// src/controllers/postulacion.controller.js
const PostModel  = require('../models/postulacion.model');
const ProyModel  = require('../models/proyecto.model');
const NotifModel = require('../models/notificacion.model');
const UsuModel   = require('../models/usuario.model');
const { enviarCorreoPostulacion } = require('../utils/email');
const { ok, created, badRequest, conflict, notFound, serverError } = require('../utils/response');

async function crear(req, res) {
  try {
    const idAlumno   = req.usuario.id;
    const idProyecto = parseInt(req.params.idProyecto || req.body.id_proyecto || req.body.idProyecto);
    if (!idProyecto) return badRequest(res, 'id_proyecto es requerido.');

    if (await PostModel.yaExiste({ idAlumno, idProyecto }))
      return conflict(res, 'Ya te postulaste a este proyecto.');

    const proyecto = await ProyModel.buscarPorId(idProyecto);
    if (!proyecto || proyecto.estado !== 'publicado')
      return notFound(res, 'Proyecto no disponible.');

    const id = await PostModel.crear({ idAlumno, idProyecto });

    try {
      const alumnoInfo = await UsuModel.buscarPorId(idAlumno);
      await enviarCorreoPostulacion({
        empresa:       proyecto.empresa,
        proyecto:      proyecto.nombre,
        correoEmpresa: proyecto.correo_empresa,
        alumno: {
          nombre:    alumnoInfo?.nombre    || req.usuario.nombre,
          correo:    alumnoInfo?.correo    || '',
          matricula: alumnoInfo?.matricula || '',
          carrera:   alumnoInfo?.carrera   || '',
        },
      });
      await PostModel.marcarCorreoEnviado(id);
    } catch (emailErr) {
      console.error('⚠️  Correo no enviado:', emailErr.message);
    }

    await NotifModel.crear({
      idUsuario: idAlumno,
      tipo:      'postulacion_registrada',
      mensaje:   `Tu postulación al proyecto "${proyecto.nombre}" fue registrada. Se notificó a la empresa.`,
    });

    return created(res, { id }, 'Postulación registrada.');
  } catch (err) {
    return serverError(res, err);
  }
}

async function misPostulaciones(req, res) {
  try {
    const lista = await PostModel.porAlumno(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

async function porProyecto(req, res) {
  try {
    const lista = await PostModel.porProyecto(parseInt(req.params.id));
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = { crear, misPostulaciones, porProyecto };
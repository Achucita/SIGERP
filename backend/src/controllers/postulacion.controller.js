const PostModel  = require('../models/postulacion.model');
const ProyModel  = require('../models/proyecto.model');
const NotifModel = require('../models/notificacion.model');
const { enviarCorreoPostulacion } = require('../utils/email');
const { ok, created, badRequest, conflict, notFound, serverError } = require('../utils/response');
 
async function crear(req, res) {
  try {
    const idAlumno  = req.usuario.id;
    const idProyecto = parseInt(req.params.idProyecto || req.body.idProyecto);
 
    if (!idProyecto) return badRequest(res, 'idProyecto es requerido.');
 
    if (await PostModel.yaExiste({ idAlumno, idProyecto }))
      return conflict(res, 'Ya te postulaste a este proyecto.');
 
    const proyecto = await ProyModel.buscarPorId(idProyecto);
    if (!proyecto || proyecto.estado !== 'publicado')
      return notFound(res, 'Proyecto no disponible.');
 
    const id = await PostModel.crear({ idAlumno, idProyecto });
 
    // Enviar correo a la empresa
    try {
      const usuarioInfo = req.usuarioCompleto; // adjuntado por middleware si lo implementas
      await enviarCorreoPostulacion({
        empresa:       proyecto.empresa,
        proyecto:      proyecto.nombre,
        correoEmpresa: proyecto.correo_empresa,
        alumno: {
          nombre:    req.usuario.nombre,
          correo:    req.body.correoAlumno || '',
          matricula: req.body.matricula    || '',
          carrera:   req.body.carrera      || '',
        },
      });
      await PostModel.marcarCorreoEnviado(id);
    } catch (emailErr) {
      console.error('⚠️  Error enviando correo a empresa:', emailErr.message);
      // No falla la postulación si el correo falla
    }
 
    // Notificación interna al alumno
    await NotifModel.crear({
      idUsuario: idAlumno,
      tipo:      'postulacion_registrada',
      mensaje:   `Tu postulación al proyecto "${proyecto.nombre}" fue registrada. Se notificó a la empresa por correo.`,
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
 
async function actualizarEstado(req, res) {
  try {
    const { estado } = req.body;
    const id         = parseInt(req.params.id);
    const permitidos = ['pendiente', 'aceptada', 'rechazada'];
    if (!permitidos.includes(estado))
      return badRequest(res, `Estado inválido. Usar: ${permitidos.join(', ')}`);
 
    const post = await PostModel.buscarPorId(id);
    if (!post) return notFound(res, 'Postulación no encontrada.');
 
    await PostModel.actualizarEstado(id, estado);
 
    // Notificar al alumno
    const tipo    = estado === 'aceptada' ? 'empresa_acepto' : 'empresa_rechazo';
    const mensaje = estado === 'aceptada'
      ? `¡La empresa aceptó tu postulación al proyecto "${post.proyecto}"! Sube tu anteproyecto para continuar.`
      : `Tu postulación al proyecto "${post.proyecto}" fue rechazada.`;
 
    await NotifModel.crear({ idUsuario: post.id_alumno, tipo, mensaje });
 
    return ok(res, {}, `Postulación marcada como ${estado}.`);
  } catch (err) {
    return serverError(res, err);
  }
}
 
module.exports = { crear, misPostulaciones, porProyecto, actualizarEstado };
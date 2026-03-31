const AntepModel = require('../models/anteproyecto.model');
const PostModel  = require('../models/postulacion.model');
const ProyModel  = require('../models/proyecto.model');
const NotifModel = require('../models/notificacion.model');
const { ok, created, badRequest, forbidden, notFound, serverError } = require('../utils/response');
 
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo PDF.');
    const { titulo, descripcion } = req.body;
    const idPostulacion = parseInt(req.body.idPostulacion);
    if (!titulo || !idPostulacion)
      return badRequest(res, 'titulo e idPostulacion son requeridos.');
 
    // Verificar que la postulación es del alumno y está aceptada
    const post = await PostModel.buscarPorId(idPostulacion);
    if (!post) return notFound(res, 'Postulación no encontrada.');
    if (post.id_alumno !== req.usuario.id)
      return forbidden(res, 'Esta postulación no es tuya.');
    if (post.estado !== 'aceptada')
      return badRequest(res, 'Solo puedes subir el anteproyecto si tu postulación fue aceptada.');
 
    const id = await AntepModel.crear({
      idPostulacion,
      titulo,
      descripcion,
      rutaArchivo: req.file.path,
    });
 
    // Notificar al alumno
    await NotifModel.crear({
      idUsuario: req.usuario.id,
      tipo:      'anteproyecto_enviado',
      mensaje:   `Tu anteproyecto fue enviado. El administrador lo revisará pronto.`,
    });
 
    return created(res, { id }, 'Anteproyecto enviado correctamente.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function pendientes(req, res) {
  try {
    const lista = await AntepModel.pendientes();
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function revisar(req, res) {
  try {
    const id         = parseInt(req.params.id);
    const { estado, comentario, idAsesor } = req.body;
 
    if (!['aprobado', 'rechazado'].includes(estado))
      return badRequest(res, 'estado debe ser "aprobado" o "rechazado".');
 
    const antep = await AntepModel.buscarPorPostulacion(
      // el id aquí es id_anteproyecto, necesitamos buscarlo diferente
      id
    );
 
    await AntepModel.actualizar(id, { estado, comentario });
 
    // Si aprobado y se da un asesor → asignar al proyecto
    if (estado === 'aprobado' && idAsesor) {
      const post = await PostModel.buscarPorId(
        // necesitamos id_postulacion del anteproyecto
        // simplificado: el frontend manda idPostulacion también
        parseInt(req.body.idPostulacion)
      );
      if (post) {
        await ProyModel.asignarAsesor(post.id_proyecto, idAsesor);
        // Notificar al alumno
        await NotifModel.crear({
          idUsuario: post.id_alumno,
          tipo:      'asesor_asignado',
          mensaje:   `Tu anteproyecto fue aprobado y se te asignó un asesor académico. Ya puedes subir reportes.`,
        });
      }
    }
 
    if (estado === 'rechazado') {
      const post = await PostModel.buscarPorId(parseInt(req.body.idPostulacion));
      if (post) {
        await NotifModel.crear({
          idUsuario: post.id_alumno,
          tipo:      'anteproyecto_rechazado',
          mensaje:   `Tu anteproyecto fue rechazado. Revisa los comentarios del administrador.`,
        });
      }
    }
 
    return ok(res, {}, `Anteproyecto ${estado}.`);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function verPorPostulacion(req, res) {
  try {
    const antep = await AntepModel.buscarPorPostulacion(parseInt(req.params.idPostulacion));
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');
    return ok(res, antep);
  } catch (err) {
    return serverError(res, err);
  }
}
 
module.exports = { subir, pendientes, revisar, verPorPostulacion };
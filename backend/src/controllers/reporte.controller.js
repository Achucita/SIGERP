const RepModel   = require('../models/reporte.model');
const PostModel  = require('../models/postulacion.model');
const NotifModel = require('../models/notificacion.model');
const { ok, created, badRequest, forbidden, notFound, serverError } = require('../utils/response');
 
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo.');
    const { titulo, descripcion, periodoInicio, periodoFin, idProyecto } = req.body;
    if (!titulo || !periodoInicio || !periodoFin || !idProyecto)
      return badRequest(res, 'titulo, periodoInicio, periodoFin e idProyecto son requeridos.');
 
    const idAlumno = req.usuario.id;
    const id       = await RepModel.crear({
      idAlumno, idProyecto: parseInt(idProyecto),
      titulo, descripcion, periodoInicio, periodoFin,
      rutaArchivo: req.file.path,
    });
    return created(res, { id }, 'Reporte enviado.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function misReportes(req, res) {
  try {
    const lista = await RepModel.porAlumno(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function porProyecto(req, res) {
  try {
    const lista = await RepModel.porProyecto(parseInt(req.params.id));
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function comentar(req, res) {
  try {
    const { estado, comentario } = req.body;
    const estados = ['revisado', 'con_observaciones'];
    if (!estados.includes(estado))
      return badRequest(res, `estado debe ser: ${estados.join(' o ')}`);
    await RepModel.comentar(parseInt(req.params.id), { estado, comentario });
 
    // notificar al alumno — idealmente buscamos id del alumno dueño del reporte
    // simplificado para no hacer join extra aquí
    return ok(res, {}, 'Reporte comentado.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
module.exports = { subir, misReportes, porProyecto, comentar };
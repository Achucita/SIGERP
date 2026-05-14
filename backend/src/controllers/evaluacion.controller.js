const EvalModel  = require('../models/evaluacion.model');
const NotifModel = require('../models/notificacion.model');
const { ok, created, badRequest, serverError } = require('../utils/response');
 
async function crear(req, res) {
  try {
    const { idAlumno, idProyecto, tipo, calificacion, comentarios, periodoEvaluado } = req.body;
    if (!idAlumno || !tipo || calificacion === undefined)
      return badRequest(res, 'idAlumno, tipo y calificacion son requeridos.');

    // idProyecto es opcional (alumno puede no tener proyecto asignado aún)
    const idProy = idProyecto && idProyecto !== 0 ? idProyecto : null;
 
    const cal = parseFloat(calificacion);
    if (isNaN(cal) || cal < 0 || cal > 10)
      return badRequest(res, 'calificacion debe ser un número entre 0 y 10.');
 
    const id = await EvalModel.crear({
      idAlumno, idAsesor: req.usuario.id, idProyecto: idProy,
      tipo, calificacion: cal, comentarios, periodoEvaluado,
    });
 
    await NotifModel.crear({
      idUsuario: idAlumno,
      tipo:      'evaluacion_recibida',
      mensaje:   `Tienes una nueva evaluación ${tipo} con calificación ${cal}.`,
    });
 
    return created(res, { id }, 'Evaluación registrada.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function listar(req, res) {
  try {
    return ok(res, await EvalModel.listar());
  } catch (err) {
    return serverError(res, err);
  }
}

async function misEvaluaciones(req, res) {
  try {
    const lista = await EvalModel.porAlumno(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function porAlumno(req, res) {
  try {
    const lista = await EvalModel.porAlumno(parseInt(req.params.id));
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}
 
module.exports = { crear, listar, misEvaluaciones, porAlumno };
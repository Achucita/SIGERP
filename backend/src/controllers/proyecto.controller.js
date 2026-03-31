const Model   = require('../models/proyecto.model');
const { ok, notFound, badRequest, serverError } = require('../utils/response');
 
async function listar(req, res) {
  try {
    const proyectos = await Model.listar({ estado: req.query.estado, area: req.query.area });
    return ok(res, proyectos);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function detalle(req, res) {
  try {
    const proyecto = await Model.buscarPorId(parseInt(req.params.id));
    if (!proyecto) return notFound(res, 'Proyecto no encontrado.');
    return ok(res, proyecto);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function cambiarEstado(req, res) {
  try {
    const { estado } = req.body;
    const estados = ['revision', 'publicado', 'cerrado', 'despublicado'];
    if (!estados.includes(estado))
      return badRequest(res, `Estado inválido. Usar: ${estados.join(', ')}`);
    await Model.actualizarEstado(parseInt(req.params.id), estado);
    return ok(res, {}, 'Estado del proyecto actualizado.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function asignarAsesor(req, res) {
  try {
    const { idAsesor } = req.body;
    if (!idAsesor) return badRequest(res, 'idAsesor es requerido.');
    await Model.asignarAsesor(parseInt(req.params.id), idAsesor);
    return ok(res, {}, 'Asesor asignado correctamente.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
module.exports = { listar, detalle, cambiarEstado, asignarAsesor };
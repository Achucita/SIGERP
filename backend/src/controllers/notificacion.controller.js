const Model = require('../models/notificacion.model');
const { ok, serverError } = require('../utils/response');
 
async function mis(req, res) {
  try {
    const lista = await Model.porUsuario(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function marcarLeida(req, res) {
  try {
    await Model.marcarLeida(parseInt(req.params.id));
    return ok(res, {}, 'Notificación marcada como leída.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
module.exports = { mis, marcarLeida };
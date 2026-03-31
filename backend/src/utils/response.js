const ok = (res, data = {}, message = 'OK', status = 200) =>
  res.status(status).json({ ok: true, message, data });
 
const created = (res, data = {}, message = 'Recurso creado') =>
  res.status(201).json({ ok: true, message, data });
 
const badRequest = (res, message = 'Solicitud inválida') =>
  res.status(400).json({ ok: false, message });
 
const unauthorized = (res, message = 'No autorizado') =>
  res.status(401).json({ ok: false, message });
 
const forbidden = (res, message = 'Acceso denegado') =>
  res.status(403).json({ ok: false, message });
 
const notFound = (res, message = 'Recurso no encontrado') =>
  res.status(404).json({ ok: false, message });
 
const conflict = (res, message = 'Conflicto con datos existentes') =>
  res.status(409).json({ ok: false, message });
 
const serverError = (res, err, message = 'Error interno del servidor') => {
  console.error(err);
  res.status(500).json({ ok: false, message });
};
 
module.exports = { ok, created, badRequest, unauthorized, forbidden, notFound, conflict, serverError };
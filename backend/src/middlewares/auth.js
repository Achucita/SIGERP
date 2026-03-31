const jwt  = require('jsonwebtoken');
const env  = require('../config/env');
const { unauthorized } = require('../utils/response');
 
function auth(req, res, next) {
  const header = req.headers['authorization'];
  if (!header || !header.startsWith('Bearer ')) {
    return unauthorized(res, 'Token no proporcionado.');
  }
 
  const token = header.split(' ')[1];
  try {
    const payload = jwt.verify(token, env.jwt.secret);
    req.usuario = payload;  // { id, rol, nombre }
    next();
  } catch (err) {
    return unauthorized(res, 'Token inválido o expirado.');
  }
}
 
module.exports = auth;
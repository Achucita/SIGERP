const { forbidden } = require('../utils/response');
 
function roles(...rolesPermitidos) {
  return (req, res, next) => {
    if (!rolesPermitidos.includes(req.usuario?.rol)) {
      return forbidden(res, 'No tienes permiso para esta acción.');
    }
    next();
  };
}
 
module.exports = roles;
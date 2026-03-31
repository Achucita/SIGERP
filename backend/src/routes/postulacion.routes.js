const router = require('express').Router();
const ctrl   = require('../controllers/postulacion.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
 
router.post('/',                       auth, roles('alumno'), ctrl.crear);
router.get('/mis',                     auth, roles('alumno'), ctrl.misPostulaciones);
router.get('/proyecto/:id',       auth, roles('admin', 'asesor'), ctrl.porProyecto);
router.put('/:id/estado',         auth, roles('admin'), ctrl.actualizarEstado);
 
module.exports = router;
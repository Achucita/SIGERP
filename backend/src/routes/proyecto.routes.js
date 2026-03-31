const router = require('express').Router();
const ctrl   = require('../controllers/proyecto.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
 
router.get('/',                          auth, ctrl.listar);
router.get('/:id',                       auth, ctrl.detalle);
router.put('/:id/estado',           auth, roles('admin'), ctrl.cambiarEstado);
router.put('/:id/asesor',           auth, roles('admin'), ctrl.asignarAsesor);
 
module.exports = router;
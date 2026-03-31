const router  = require('express').Router();
const ctrl    = require('../controllers/usuario.controller');
const auth    = require('../middlewares/auth');
const roles   = require('../middlewares/roles');
 
router.post('/registro',         ctrl.registro);          // público — solo alumnos
router.post('/login',            ctrl.login);             // público
router.get('/perfil',      auth, ctrl.perfil);            // cualquier rol autenticado
router.put('/:id',         auth, ctrl.actualizar);        // propio usuario o admin
router.get('/',            auth, roles('admin'), ctrl.listar);  // solo admin
router.delete('/:id',      auth, roles('admin'), ctrl.baja);    // solo admin
 
module.exports = router;
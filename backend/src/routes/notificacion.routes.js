const router = require('express').Router();
const ctrl   = require('../controllers/notificacion.controller');
const auth   = require('../middlewares/auth');
 
router.get('/',          auth, ctrl.mis);
router.put('/:id/leer',  auth, ctrl.marcarLeida);
 
module.exports = router;
const router = require('express').Router();
const ctrl   = require('../controllers/evaluacion.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
 
router.post('/',            auth, roles('asesor'), ctrl.crear);
router.get('/mis',          auth, roles('alumno'), ctrl.misEvaluaciones);
router.get('/alumno/:id',   auth, roles('asesor', 'admin'), ctrl.porAlumno);
 
module.exports = router;
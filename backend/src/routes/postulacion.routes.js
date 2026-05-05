// src/routes/postulacion.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/postulacion.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');

// Alumno se postula
router.post('/',         auth, roles('alumno'), ctrl.crear);
// Alumno ve sus postulaciones
router.get('/mis',       auth, roles('alumno'), ctrl.misPostulaciones);
// Admin/Asesor ve postulaciones de un proyecto
router.get('/proyecto/:id', auth, roles('admin', 'asesor'), ctrl.porProyecto);

module.exports = router;
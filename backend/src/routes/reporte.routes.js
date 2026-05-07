// src/routes/reporte.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/reporte.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/reportes/'),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `rep_${req.usuario?.id}_${Date.now()}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 15 * 1024 * 1024 } });

// Alumno
router.post('/',              auth, roles('alumno'), upload.single('archivo'), ctrl.subir);
router.get('/mis',            auth, roles('alumno'), ctrl.misReportes);
router.get('/periodos',       auth, ctrl.periodos);           // alumno y admin ven fechas

// Admin
router.get('/',               auth, roles('admin'), ctrl.listar);
router.put('/periodos',       auth, roles('admin'), ctrl.actualizarPeriodo);  // <- antes que /:id
router.put('/:id',            auth, roles('admin'), ctrl.revisar);

module.exports = router;
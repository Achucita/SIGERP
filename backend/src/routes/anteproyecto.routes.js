// src/routes/anteproyecto.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/anteproyecto.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/anteproyectos/'),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `antep_${req.usuario?.id}_${Date.now()}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 15 * 1024 * 1024 } });

// ── Alumno ─────────────────────────────────────────────────────────────────
router.post('/',                        auth, roles('alumno'), upload.single('archivo'), ctrl.subir);
router.get('/mi/:idPostulacion',        auth, roles('alumno'), ctrl.miAnteproyecto);

// ── Admin ──────────────────────────────────────────────────────────────────
router.get('/',                         auth, roles('admin'), ctrl.listar);
router.get('/pendientes',               auth, roles('admin'), ctrl.pendientes);
router.get('/:id',                      auth, roles('admin', 'asesor'), ctrl.verPorId);
router.get('/postulacion/:idPostulacion', auth, roles('admin', 'asesor'), ctrl.verPorPostulacion);
router.put('/:id/revisar',              auth, roles('admin'), ctrl.revisar);

// ── Asesor ─────────────────────────────────────────────────────────────────
router.get('/mis-asignados',            auth, roles('asesor'), ctrl.porAsesor);
router.put('/:id/revisar-asesor',       auth, roles('asesor'), ctrl.revisarAsesor);

module.exports = router;
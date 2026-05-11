// src/routes/anteproyecto.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/anteproyecto.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');
const fs     = require('fs');

const uploadDir = path.join(__dirname, '..', '..', 'uploads', 'anteproyectos');
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `antep_${req.usuario?.id ?? 'u'}_${Date.now()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['.pdf', '.docx'];
    if (allowed.includes(path.extname(file.originalname).toLowerCase()))
      return cb(null, true);
    cb(new Error('Solo se permiten archivos PDF o DOCX.'));
  },
});

function uploadSingle(campo) {
  return (req, res, next) => {
    upload.single(campo)(req, res, (err) => {
      if (!err) return next();
      const msg = err.code === 'LIMIT_FILE_SIZE'
        ? 'El archivo supera el limite de 15 MB.'
        : (err.message || 'Error al procesar el archivo.');
      return res.status(400).json({ ok: false, message: msg });
    });
  };
}

// ── Alumno ────────────────────────────────────────────────────────────────────
router.post('/',  auth, roles('alumno'), uploadSingle('archivo'), ctrl.subir);
router.get('/mi', auth, roles('alumno'), ctrl.miAnteproyecto);

// ── Rutas con segmentos fijos SIEMPRE antes de /:id ─────────────────────────
// (Express evalúa en orden — si /:id va primero, captura todo lo demás)
router.get('/pendientes',                 auth, roles('admin'),           ctrl.pendientes);
router.get('/postulacion/:idPostulacion', auth, roles('admin', 'asesor'), ctrl.verPorPostulacion);
router.get('/mis-asignados',              auth, roles('asesor'),          ctrl.porAsesor);

// ── Admin ─────────────────────────────────────────────────────────────────────
router.get('/',                           auth, roles('admin'),           ctrl.listar);
router.put('/:id/asignar-asesor',         auth, roles('admin'),           ctrl.asignarAsesor);
router.get('/:id',                        auth, roles('admin', 'asesor'), ctrl.verPorId);  // ← AL FINAL

// ── Asesor ────────────────────────────────────────────────────────────────────
router.put('/:id/revisar-asesor',         auth, roles('asesor'),          ctrl.revisarAsesor);

module.exports = router;
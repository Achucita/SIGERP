// src/routes/reporte.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/reporte.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');
const fs     = require('fs');

const uploadDir = path.join(__dirname, '..', '..', 'uploads', 'reportes');
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `rep_${req.usuario?.id ?? 'u'}_${Date.now()}${ext}`);
  },
});

function uploadSingle(campo) {
  return (req, res, next) => {
    multer({ storage, limits: { fileSize: 15 * 1024 * 1024 } })
      .single(campo)(req, res, (err) => {
        if (!err) return next();
        const msg = err.code === 'LIMIT_FILE_SIZE'
          ? 'El archivo supera el limite de 15 MB.'
          : (err.message || 'Error al procesar el archivo.');
        return res.status(400).json({ ok: false, message: msg });
      });
  };
}

// Alumno
router.post('/',        auth, roles('alumno'), uploadSingle('archivo'), ctrl.subir);
router.get('/mis',      auth, roles('alumno'), ctrl.misReportes);
router.get('/periodos', auth,                  ctrl.periodos);

// Admin
router.get('/',         auth, roles('admin'), ctrl.listar);
router.put('/periodos', auth, roles('admin'), ctrl.actualizarPeriodo);
router.put('/:id',      auth, roles('admin'), ctrl.revisar);

module.exports = router;
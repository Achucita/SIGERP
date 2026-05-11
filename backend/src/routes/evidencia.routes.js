// src/routes/evidencia.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/evidencia.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');
const fs     = require('fs');

const uploadDir = path.join(__dirname, '..', '..', 'uploads', 'evidencias');
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `evid_${req.usuario?.id ?? 'u'}_${Date.now()}${ext}`);
  },
});

function uploadSingle(campo) {
  return (req, res, next) => {
    multer({ storage, limits: { fileSize: 20 * 1024 * 1024 } })
      .single(campo)(req, res, (err) => {
        if (!err) return next();
        return res.status(400).json({ ok: false, message: err.message || 'Error al procesar el archivo.' });
      });
  };
}

router.post('/',              auth, roles('alumno'), uploadSingle('archivo'), ctrl.subir);
router.get('/mis',            auth, roles('alumno'), ctrl.misEvidencias);
router.get('/asesor',         auth, roles('asesor'), ctrl.porAsesor);
router.put('/:id/comentar',   auth, roles('asesor'), ctrl.comentar);

module.exports = router;
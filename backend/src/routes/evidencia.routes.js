// src/routes/evidencia.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/evidencia.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/evidencias/'),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `evid_${req.usuario?.id}_${Date.now()}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 20 * 1024 * 1024 } });

router.post('/',          auth, roles('alumno'), upload.single('archivo'), ctrl.subir);
router.get('/mis',        auth, roles('alumno'), ctrl.misEvidencias);
router.get('/asesor',     auth, roles('asesor'), ctrl.porAsesor);
router.put('/:id/comentar', auth, roles('asesor'), ctrl.comentar);

module.exports = router;
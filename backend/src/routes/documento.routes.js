// src/routes/documento.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/documento.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/documentos/'),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `doc_${req.usuario?.id}_${Date.now()}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 20 * 1024 * 1024 } });

// Alumno
router.post('/',          auth, roles('alumno'), upload.single('archivo'), ctrl.subir);
router.get('/mis',        auth, roles('alumno'), ctrl.misDocumentos);
router.delete('/:id',     auth, roles('alumno'), ctrl.eliminar);

// Admin
router.get('/',           auth, roles('admin'), ctrl.listarTodos);
router.get('/alumno/:idAlumno', auth, roles('admin'), ctrl.porAlumno);

module.exports = router;
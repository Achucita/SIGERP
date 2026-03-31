const router = require('express').Router();
const ctrl   = require('../controllers/anteproyecto.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');
const fs     = require('fs');
 
const uploadDir = path.join(__dirname, '../../uploads/anteproyectos');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
 
const storage = multer.diskStorage({
  destination: uploadDir,
  filename: (req, file, cb) =>
    cb(null, `antep_post${req.body.idPostulacion}_${Date.now()}${path.extname(file.originalname)}`),
});
const upload = multer({ storage, fileFilter: (req, file, cb) =>
  cb(null, file.mimetype === 'application/pdf'),
});
 
router.post('/',                  auth, roles('alumno'), upload.single('archivo'), ctrl.subir);
router.get('/pendientes',    auth, roles('admin'), ctrl.pendientes);
router.get('/:idPostulacion', auth, ctrl.verPorPostulacion);
router.put('/:id/revisar',   auth, roles('admin'), ctrl.revisar);
 
module.exports = router;
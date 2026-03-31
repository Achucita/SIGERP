const router = require('express').Router();
const ctrl   = require('../controllers/reporte.controller');
const auth   = require('../middlewares/auth');
const roles  = require('../middlewares/roles');
const multer = require('multer');
const path   = require('path');
const fs     = require('fs');
 
const uploadDir = path.join(__dirname, '../../uploads/reportes');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
 
const storage = multer.diskStorage({
  destination: uploadDir,
  filename: (req, file, cb) =>
    cb(null, `rep_${req.usuario.id}_${Date.now()}${path.extname(file.originalname)}`),
});
const upload = multer({ storage });
 
router.post('/',               auth, roles('alumno'), upload.single('archivo'), ctrl.subir);
router.get('/mis',             auth, roles('alumno'), ctrl.misReportes);
router.get('/proyecto/:id',    auth, roles('asesor', 'admin'), ctrl.porProyecto);
router.put('/:id/comentar',    auth, roles('asesor'), ctrl.comentar);
 
module.exports = router;
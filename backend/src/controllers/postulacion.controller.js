// src/controllers/postulacion.controller.js
const path       = require('path');
const fs         = require('fs');
const multer     = require('multer');
const PostModel  = require('../models/postulacion.model');
const ProyModel  = require('../models/proyecto.model');
const NotifModel = require('../models/notificacion.model');
const UsuModel   = require('../models/usuario.model');
const { enviarCorreoPostulacion } = require('../utils/email');
const { ok, created, badRequest, conflict, notFound, serverError } = require('../utils/response');

// ── Configuración de Multer para CVs ────────────────────────────────────────
const storage = multer.diskStorage({
  destination(req, file, cb) {
    const dir = path.join(__dirname, '..', '..', 'uploads', 'cvs');
    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename(req, file, cb) {
    const idAlumno  = req.usuario?.id || 'x';
    const timestamp = Date.now();
    const ext       = path.extname(file.originalname).toLowerCase();
    cb(null, `cv_alumno_${idAlumno}_${timestamp}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = ['.pdf', '.doc', '.docx'];
  const ext     = path.extname(file.originalname).toLowerCase();
  if (allowed.includes(ext)) return cb(null, true);
  cb(new Error('Solo se permiten archivos PDF, DOC o DOCX para el CV.'));
};

/** Middleware de subida — máximo 5 MB, campo "cv" */
const uploadCV = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
}).single('cv');

// ── Controladores ────────────────────────────────────────────────────────────

/**
 * POST /api/postulaciones
 * Acepta multipart/form-data con:
 *   - id_proyecto  (body field)
 *   - cv           (optional file — PDF / DOC / DOCX, max 5 MB)
 */
async function crear(req, res) {
  // Procesamos la subida dentro del controlador para poder capturar errores
  uploadCV(req, res, async (uploadErr) => {
    if (uploadErr) return badRequest(res, uploadErr.message);

    try {
      const idAlumno   = req.usuario.id;
      const idProyecto = parseInt(req.params.idProyecto || req.body.id_proyecto || req.body.idProyecto);
      if (!idProyecto) return badRequest(res, 'id_proyecto es requerido.');

      if (await PostModel.yaExiste({ idAlumno, idProyecto }))
        return conflict(res, 'Ya te postulaste a este proyecto.');

      const proyecto = await ProyModel.buscarPorId(idProyecto);
      if (!proyecto || proyecto.estado !== 'publicado')
        return notFound(res, 'Proyecto no disponible.');

      // Ruta relativa al CV (null si no se subió)
      const cvRuta = req.file
        ? path.join('uploads', 'cvs', req.file.filename).replace(/\\/g, '/')
        : null;

      const id = await PostModel.crear({ idAlumno, idProyecto, cvRuta });

      try {
        const alumnoInfo = await UsuModel.buscarPorId(idAlumno);
        await enviarCorreoPostulacion({
          empresa:       proyecto.empresa,
          proyecto:      proyecto.nombre,
          correoEmpresa: proyecto.correo_empresa,
          cvRuta,
          alumno: {
            nombre:    alumnoInfo?.nombre    || req.usuario.nombre,
            correo:    alumnoInfo?.correo    || '',
            matricula: alumnoInfo?.matricula || '',
            carrera:   alumnoInfo?.carrera   || '',
          },
        });
        await PostModel.marcarCorreoEnviado(id);
      } catch (emailErr) {
        console.error('⚠️  Correo no enviado:', emailErr.message);
      }

      await NotifModel.crear({
        idUsuario: idAlumno,
        tipo:      'postulacion_registrada',
        mensaje:   `Tu postulación al proyecto "${proyecto.nombre}" fue registrada. Se notificó a la empresa.`,
      });

      return created(res, { id, cvSubido: !!cvRuta }, 'Postulación registrada.');
    } catch (err) {
      return serverError(res, err);
    }
  });
}

async function misPostulaciones(req, res) {
  try {
    const lista = await PostModel.porAlumno(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

async function porProyecto(req, res) {
  try {
    const lista = await PostModel.porProyecto(parseInt(req.params.id));
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = { crear, misPostulaciones, porProyecto };
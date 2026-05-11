// src/controllers/evidencia.controller.js
const EvidModel  = require('../models/evidencia.model');
const NotifModel = require('../models/notificacion.model');
const { ok, created, badRequest, serverError } = require('../utils/response');

async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo.');
    const id = await EvidModel.crear({
      idAlumno:    req.usuario.id,
      descripcion: req.body.descripcion || null,
      rutaArchivo: `uploads/evidencias/${req.file.filename}`,
    });
    return created(res, { id }, 'Evidencia enviada al asesor.');
  } catch (err) {
    return serverError(res, err);
  }
}

async function misEvidencias(req, res) {
  try {
    return ok(res, await EvidModel.porAlumno(req.usuario.id));
  } catch (err) {
    return serverError(res, err);
  }
}

async function porAsesor(req, res) {
  try {
    return ok(res, await EvidModel.porAsesor(req.usuario.id));
  } catch (err) {
    return serverError(res, err);
  }
}

async function comentar(req, res) {
  try {
    const { comentario, idAlumno } = req.body;
    if (!comentario) return badRequest(res, 'El comentario es requerido.');
    await EvidModel.comentar(parseInt(req.params.id), comentario);
    if (idAlumno) {
      await NotifModel.crear({
        idUsuario: parseInt(idAlumno),
        tipo:      'evidencia_comentada',
        mensaje:   'Tu asesor dejó un comentario en una de tus evidencias.',
      });
    }
    return ok(res, {}, 'Comentario registrado.');
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = { subir, misEvidencias, porAsesor, comentar };
// src/controllers/evidencia.controller.js
const EvidModel  = require('../models/evidencia.model');
const NotifModel = require('../models/notificacion.model');
const { ok, created, badRequest, serverError } = require('../utils/response');

// Alumno sube evidencia — siempre abierto
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo.');
    const { descripcion } = req.body;

    const id = await EvidModel.crear({
      idAlumno:    req.usuario.id,
      descripcion: descripcion || null,
      rutaArchivo: req.file.path,
    });

    return created(res, { id }, 'Evidencia enviada al asesor.');
  } catch (err) {
    return serverError(res, err);
  }
}

// Alumno ve sus evidencias
async function misEvidencias(req, res) {
  try {
    const lista = await EvidModel.porAlumno(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// Asesor ve evidencias de sus alumnos
async function porAsesor(req, res) {
  try {
    const lista = await EvidModel.porAsesor(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// Asesor comenta una evidencia (sin calificación)
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
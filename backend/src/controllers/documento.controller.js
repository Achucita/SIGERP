// src/controllers/documento.controller.js
const DocModel = require('../models/documento.model');
const { ok, created, badRequest, forbidden, serverError } = require('../utils/response');

// Alumno sube un documento
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo.');
    const nombre = req.body.nombre || req.file.originalname;

    const id = await DocModel.crear({
      idAlumno:    req.usuario.id,
      nombre,
      rutaArchivo: req.file.path,
    });

    return created(res, { id }, 'Documento guardado en tu expediente.');
  } catch (err) {
    return serverError(res, err);
  }
}

// Alumno ve sus documentos
async function misDocumentos(req, res) {
  try {
    const lista = await DocModel.porAlumno(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// Alumno elimina un documento suyo
async function eliminar(req, res) {
  try {
    await DocModel.eliminar(parseInt(req.params.id), req.usuario.id);
    return ok(res, {}, 'Documento eliminado.');
  } catch (err) {
    return serverError(res, err);
  }
}

// Admin ve todos los documentos
async function listarTodos(req, res) {
  try {
    const lista = await DocModel.listarTodos();
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// Admin ve documentos de un alumno específico
async function porAlumno(req, res) {
  try {
    const lista = await DocModel.porAlumnoAdmin(parseInt(req.params.idAlumno));
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = { subir, misDocumentos, eliminar, listarTodos, porAlumno };
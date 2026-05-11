// src/controllers/documento.controller.js
const DocModel = require('../models/documento.model');
const { ok, created, badRequest, serverError } = require('../utils/response');

async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo.');
    const nombre = req.body.nombre || req.file.originalname;

    const id = await DocModel.crear({
      idAlumno:    req.usuario.id,
      nombre,
      rutaArchivo: `uploads/documentos/${req.file.filename}`,
    });

    return created(res, { id }, 'Documento guardado en tu expediente.');
  } catch (err) {
    return serverError(res, err);
  }
}

async function misDocumentos(req, res) {
  try {
    return ok(res, await DocModel.porAlumno(req.usuario.id));
  } catch (err) {
    return serverError(res, err);
  }
}

async function eliminar(req, res) {
  try {
    await DocModel.eliminar(parseInt(req.params.id), req.usuario.id);
    return ok(res, {}, 'Documento eliminado.');
  } catch (err) {
    return serverError(res, err);
  }
}

async function listarTodos(req, res) {
  try {
    return ok(res, await DocModel.listarTodos());
  } catch (err) {
    return serverError(res, err);
  }
}

async function porAlumno(req, res) {
  try {
    return ok(res, await DocModel.porAlumnoAdmin(parseInt(req.params.idAlumno)));
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = { subir, misDocumentos, eliminar, listarTodos, porAlumno };
// src/controllers/expediente.controller.js
const ExpedienteModel = require('../models/expediente.model');
const { ok, serverError } = require('../utils/response');

// Admin — lista de todos los alumnos en residencias
async function listar(req, res) {
  try {
    const lista = await ExpedienteModel.listarAlumnos();
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// Admin — expediente completo de un alumno
async function detalle(req, res) {
  try {
    const idAlumno = parseInt(req.params.id);
    if (!idAlumno) return res.status(400).json({ ok: false, message: 'ID inválido.' });

    const expediente = await ExpedienteModel.expedienteCompleto(idAlumno);
    if (!expediente.alumno)
      return res.status(404).json({ ok: false, message: 'Alumno no encontrado o sin residencia activa.' });

    return ok(res, expediente);
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = { listar, detalle };
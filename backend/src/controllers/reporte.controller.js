// src/controllers/reporte.controller.js
const ReporteModel = require('../models/reporte.model');
const NotifModel   = require('../models/notificacion.model');
const { ok, created, badRequest, serverError } = require('../utils/response');

// Alumno sube reporte formal — solo si el periodo está abierto
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo PDF.');

    const numeroReporte = parseInt(req.body.numero_reporte);
    const periodoCubre  = req.body.periodo_cubre;

    if (!numeroReporte || ![1, 2, 3].includes(numeroReporte))
      return badRequest(res, 'numero_reporte debe ser 1, 2 o 3.');
    if (!periodoCubre)
      return badRequest(res, 'periodo_cubre es requerido.');

    const habilitado = await ReporteModel.periodoHabilitado(numeroReporte);
    if (!habilitado)
      return badRequest(res, `El periodo ${numeroReporte} aún no está habilitado por el administrador.`);

    const misReportes = await ReporteModel.porAlumno(req.usuario.id);
    const yaExiste = misReportes.some(r =>
      r.numero_reporte === numeroReporte || r.numero_reporte.toString() === numeroReporte.toString()
    );
    if (yaExiste)
      return badRequest(res, `Ya enviaste el reporte ${numeroReporte}.`);

    const id = await ReporteModel.crear({
      idAlumno:               req.usuario.id,
      numeroReporte,
      periodoCubre,
      rutaArchivo:            req.file.path,
      comentariosAdicionales: req.body.comentarios_adicionales || null,
    });

    await NotifModel.crear({
      idUsuario: req.usuario.id,
      tipo:      'reporte_enviado',
      mensaje:   `Tu reporte ${numeroReporte} (${periodoCubre}) fue enviado a administración.`,
    });

    return created(res, { id }, `Reporte ${numeroReporte} enviado.`);
  } catch (err) {
    return serverError(res, err);
  }
}

// Alumno ve sus reportes
async function misReportes(req, res) {
  try {
    const lista = await ReporteModel.porAlumno(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// Admin ve todos los reportes
async function listar(req, res) {
  try {
    const lista = await ReporteModel.listar({
      estado:   req.query.estado   || null,
      idAlumno: req.query.idAlumno ? parseInt(req.query.idAlumno) : null,
    });
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// Admin revisa un reporte
async function revisar(req, res) {
  try {
    const { estado, comentario, idAlumno } = req.body;
    if (!['revisado', 'con_observaciones'].includes(estado))
      return badRequest(res, 'estado debe ser: revisado o con_observaciones.');

    await ReporteModel.actualizarEstado(parseInt(req.params.id), { estado, comentario });

    if (idAlumno) {
      await NotifModel.crear({
        idUsuario: parseInt(idAlumno),
        tipo:      'reporte_revisado',
        mensaje:   estado === 'revisado'
          ? 'Tu reporte fue revisado y aceptado por administración.'
          : `Tu reporte fue devuelto con observaciones: ${comentario}`,
      });
    }

    return ok(res, {}, `Reporte marcado como ${estado}.`);
  } catch (err) {
    return serverError(res, err);
  }
}

// Admin y alumno ven los periodos y sus fechas
async function periodos(req, res) {
  try {
    const lista = await ReporteModel.listarPeriodos();
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// Admin configura fechas de un periodo
async function actualizarPeriodo(req, res) {
  try {
    const { numero_reporte, nombre, fecha_apertura, fecha_cierre } = req.body;
    if (!numero_reporte || ![1, 2, 3].includes(parseInt(numero_reporte)))
      return badRequest(res, 'numero_reporte debe ser 1, 2 o 3.');

    await ReporteModel.actualizarPeriodo({
      numeroReporte: parseInt(numero_reporte),
      nombre:        nombre || `Reporte ${numero_reporte}`,
      fechaApertura: fecha_apertura || null,
      fechaCierre:   fecha_cierre   || null,
    });

    return ok(res, {}, `Periodo ${numero_reporte} actualizado.`);
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = { subir, misReportes, listar, revisar, periodos, actualizarPeriodo };
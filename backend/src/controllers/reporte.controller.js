// src/controllers/reporte.controller.js
const ReporteModel = require('../models/reporte.model');
const NotifModel   = require('../models/notificacion.model');
const { ok, created, badRequest, serverError } = require('../utils/response');

// Alumno sube reporte formal
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo PDF.');

    const numeroReporte = parseInt(req.body.numero_reporte);
    const titulo        = req.body.titulo;
    const periodoInicio = req.body.periodo_inicio;
    const periodoFin    = req.body.periodo_fin;

    if (!numeroReporte || ![1, 2, 3].includes(numeroReporte))
      return badRequest(res, 'numero_reporte debe ser 1, 2 o 3.');
    if (!titulo)
      return badRequest(res, 'El titulo es requerido.');

    const habilitado = await ReporteModel.periodoHabilitado(numeroReporte);
    if (!habilitado)
      return badRequest(res, `El periodo ${numeroReporte} aun no esta habilitado.`);

    const misReportes = await ReporteModel.porAlumno(req.usuario.id);
    const existente   = misReportes.find(r =>
      r.numero_reporte.toString() === numeroReporte.toString()
    );

    const rutaRelativa = `uploads/reportes/${req.file.filename}`;

    let id;
    if (existente) {
      // Reenvio con correcciones — actualizar el reporte existente
      await ReporteModel.actualizar(existente.id_reporte, {
        titulo,
        descripcion:   req.body.descripcion || null,
        periodoInicio: periodoInicio || null,
        periodoFin:    periodoFin    || null,
        rutaArchivo:   rutaRelativa,
      });
      id = existente.id_reporte;
    } else {
      // Primer envio — crear nuevo reporte
      const idProyecto = await ReporteModel.idProyectoDeAlumno(req.usuario.id);
      id = await ReporteModel.crear({
        idAlumno:      req.usuario.id,
        idProyecto,
        numeroReporte,
        titulo,
        descripcion:   req.body.descripcion || null,
        periodoInicio: periodoInicio || null,
        periodoFin:    periodoFin    || null,
        rutaArchivo:   rutaRelativa,
      });
    }

    await NotifModel.crear({
      idUsuario: req.usuario.id,
      tipo:      'reporte_enviado',
      mensaje:   `Tu reporte ${numeroReporte} fue enviado a administracion.`,
    });

    return created(res, { id }, `Reporte ${numeroReporte} enviado.`);
  } catch (err) {
    return serverError(res, err);
  }
}

async function misReportes(req, res) {
  try {
    return ok(res, await ReporteModel.porAlumno(req.usuario.id));
  } catch (err) {
    return serverError(res, err);
  }
}

async function listar(req, res) {
  try {
    return ok(res, await ReporteModel.listar({
      estado:   req.query.estado   || null,
      idAlumno: req.query.idAlumno ? parseInt(req.query.idAlumno) : null,
    }));
  } catch (err) {
    return serverError(res, err);
  }
}

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
          ? 'Tu reporte fue revisado y aceptado.'
          : `Tu reporte fue devuelto con observaciones: ${comentario}`,
      });
    }

    return ok(res, {}, `Reporte marcado como ${estado}.`);
  } catch (err) {
    return serverError(res, err);
  }
}

async function periodos(req, res) {
  try {
    return ok(res, await ReporteModel.listarPeriodos());
  } catch (err) {
    return serverError(res, err);
  }
}

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
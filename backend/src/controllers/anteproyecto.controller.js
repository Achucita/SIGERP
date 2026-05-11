// src/controllers/anteproyecto.controller.js
const AntepModel = require('../models/anteproyecto.model');
const NotifModel = require('../models/notificacion.model');
const { ok, created, badRequest, notFound, serverError } = require('../utils/response');

// ── Alumno sube su anteproyecto ───────────────────────────────────────────────
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo PDF o DOCX.');

    const { titulo, descripcion, asesoresPropuestos } = req.body;
    if (!titulo) return badRequest(res, 'El titulo es requerido.');

    const idAlumno = req.usuario.id;

    // Ya tiene uno → actualizar en lugar de duplicar
    const existente = await AntepModel.buscarPorAlumno(idAlumno);
    if (existente) {
      const { getPool, sql } = require('../config/db');
      const pool = await getPool();

      // Si ya tiene asesor asignado (fue enviado con observaciones), va directo al asesor
      // sin pasar por el admin de nuevo
      const tieneAsesor = !!existente.id_asesor_asignado;
      const nuevoEstado = tieneAsesor ? 'asignado' : 'pendiente';

      await pool.request()
        .input('id',         sql.Int,      existente.id_anteproyecto)
        .input('titulo',     sql.NVarChar, titulo)
        .input('desc',       sql.NVarChar, descripcion || null)
        .input('ruta',       sql.NVarChar, `uploads/anteproyectos/${req.file.filename}`)
        .input('propuestos', sql.NVarChar, asesoresPropuestos || null)
        .input('estado',     sql.NVarChar, nuevoEstado)
        .query(`
          UPDATE anteproyectos
          SET titulo              = @titulo,
              descripcion         = @desc,
              ruta_archivo        = @ruta,
              asesores_propuestos = @propuestos,
              estado              = @estado,
              comentario_admin    = NULL,
              fecha_envio         = GETDATE()
          WHERE id_anteproyecto = @id
        `);

      const mensaje = tieneAsesor
        ? `Tu anteproyecto "${titulo}" fue actualizado y enviado directamente a tu asesor para revision.`
        : `Tu anteproyecto "${titulo}" fue actualizado y enviado al administrador para revision.`;

      await NotifModel.crear({ idUsuario: idAlumno, tipo: 'anteproyecto_enviado', mensaje });
      return ok(res, { id: existente.id_anteproyecto }, mensaje);
    }

    // Nuevo
    // Guardar ruta relativa (uploads/anteproyectos/archivo.pdf)
    // para que el frontend pueda construir la URL correctamente
    const rutaRelativa = `uploads/anteproyectos/${req.file.filename}`;
    const id = await AntepModel.crear({
      idAlumno, titulo, descripcion,
      rutaArchivo: rutaRelativa,
      asesoresPropuestos: asesoresPropuestos || null,
    });

    await NotifModel.crear({
      idUsuario: idAlumno,
      tipo:      'anteproyecto_enviado',
      mensaje:   `Tu anteproyecto "${titulo}" fue enviado. El administrador lo revisara pronto.`,
    });

    return created(res, { id }, 'Anteproyecto enviado correctamente.');
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Alumno ve su propio anteproyecto ─────────────────────────────────────────
async function miAnteproyecto(req, res) {
  try {
    const antep = await AntepModel.buscarPorAlumno(req.usuario.id);
    if (!antep) return notFound(res, 'Aun no has subido un anteproyecto.');
    return ok(res, antep);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Admin: listar todos ───────────────────────────────────────────────────────
async function listar(req, res) {
  try {
    return ok(res, await AntepModel.listar(req.query.estado || null));
  } catch (err) {
    return serverError(res, err);
  }
}

async function pendientes(req, res) {
  try {
    return ok(res, await AntepModel.listar('pendiente'));
  } catch (err) {
    return serverError(res, err);
  }
}

async function verPorId(req, res) {
  try {
    const antep = await AntepModel.buscarPorId(parseInt(req.params.id));
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');
    return ok(res, antep);
  } catch (err) {
    return serverError(res, err);
  }
}

async function verPorPostulacion(req, res) {
  try {
    const antep = await AntepModel.buscarPorPostulacion(parseInt(req.params.idPostulacion));
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');
    return ok(res, antep);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Admin: asignar asesor ─────────────────────────────────────────────────────
// El admin NO aprueba/rechaza, solo asigna. El asesor es quien aprueba.
async function asignarAsesor(req, res) {
  try {
    const id = parseInt(req.params.id);
    const { idAsesor } = req.body;
    if (!idAsesor) return badRequest(res, 'idAsesor es requerido.');

    const antep = await AntepModel.buscarPorId(id);
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');

    await AntepModel.asignarAsesor(id, parseInt(idAsesor));

    // Notificar al alumno
    await NotifModel.crear({
      idUsuario: antep.id_alumno,
      tipo:      'asesor_asignado',
      mensaje:   'Tu anteproyecto fue revisado por el administrador y se te asigno un asesor. Espera su retroalimentacion.',
    });

    return ok(res, {}, 'Asesor asignado correctamente. El asesor revisara el anteproyecto.');
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Asesor: ver sus anteproyectos asignados ───────────────────────────────────
async function porAsesor(req, res) {
  try {
    return ok(res, await AntepModel.porAsesor(req.usuario.id));
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Asesor: dar retroalimentacion ─────────────────────────────────────────────
async function revisarAsesor(req, res) {
  try {
    const id = parseInt(req.params.id);
    const { estado, comentario } = req.body;

    const estadosValidos = ['aprobado', 'con_observaciones', 'rechazado'];
    if (!estadosValidos.includes(estado))
      return badRequest(res, `El asesor puede marcar: ${estadosValidos.join(', ')}.`);
    if (!comentario && estado !== 'aprobado')
      return badRequest(res, 'Se requiere un comentario al rechazar o poner observaciones.');

    const antep = await AntepModel.buscarPorId(id);
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');

    // Solo puede revisar anteproyectos que le fueron asignados
    if (antep.id_asesor_asignado !== req.usuario.id)
      return badRequest(res, 'Este anteproyecto no esta asignado a ti.');

    await AntepModel.actualizar(id, { estado, comentario });

    const mensajes = {
      aprobado:          `Tu asesor aprobo tu anteproyecto. Puedes continuar con tu residencia.`,
      rechazado:         `Tu asesor rechazo tu anteproyecto.${comentario ? ' Motivo: ' + comentario : ''} Corriges y vuelves a enviarlo.`,
      con_observaciones: `Tu asesor regreso tu anteproyecto con observaciones.${comentario ? ' ' + comentario : ''} Realiza las correcciones.`,
    };

    await NotifModel.crear({
      idUsuario: antep.id_alumno,
      tipo:      `anteproyecto_${estado}`,
      mensaje:   mensajes[estado],
    });

    return ok(res, {}, `Retroalimentacion enviada. Anteproyecto marcado como ${estado}.`);
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = {
  subir, miAnteproyecto,
  listar, pendientes, verPorId, verPorPostulacion,
  asignarAsesor, porAsesor, revisarAsesor,
};
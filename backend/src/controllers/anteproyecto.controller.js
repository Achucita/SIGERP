// src/controllers/anteproyecto.controller.js
const AntepModel = require('../models/anteproyecto.model');
const PostModel  = require('../models/postulacion.model');
const ProyModel  = require('../models/proyecto.model');
const NotifModel = require('../models/notificacion.model');
const { ok, created, badRequest, forbidden, notFound, serverError } = require('../utils/response');

// ── Alumno sube su anteproyecto ───────────────────────────────────────────────
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo PDF o DOCX.');

    const { titulo, descripcion, id_postulacion } = req.body;
    if (!titulo || !id_postulacion)
      return badRequest(res, 'titulo e id_postulacion son requeridos.');

    const idPostulacion = parseInt(id_postulacion);
    const post = await PostModel.buscarPorId(idPostulacion);
    if (!post) return notFound(res, 'Postulación no encontrada.');
    if (post.id_alumno !== req.usuario.id)
      return forbidden(res, 'Esta postulación no es tuya.');

    // Ya NO se requiere que la postulación esté aceptada —
    // cualquier alumno postulado puede subir su anteproyecto
    const existente = await AntepModel.buscarPorPostulacion(idPostulacion);
    if (existente) {
      // Actualizar en lugar de rechazar — el alumno puede reenviar
      await AntepModel.actualizar(existente.id_anteproyecto, {
        estado:     'pendiente',
        comentario: null,
      });
      // También actualiza la ruta del archivo si cambió
      const { getPool, sql } = require('../config/db');
      const pool = await getPool();
      await pool.request()
        .input('id',     sql.Int,      existente.id_anteproyecto)
        .input('titulo', sql.NVarChar, titulo)
        .input('desc',   sql.NVarChar, descripcion || null)
        .input('ruta',   sql.NVarChar, req.file.path)
        .query(`
          UPDATE anteproyectos
          SET titulo = @titulo, descripcion = @desc,
              ruta_archivo = @ruta, estado = 'pendiente',
              comentario_admin = NULL, fecha_revision = NULL
          WHERE id_anteproyecto = @id
        `);

      await NotifModel.crear({
        idUsuario: req.usuario.id,
        tipo:      'anteproyecto_enviado',
        mensaje:   `Tu anteproyecto "${titulo}" fue actualizado y enviado para revisión.`,
      });
      return ok(res, { id: existente.id_anteproyecto }, 'Anteproyecto actualizado y enviado para revisión.');
    }

    const id = await AntepModel.crear({
      idPostulacion,
      titulo,
      descripcion,
      rutaArchivo: req.file.path,
    });

    await NotifModel.crear({
      idUsuario: req.usuario.id,
      tipo:      'anteproyecto_enviado',
      mensaje:   `Tu anteproyecto "${titulo}" fue enviado. El administrador lo revisará pronto.`,
    });

    return created(res, { id }, 'Anteproyecto enviado correctamente.');
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Alumno ve su propio anteproyecto por postulación ─────────────────────────
async function miAnteproyecto(req, res) {
  try {
    const antep = await AntepModel.buscarPorPostulacion(parseInt(req.params.idPostulacion));
    if (!antep) return notFound(res, 'No has subido un anteproyecto para esta postulación.');
    if (antep.id_alumno !== req.usuario.id)
      return forbidden(res, 'No tienes acceso a este anteproyecto.');
    return ok(res, antep);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Admin: ver todos los anteproyectos con filtro opcional ?estado= ───────────
async function listar(req, res) {
  try {
    const lista = await AntepModel.listar(req.query.estado || null);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Admin: ver anteproyectos pendientes ───────────────────────────────────────
async function pendientes(req, res) {
  try {
    const lista = await AntepModel.listar('pendiente');
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Ver uno por id ────────────────────────────────────────────────────────────
async function verPorId(req, res) {
  try {
    const antep = await AntepModel.buscarPorId(parseInt(req.params.id));
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');
    return ok(res, antep);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Ver por postulación ───────────────────────────────────────────────────────
async function verPorPostulacion(req, res) {
  try {
    const antep = await AntepModel.buscarPorPostulacion(parseInt(req.params.idPostulacion));
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');
    return ok(res, antep);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Admin: revisar anteproyecto (aprobar/rechazar + asignar asesor) ───────────
async function revisar(req, res) {
  try {
    const id = parseInt(req.params.id);
    const { estado, comentario, idAsesor } = req.body;

    const estadosValidos = ['aprobado', 'rechazado', 'con_observaciones'];
    if (!estadosValidos.includes(estado))
      return badRequest(res, `estado debe ser: ${estadosValidos.join(', ')}.`);

    if (estado === 'aprobado' && !idAsesor)
      return badRequest(res, 'Se requiere idAsesor para aprobar el anteproyecto.');

    const antep = await AntepModel.buscarPorId(id);
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');

    await AntepModel.actualizar(id, { estado, comentario });

    // Al aprobar, asignar asesor al proyecto
    if (estado === 'aprobado' && idAsesor) {
      await ProyModel.asignarAsesor(antep.id_proyecto, parseInt(idAsesor));
      await NotifModel.crear({
        idUsuario: antep.id_alumno,
        tipo:      'asesor_asignado',
        mensaje:   '¡Tu anteproyecto fue aprobado! Se te asignó un asesor académico. Ya puedes subir tus reportes de avance.',
      });
    }

    if (estado === 'rechazado') {
      await NotifModel.crear({
        idUsuario: antep.id_alumno,
        tipo:      'anteproyecto_rechazado',
        mensaje:   `Tu anteproyecto fue rechazado.${comentario ? ' Motivo: ' + comentario : ''} Puedes corregirlo y volver a enviarlo.`,
      });
    }

    if (estado === 'con_observaciones') {
      await NotifModel.crear({
        idUsuario: antep.id_alumno,
        tipo:      'anteproyecto_observaciones',
        mensaje:   `Tu anteproyecto tiene observaciones.${comentario ? ' ' + comentario : ''} Realiza las correcciones y vuelve a enviarlo.`,
      });
    }

    return ok(res, {}, `Anteproyecto marcado como ${estado}.`);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Asesor: revisar su anteproyecto asignado ──────────────────────────────────
async function revisarAsesor(req, res) {
  try {
    const id = parseInt(req.params.id);
    const { estado, comentario } = req.body;

    const estadosValidos = ['aprobado', 'con_observaciones', 'rechazado'];
    if (!estadosValidos.includes(estado))
      return badRequest(res, `El asesor puede marcar: ${estadosValidos.join(', ')}.`);

    const antep = await AntepModel.buscarPorId(id);
    if (!antep) return notFound(res, 'Anteproyecto no encontrado.');

    await AntepModel.actualizar(id, { estado, comentario });

    const mensajes = {
      aprobado:          `Tu asesor aprobó tu anteproyecto. ¡Ya puedes comenzar tu residencia!`,
      rechazado:         `Tu asesor rechazó tu anteproyecto.${comentario ? ' ' + comentario : ''} Corrígelo y vuelve a enviarlo.`,
      con_observaciones: `Tu asesor regresó tu anteproyecto con observaciones.${comentario ? ' ' + comentario : ''}`,
    };

    await NotifModel.crear({
      idUsuario: antep.id_alumno,
      tipo:      `anteproyecto_${estado}`,
      mensaje:   mensajes[estado],
    });

    return ok(res, {}, `Anteproyecto ${estado} por el asesor.`);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Asesor: ver anteproyectos de sus proyectos ────────────────────────────────
async function porAsesor(req, res) {
  try {
    const lista = await AntepModel.porAsesor(req.usuario.id);
    return ok(res, lista);
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = {
  subir,
  miAnteproyecto,
  listar,
  pendientes,
  verPorId,
  verPorPostulacion,
  revisar,
  revisarAsesor,
  porAsesor,
};
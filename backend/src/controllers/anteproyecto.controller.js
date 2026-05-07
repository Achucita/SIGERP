// src/controllers/anteproyecto.controller.js
const AntepModel = require('../models/anteproyecto.model');
const ProyModel  = require('../models/proyecto.model');
const NotifModel = require('../models/notificacion.model');
const { ok, created, badRequest, forbidden, notFound, serverError } = require('../utils/response');

// ── Alumno sube su anteproyecto (sin postulación obligatoria) ─────────────────
async function subir(req, res) {
  try {
    if (!req.file) return badRequest(res, 'Se requiere un archivo PDF o DOCX.');

    const { titulo, descripcion } = req.body;
    if (!titulo) return badRequest(res, 'El título es requerido.');

    const idAlumno = req.usuario.id;

    // ¿Ya tiene uno? → actualizar en lugar de duplicar
    const existente = await AntepModel.buscarPorAlumno(idAlumno);
    if (existente) {
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
              comentario_admin = NULL, fecha_revision = NULL,
              fecha_envio = GETDATE()
          WHERE id_anteproyecto = @id
        `);

      await NotifModel.crear({
        idUsuario: idAlumno,
        tipo:      'anteproyecto_enviado',
        mensaje:   `Tu anteproyecto "${titulo}" fue actualizado y enviado para revisión.`,
      });
      return ok(res, { id: existente.id_anteproyecto }, 'Anteproyecto actualizado y enviado para revisión.');
    }

    // Nuevo anteproyecto
    const id = await AntepModel.crear({ idAlumno, titulo, descripcion, rutaArchivo: req.file.path });

    await NotifModel.crear({
      idUsuario: idAlumno,
      tipo:      'anteproyecto_enviado',
      mensaje:   `Tu anteproyecto "${titulo}" fue enviado. El administrador lo revisará pronto.`,
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
    if (!antep) return notFound(res, 'Aún no has subido un anteproyecto.');
    return ok(res, antep);
  } catch (err) {
    return serverError(res, err);
  }
}

// ── Admin: ver todos los anteproyectos ───────────────────────────────────────
async function listar(req, res) {
  try {
    const lista = await AntepModel.listar(req.query.estado || null);
    return ok(res, lista);
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

// ── Admin: aprobar / rechazar ─────────────────────────────────────────────────
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

    if (estado === 'aprobado' && idAsesor && antep.id_proyecto) {
      await ProyModel.asignarAsesor(antep.id_proyecto, parseInt(idAsesor));
      await NotifModel.crear({
        idUsuario: antep.id_alumno,
        tipo:      'asesor_asignado',
        mensaje:   '¡Tu anteproyecto fue aprobado! Se te asignó un asesor académico.',
      });
    } else if (estado === 'aprobado') {
      await NotifModel.crear({
        idUsuario: antep.id_alumno,
        tipo:      'anteproyecto_aprobado',
        mensaje:   '¡Tu anteproyecto fue aprobado por el administrador!',
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

// ── Asesor ────────────────────────────────────────────────────────────────────
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
      aprobado:          `Tu asesor aprobó tu anteproyecto.`,
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

async function porAsesor(req, res) {
  try {
    return ok(res, await AntepModel.porAsesor(req.usuario.id));
  } catch (err) {
    return serverError(res, err);
  }
}

module.exports = { subir, miAnteproyecto, listar, pendientes, verPorId, verPorPostulacion, revisar, revisarAsesor, porAsesor };
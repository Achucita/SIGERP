// src/models/expediente.model.js
const { getPool, sql } = require('../config/db');

// Lista todos los alumnos registrados (con o sin postulacion)
async function listarAlumnos() {
  const pool = await getPool();
  const res  = await pool.request().query(`
    SELECT
      u.id_usuario            AS id_alumno,
      u.nombre, u.correo,
      al.matricula, al.carrera,
      -- Proyecto y empresa de la postulacion mas reciente (si existe)
      ISNULL(p.nombre,  '—') AS proyecto,
      ISNULL(e.nombre,  '—') AS empresa,
      ISNULL(po.estado, '—') AS estado_postulacion,
      po.fecha_postulacion,
      (SELECT COUNT(*) FROM reportes          r   WHERE r.id_alumno   = al.id_alumno) AS total_reportes,
      (SELECT COUNT(*) FROM evidencias        ev  WHERE ev.id_alumno  = al.id_alumno) AS total_evidencias,
      (SELECT COUNT(*) FROM documentos_alumno d   WHERE d.id_alumno   = al.id_alumno) AS total_documentos,
      (SELECT COUNT(*) FROM anteproyectos     ant WHERE ant.id_alumno = al.id_alumno) AS total_anteproyectos
    FROM   alumnos  al
    JOIN   usuarios u   ON u.id_usuario = al.id_alumno AND u.activo = 1
    -- JOIN opcional: tomar solo la postulacion aceptada, o la mas reciente si no hay aceptada
    LEFT JOIN postulaciones po ON po.id_alumno  = al.id_alumno
          AND po.id_postulacion = (
            SELECT TOP 1 id_postulacion FROM postulaciones p2
            WHERE p2.id_alumno = al.id_alumno
            ORDER BY CASE WHEN p2.estado = 'aceptada' THEN 0 ELSE 1 END, p2.fecha_postulacion DESC
          )
    LEFT JOIN proyectos p ON p.id_proyecto = po.id_proyecto
    LEFT JOIN empresas  e ON e.id_empresa  = p.id_empresa
    ORDER BY u.nombre ASC
  `);
  return res.recordset;
}

// Expediente completo de un alumno
async function expedienteCompleto(idAlumno) {
  const pool = await getPool();

  const base = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT
        u.id_usuario  AS id_alumno,
        u.nombre, u.correo, u.fecha_registro,
        al.matricula, al.carrera,
        ISNULL(p.nombre,       '—') AS proyecto,
        ISNULL(p.descripcion,  '')  AS proyecto_descripcion,
        ISNULL(e.nombre,       '—') AS empresa,
        ISNULL(e.correo_empresa,'') AS empresa_contacto,
        ISNULL(e.telefono,     '')  AS empresa_telefono,
        ISNULL(e.nombre_responsable,'') AS nombre_responsable,
        ISNULL(ua.nombre, 'Sin asignar') AS asesor,
        ISNULL(po.estado, '—')      AS estado_postulacion,
        po.id_postulacion,
        po.fecha_postulacion
      FROM   alumnos  al
      JOIN   usuarios u   ON u.id_usuario = al.id_alumno
      LEFT JOIN postulaciones po ON po.id_alumno  = al.id_alumno
            AND po.id_postulacion = (
              SELECT TOP 1 id_postulacion FROM postulaciones p2
              WHERE p2.id_alumno = al.id_alumno
              ORDER BY CASE WHEN p2.estado = 'aceptada' THEN 0 ELSE 1 END, p2.fecha_postulacion DESC
            )
      LEFT JOIN proyectos p  ON p.id_proyecto = po.id_proyecto
      LEFT JOIN empresas  e  ON e.id_empresa  = p.id_empresa
      LEFT JOIN usuarios  ua ON ua.id_usuario = p.id_asesor
      WHERE  al.id_alumno = @id
    `);

  const docs = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_documento, nombre, ruta_archivo, fecha_subida
      FROM   documentos_alumno
      WHERE  id_alumno = @id
      ORDER BY fecha_subida DESC
    `);

  // Reportes con columnas reales de la BD
  const reportes = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_reporte, numero_reporte, titulo, descripcion,
             periodo_inicio, periodo_fin,
             ruta_archivo, estado, fecha_envio,
             comentario_asesor, comentario_admin
      FROM   reportes
      WHERE  id_alumno = @id
      ORDER BY numero_reporte ASC
    `);

  const evidencias = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_evidencia, descripcion, ruta_archivo,
             comentario_asesor, fecha_envio, fecha_comentario
      FROM   evidencias
      WHERE  id_alumno = @id
      ORDER BY fecha_envio DESC
    `);

  // Anteproyecto por id_alumno directo
  const anteproyectos = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_anteproyecto, titulo, descripcion,
             ruta_archivo, estado, comentario_admin,
             fecha_envio, asesores_propuestos
      FROM   anteproyectos
      WHERE  id_alumno = @id
      ORDER BY fecha_envio DESC
    `);

  return {
    alumno:        base.recordset[0] || null,
    documentos:    docs.recordset,
    reportes:      reportes.recordset,
    evidencias:    evidencias.recordset,
    anteproyectos: anteproyectos.recordset,
  };
}

module.exports = { listarAlumnos, expedienteCompleto };
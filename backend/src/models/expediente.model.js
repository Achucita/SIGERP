// src/models/expediente.model.js
const { getPool, sql } = require('../config/db');

// ── Lista de todos los alumnos en residencias ──────────────────────────────
// Un alumno "está en residencias" si tiene al menos una postulación aceptada
async function listarAlumnos() {
  const pool = await getPool();
  const res  = await pool.request().query(`
    SELECT
      u.id_usuario            AS id_alumno,
      u.nombre,
      u.correo,
      al.matricula,
      al.carrera,
      p.nombre                AS proyecto,
      e.nombre                AS empresa,
      po.estado               AS estado_postulacion,
      po.fecha_postulacion,
      -- conteos rápidos
      (SELECT COUNT(*) FROM reportes     r  WHERE r.id_alumno  = al.id_alumno) AS total_reportes,
      (SELECT COUNT(*) FROM evidencias   ev WHERE ev.id_alumno = al.id_alumno) AS total_evidencias,
      (SELECT COUNT(*) FROM documentos_alumno d WHERE d.id_alumno = al.id_alumno) AS total_documentos,
      (SELECT COUNT(*) FROM anteproyectos ant
         JOIN postulaciones po2 ON po2.id_postulacion = ant.id_postulacion
         WHERE po2.id_alumno = al.id_alumno) AS total_anteproyectos
    FROM   alumnos       al
    JOIN   usuarios      u  ON u.id_usuario  = al.id_alumno  AND u.activo = 1
    JOIN   postulaciones po ON po.id_alumno  = al.id_alumno  AND po.estado = 'aceptada'
    JOIN   proyectos     p  ON p.id_proyecto = po.id_proyecto
    JOIN   empresas      e  ON e.id_empresa  = p.id_empresa
    ORDER BY u.nombre ASC
  `);
  return res.recordset;
}

// ── Expediente completo de un alumno ──────────────────────────────────────
async function expedienteCompleto(idAlumno) {
  const pool = await getPool();

  // Datos base del alumno
  const base = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT
        u.id_usuario AS id_alumno, u.nombre, u.correo, u.fecha_registro,
        al.matricula, al.carrera,
        p.nombre       AS proyecto,
        p.descripcion  AS proyecto_descripcion,
        e.nombre       AS empresa,
        e.contacto     AS empresa_contacto,
        ua.nombre      AS asesor,
        po.estado      AS estado_postulacion,
        po.id_postulacion,
        po.fecha_postulacion
      FROM   alumnos       al
      JOIN   usuarios      u   ON u.id_usuario  = al.id_alumno
      JOIN   postulaciones po  ON po.id_alumno  = al.id_alumno AND po.estado = 'aceptada'
      JOIN   proyectos     p   ON p.id_proyecto = po.id_proyecto
      JOIN   empresas      e   ON e.id_empresa  = p.id_empresa
      LEFT JOIN usuarios   ua  ON ua.id_usuario = p.id_asesor
      WHERE  al.id_alumno = @id
    `);

  // Documentos
  const docs = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_documento, nombre, ruta_archivo, fecha_subida
      FROM   documentos_alumno
      WHERE  id_alumno = @id
      ORDER BY fecha_subida DESC
    `);

  // Reportes
  const reportes = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_reporte, numero_reporte, periodo_cubre,
             ruta_archivo, estado, fecha_envio, fecha_revision,
             comentarios_adicionales, comentario_admin
      FROM   reportes
      WHERE  id_alumno = @id
      ORDER BY numero_reporte ASC
    `);

  // Evidencias
  const evidencias = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_evidencia, descripcion, ruta_archivo,
             comentario_asesor, fecha_envio, fecha_comentario
      FROM   evidencias
      WHERE  id_alumno = @id
      ORDER BY fecha_envio DESC
    `);

  // Anteproyecto(s)
  const anteproyectos = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT ant.id_anteproyecto, ant.titulo, ant.descripcion,
             ant.ruta_archivo, ant.estado,
             ant.comentario_admin, ant.fecha_envio, ant.fecha_revision
      FROM   anteproyectos ant
      JOIN   postulaciones po ON po.id_postulacion = ant.id_postulacion
      WHERE  po.id_alumno = @id
      ORDER BY ant.fecha_envio DESC
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
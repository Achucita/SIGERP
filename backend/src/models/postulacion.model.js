// src/models/postulacion.model.js
const { getPool, sql } = require('../config/db');

/**
 * Crea una postulación. Si el alumno adjuntó CV, guarda la ruta.
 */
async function crear({ idAlumno, idProyecto, cvRuta = null }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno',   sql.Int,          idAlumno)
    .input('proyecto', sql.Int,          idProyecto)
    .input('cvRuta',   sql.NVarChar(500), cvRuta)
    .query(`
      INSERT INTO postulaciones (id_alumno, id_proyecto, cv_ruta)
      OUTPUT INSERTED.id_postulacion
      VALUES (@alumno, @proyecto, @cvRuta)
    `);
  return res.recordset[0].id_postulacion;
}

async function yaExiste({ idAlumno, idProyecto }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno',   sql.Int, idAlumno)
    .input('proyecto', sql.Int, idProyecto)
    .query(`
      SELECT 1 AS existe FROM postulaciones
      WHERE id_alumno = @alumno AND id_proyecto = @proyecto
    `);
  return res.recordset.length > 0;
}

async function buscarPorId(id) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, id)
    .query(`
      SELECT po.id_postulacion, po.id_alumno, po.id_proyecto,
             po.fecha_postulacion, po.correo_enviado, po.cv_ruta,
             p.nombre  AS proyecto,
             e.nombre  AS empresa,
             e.correo_empresa
      FROM   postulaciones po
      JOIN   proyectos p ON p.id_proyecto = po.id_proyecto
      JOIN   empresas  e ON e.id_empresa  = p.id_empresa
      WHERE  po.id_postulacion = @id
    `);
  return res.recordset[0] || null;
}

// Lo que ve el alumno: sus postulaciones + asesor asignado al proyecto
async function porAlumno(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT
        po.id_postulacion,
        po.id_alumno,
        po.id_proyecto,
        po.fecha_postulacion,
        po.cv_ruta,
        p.nombre                        AS proyecto,
        e.nombre                        AS empresa,
        ISNULL(ua.nombre, NULL)         AS asesor_interno
      FROM   postulaciones po
      JOIN   proyectos     p   ON p.id_proyecto = po.id_proyecto
      JOIN   empresas      e   ON e.id_empresa  = p.id_empresa
      LEFT JOIN asesores   a   ON a.id_asesor   = p.id_asesor
      LEFT JOIN usuarios   ua  ON ua.id_usuario = a.id_asesor
      WHERE  po.id_alumno = @id
      ORDER BY po.fecha_postulacion DESC
    `);
  return res.recordset;
}

async function porProyecto(idProyecto) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idProyecto)
    .query(`
      SELECT po.id_postulacion, po.id_alumno, po.fecha_postulacion,
             po.cv_ruta,
             u.nombre AS alumno, al.matricula, al.carrera
      FROM   postulaciones po
      JOIN   alumnos       al ON al.id_alumno  = po.id_alumno
      JOIN   usuarios      u  ON u.id_usuario  = al.id_alumno
      WHERE  po.id_proyecto = @id
      ORDER BY po.fecha_postulacion DESC
    `);
  return res.recordset;
}

async function marcarCorreoEnviado(id) {
  const pool = await getPool();
  await pool.request()
    .input('id', sql.Int, id)
    .query('UPDATE postulaciones SET correo_enviado = 1 WHERE id_postulacion = @id');
}

module.exports = { crear, yaExiste, buscarPorId, porAlumno, porProyecto, marcarCorreoEnviado };
// src/models/evidencia.model.js
const { getPool, sql } = require('../config/db');

async function crear({ idAlumno, descripcion, rutaArchivo }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno',      sql.Int,      idAlumno)
    .input('descripcion', sql.NVarChar, descripcion || null)
    .input('ruta',        sql.NVarChar, rutaArchivo)
    .query(`
      INSERT INTO evidencias (id_alumno, descripcion, ruta_archivo)
      OUTPUT INSERTED.id_evidencia
      VALUES (@alumno, @descripcion, @ruta)
    `);
  return res.recordset[0].id_evidencia;
}

// Alumno ve sus evidencias con los comentarios del asesor
async function porAlumno(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT e.id_evidencia, e.descripcion, e.ruta_archivo,
             e.comentario_asesor, e.fecha_envio, e.fecha_comentario
      FROM   evidencias e
      WHERE  e.id_alumno = @id
      ORDER BY e.fecha_envio DESC
    `);
  return res.recordset;
}

// Asesor ve todas las evidencias de sus alumnos
async function porAsesor(idAsesor) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('asesor', sql.Int, idAsesor)
    .query(`
      SELECT e.id_evidencia, e.descripcion, e.ruta_archivo,
             e.comentario_asesor, e.fecha_envio, e.fecha_comentario,
             u.nombre   AS alumno,
             al.matricula, al.carrera
      FROM   evidencias    e
      JOIN   alumnos       al  ON al.id_alumno  = e.id_alumno
      JOIN   usuarios      u   ON u.id_usuario  = al.id_alumno
      JOIN   postulaciones po  ON po.id_alumno  = e.id_alumno
      JOIN   proyectos     p   ON p.id_proyecto = po.id_proyecto
      WHERE  p.id_asesor = @asesor
      ORDER BY e.fecha_envio DESC
    `);
  return res.recordset;
}

// Asesor agrega comentario a una evidencia (sin calificación)
async function comentar(id, comentario) {
  const pool = await getPool();
  await pool.request()
    .input('id',         sql.Int,      id)
    .input('comentario', sql.NVarChar, comentario)
    .query(`
      UPDATE evidencias
      SET comentario_asesor = @comentario, fecha_comentario = GETDATE()
      WHERE  id_evidencia = @id
    `);
}

module.exports = { crear, porAlumno, porAsesor, comentar };
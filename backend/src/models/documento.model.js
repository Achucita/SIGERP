// src/models/documento.model.js
const { getPool, sql } = require('../config/db');

async function crear({ idAlumno, nombre, rutaArchivo }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno', sql.Int,      idAlumno)
    .input('nombre', sql.NVarChar, nombre)
    .input('ruta',   sql.NVarChar, rutaArchivo)
    .query(`
      INSERT INTO documentos_alumno (id_alumno, nombre, ruta_archivo)
      OUTPUT INSERTED.id_documento
      VALUES (@alumno, @nombre, @ruta)
    `);
  return res.recordset[0].id_documento;
}

// Documentos del alumno
async function porAlumno(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_documento, nombre, ruta_archivo, fecha_subida
      FROM   documentos_alumno
      WHERE  id_alumno = @id
      ORDER BY fecha_subida DESC
    `);
  return res.recordset;
}

// Admin ve documentos de cualquier alumno
async function porAlumnoAdmin(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT d.id_documento, d.nombre, d.ruta_archivo, d.fecha_subida,
             u.nombre AS alumno, al.matricula, al.carrera
      FROM   documentos_alumno d
      JOIN   alumnos           al ON al.id_alumno = d.id_alumno
      JOIN   usuarios          u  ON u.id_usuario = al.id_alumno
      WHERE  d.id_alumno = @id
      ORDER BY d.fecha_subida DESC
    `);
  return res.recordset;
}

// Admin ve todos los documentos de todos
async function listarTodos() {
  const pool = await getPool();
  const res  = await pool.request().query(`
    SELECT d.id_documento, d.nombre, d.ruta_archivo, d.fecha_subida,
           u.nombre AS alumno, al.matricula, al.carrera
    FROM   documentos_alumno d
    JOIN   alumnos           al ON al.id_alumno = d.id_alumno
    JOIN   usuarios          u  ON u.id_usuario = al.id_alumno
    ORDER BY al.matricula, d.fecha_subida DESC
  `);
  return res.recordset;
}

async function eliminar(id, idAlumno) {
  const pool = await getPool();
  await pool.request()
    .input('id',     sql.Int, id)
    .input('alumno', sql.Int, idAlumno)
    .query('DELETE FROM documentos_alumno WHERE id_documento = @id AND id_alumno = @alumno');
}

module.exports = { crear, porAlumno, porAlumnoAdmin, listarTodos, eliminar };
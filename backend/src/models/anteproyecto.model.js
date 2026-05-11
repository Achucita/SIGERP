// src/models/anteproyecto.model.js
const { getPool, sql } = require('../config/db');

async function crear({ idAlumno, titulo, descripcion, rutaArchivo, asesoresPropuestos }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno',      sql.Int,      idAlumno)
    .input('titulo',      sql.NVarChar, titulo)
    .input('descripcion', sql.NVarChar, descripcion || null)
    .input('ruta',        sql.NVarChar, rutaArchivo)
    .input('propuestos',  sql.NVarChar, asesoresPropuestos || null)
    .query(`
      INSERT INTO anteproyectos
        (id_alumno, id_postulacion, titulo, descripcion, ruta_archivo, asesores_propuestos)
      OUTPUT INSERTED.id_anteproyecto
      VALUES (@alumno, NULL, @titulo, @descripcion, @ruta, @propuestos)
    `);
  return res.recordset[0].id_anteproyecto;
}

async function buscarPorAlumno(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT
        ant.id_anteproyecto, ant.titulo, ant.descripcion,
        ant.ruta_archivo, ant.estado,
        ant.comentario_admin, ant.fecha_envio, ant.fecha_revision,
        ant.id_alumno, ant.asesores_propuestos,
        u.nombre     AS alumno,
        al.matricula,
        ua.nombre    AS asesor_asignado
      FROM   anteproyectos ant
      JOIN   usuarios      u   ON u.id_usuario  = ant.id_alumno
      JOIN   alumnos       al  ON al.id_alumno  = ant.id_alumno
      LEFT JOIN usuarios   ua  ON ua.id_usuario = ant.id_asesor_asignado
      WHERE  ant.id_alumno = @id
    `);
  return res.recordset[0] || null;
}

async function buscarPorId(id) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, id)
    .query(`
      SELECT
        ant.id_anteproyecto, ant.titulo, ant.descripcion,
        ant.ruta_archivo, ant.estado,
        ant.comentario_admin, ant.fecha_envio, ant.fecha_revision,
        ant.id_alumno, ant.id_postulacion, ant.asesores_propuestos,
        ant.id_asesor_asignado,
        u.nombre    AS alumno,
        al.matricula, al.carrera,
        ua.nombre   AS asesor_asignado,
        po.id_proyecto,
        p.nombre    AS proyecto,
        e.nombre    AS empresa
      FROM   anteproyectos ant
      JOIN   usuarios      u   ON u.id_usuario      = ant.id_alumno
      JOIN   alumnos       al  ON al.id_alumno      = ant.id_alumno
      LEFT JOIN usuarios   ua  ON ua.id_usuario     = ant.id_asesor_asignado
      LEFT JOIN postulaciones po ON po.id_postulacion = ant.id_postulacion
      LEFT JOIN proyectos     p  ON p.id_proyecto     = po.id_proyecto
      LEFT JOIN empresas      e  ON e.id_empresa      = p.id_empresa
      WHERE  ant.id_anteproyecto = @id
    `);
  return res.recordset[0] || null;
}

async function buscarPorPostulacion(idPostulacion) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idPostulacion)
    .query(`
      SELECT ant.*, u.nombre AS alumno, al.matricula,
             ua.nombre AS asesor_asignado,
             po.id_proyecto, p.nombre AS proyecto, e.nombre AS empresa
      FROM   anteproyectos ant
      JOIN   usuarios      u  ON u.id_usuario       = ant.id_alumno
      JOIN   alumnos       al ON al.id_alumno       = ant.id_alumno
      LEFT JOIN usuarios   ua ON ua.id_usuario      = ant.id_asesor_asignado
      LEFT JOIN postulaciones po ON po.id_postulacion = ant.id_postulacion
      LEFT JOIN proyectos     p  ON p.id_proyecto     = po.id_proyecto
      LEFT JOIN empresas      e  ON e.id_empresa      = p.id_empresa
      WHERE  ant.id_postulacion = @id
    `);
  return res.recordset[0] || null;
}

async function listar(estado = null) {
  const pool = await getPool();
  const req  = pool.request();
  let where  = '';
  if (estado) {
    req.input('estado', sql.NVarChar, estado);
    where = 'WHERE ant.estado = @estado';
  }
  const res = await req.query(`
    SELECT
      ant.id_anteproyecto, ant.titulo, ant.estado,
      ant.comentario_admin, ant.fecha_envio, ant.fecha_revision,
      ant.ruta_archivo, ant.id_alumno, ant.id_postulacion,
      ant.asesores_propuestos, ant.id_asesor_asignado,
      u.nombre    AS alumno,
      al.matricula, al.carrera,
      ua.nombre   AS asesor_asignado,
      ISNULL(po.id_proyecto, 0)  AS id_proyecto,
      ISNULL(p.nombre,  '—')     AS proyecto,
      ISNULL(e.nombre,  '—')     AS empresa
    FROM   anteproyectos ant
    JOIN   usuarios      u   ON u.id_usuario      = ant.id_alumno
    JOIN   alumnos       al  ON al.id_alumno      = ant.id_alumno
    LEFT JOIN usuarios   ua  ON ua.id_usuario     = ant.id_asesor_asignado
    LEFT JOIN postulaciones po ON po.id_postulacion = ant.id_postulacion
    LEFT JOIN proyectos     p  ON p.id_proyecto     = po.id_proyecto
    LEFT JOIN empresas      e  ON e.id_empresa      = p.id_empresa
    ${where}
    ORDER BY ant.fecha_envio DESC
  `);
  return res.recordset;
}

// Anteproyectos asignados a un asesor para que los revise
async function porAsesor(idAsesor) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('asesor', sql.Int, idAsesor)
    .query(`
      SELECT
        ant.id_anteproyecto, ant.titulo, ant.estado,
        ant.comentario_admin, ant.fecha_envio, ant.ruta_archivo,
        ant.id_alumno, ant.asesores_propuestos,
        u.nombre   AS alumno,
        al.matricula, al.carrera,
        ISNULL(p.nombre, '—') AS proyecto,
        ISNULL(e.nombre, '—') AS empresa
      FROM   anteproyectos ant
      JOIN   usuarios      u  ON u.id_usuario      = ant.id_alumno
      JOIN   alumnos       al ON al.id_alumno      = ant.id_alumno
      LEFT JOIN postulaciones po ON po.id_postulacion = ant.id_postulacion
      LEFT JOIN proyectos     p  ON p.id_proyecto     = po.id_proyecto
      LEFT JOIN empresas      e  ON e.id_empresa      = p.id_empresa
      WHERE  ant.id_asesor_asignado = @asesor
      ORDER BY ant.fecha_envio DESC
    `);
  return res.recordset;
}

// Admin asigna asesor
async function asignarAsesor(id, idAsesor) {
  const pool = await getPool();
  await pool.request()
    .input('id',     sql.Int, id)
    .input('asesor', sql.Int, idAsesor)
    .query(`
      UPDATE anteproyectos
      SET id_asesor_asignado = @asesor,
          estado = 'asignado'
      WHERE id_anteproyecto = @id
    `);
}

// Admin o asesor actualiza estado con comentario
async function actualizar(id, { estado, comentario }) {
  const pool = await getPool();
  await pool.request()
    .input('id',         sql.Int,      id)
    .input('estado',     sql.NVarChar, estado)
    .input('comentario', sql.NVarChar, comentario || null)
    .query(`
      UPDATE anteproyectos
      SET estado           = @estado,
          comentario_admin = @comentario,
          fecha_revision   = GETDATE()
      WHERE id_anteproyecto = @id
    `);
}

module.exports = {
  crear, buscarPorAlumno, buscarPorId, buscarPorPostulacion,
  listar, porAsesor, asignarAsesor, actualizar,
};
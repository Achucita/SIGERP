// src/models/anteproyecto.model.js
const { getPool, sql } = require('../config/db');

async function crear({ idPostulacion, titulo, descripcion, rutaArchivo }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('postulacion', sql.Int,      idPostulacion)
    .input('titulo',      sql.NVarChar, titulo)
    .input('descripcion', sql.NVarChar, descripcion || null)
    .input('ruta',        sql.NVarChar, rutaArchivo)
    .query(`
      INSERT INTO anteproyectos (id_postulacion, titulo, descripcion, ruta_archivo)
      OUTPUT INSERTED.id_anteproyecto
      VALUES (@postulacion, @titulo, @descripcion, @ruta)
    `);
  return res.recordset[0].id_anteproyecto;
}

// Una sola definición de buscarPorId (la completa con JOINs)
async function buscarPorId(id) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, id)
    .query(`
      SELECT
        ant.id_anteproyecto, ant.titulo, ant.descripcion,
        ant.ruta_archivo,    ant.estado,
        ant.comentario_admin, ant.fecha_envio, ant.fecha_revision,
        ant.id_postulacion,
        po.id_alumno,  po.id_proyecto,
        u.nombre  AS alumno,
        al.matricula,
        p.nombre  AS proyecto,
        e.nombre  AS empresa
      FROM   anteproyectos ant
      JOIN   postulaciones po ON po.id_postulacion = ant.id_postulacion
      JOIN   alumnos       al ON al.id_alumno      = po.id_alumno
      JOIN   usuarios      u  ON u.id_usuario      = al.id_alumno
      JOIN   proyectos     p  ON p.id_proyecto     = po.id_proyecto
      JOIN   empresas      e  ON e.id_empresa      = p.id_empresa
      WHERE  ant.id_anteproyecto = @id
    `);
  return res.recordset[0] || null;
}

async function buscarPorPostulacion(idPostulacion) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idPostulacion)
    .query(`
      SELECT
        ant.id_anteproyecto, ant.titulo, ant.descripcion,
        ant.ruta_archivo,    ant.estado,
        ant.comentario_admin, ant.fecha_envio, ant.fecha_revision,
        ant.id_postulacion,
        po.id_alumno,  po.id_proyecto,
        u.nombre  AS alumno,
        al.matricula,
        p.nombre  AS proyecto,
        e.nombre  AS empresa
      FROM   anteproyectos ant
      JOIN   postulaciones po ON po.id_postulacion = ant.id_postulacion
      JOIN   alumnos       al ON al.id_alumno      = po.id_alumno
      JOIN   usuarios      u  ON u.id_usuario      = al.id_alumno
      JOIN   proyectos     p  ON p.id_proyecto     = po.id_proyecto
      JOIN   empresas      e  ON e.id_empresa      = p.id_empresa
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
      ant.ruta_archivo,    ant.id_postulacion,
      po.id_alumno,  po.id_proyecto,
      u.nombre  AS alumno,
      al.matricula, al.carrera,
      p.nombre  AS proyecto,
      e.nombre  AS empresa,
      ISNULL(ua.nombre, 'Sin asignar') AS asesor_actual
    FROM   anteproyectos ant
    JOIN   postulaciones po  ON po.id_postulacion = ant.id_postulacion
    JOIN   alumnos       al  ON al.id_alumno      = po.id_alumno
    JOIN   usuarios      u   ON u.id_usuario      = al.id_alumno
    JOIN   proyectos     p   ON p.id_proyecto     = po.id_proyecto
    JOIN   empresas      e   ON e.id_empresa      = p.id_empresa
    LEFT JOIN asesores   a   ON a.id_asesor       = p.id_asesor
    LEFT JOIN usuarios   ua  ON ua.id_usuario     = a.id_asesor
    ${where}
    ORDER BY ant.fecha_envio DESC
  `);
  return res.recordset;
}

async function porAsesor(idAsesor) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('asesor', sql.Int, idAsesor)
    .query(`
      SELECT
        ant.id_anteproyecto, ant.titulo, ant.estado,
        ant.comentario_admin, ant.fecha_envio, ant.ruta_archivo,
        ant.id_postulacion,
        po.id_alumno,  po.id_proyecto,
        u.nombre  AS alumno,
        al.matricula,
        p.nombre  AS proyecto
      FROM   anteproyectos ant
      JOIN   postulaciones po ON po.id_postulacion = ant.id_postulacion
      JOIN   alumnos       al ON al.id_alumno      = po.id_alumno
      JOIN   usuarios      u  ON u.id_usuario      = al.id_alumno
      JOIN   proyectos     p  ON p.id_proyecto     = po.id_proyecto
      WHERE  p.id_asesor = @asesor
      ORDER BY ant.fecha_envio DESC
    `);
  return res.recordset;
}

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
  crear,
  buscarPorId,
  buscarPorPostulacion,
  listar,
  porAsesor,
  actualizar,
};
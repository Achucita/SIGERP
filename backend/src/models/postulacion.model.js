const { getPool, sql } = require('../config/db');
 
async function crear({ idAlumno, idProyecto }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno',   sql.Int, idAlumno)
    .input('proyecto', sql.Int, idProyecto)
    .query(`
      INSERT INTO postulaciones (id_alumno, id_proyecto, correo_enviado)
      OUTPUT INSERTED.id_postulacion
      VALUES (@alumno, @proyecto, 0)
    `);
  return res.recordset[0].id_postulacion;
}
 
async function marcarCorreoEnviado(id) {
  const pool = await getPool();
  await pool.request()
    .input('id', sql.Int, id)
    .query('UPDATE postulaciones SET correo_enviado = 1 WHERE id_postulacion = @id');
}
 
async function yaExiste({ idAlumno, idProyecto }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno',   sql.Int, idAlumno)
    .input('proyecto', sql.Int, idProyecto)
    .query(`SELECT 1 AS existe FROM postulaciones
            WHERE id_alumno = @alumno AND id_proyecto = @proyecto`);
  return res.recordset.length > 0;
}
 
async function porAlumno(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT po.id_postulacion, po.estado, po.fecha_postulacion, po.correo_enviado,
             p.nombre AS proyecto, p.id_proyecto,
             e.nombre AS empresa,
             ISNULL(ant.estado, NULL) AS estado_anteproyecto
      FROM   postulaciones po
      JOIN   proyectos p   ON p.id_proyecto   = po.id_proyecto
      JOIN   empresas  e   ON e.id_empresa    = p.id_empresa
      LEFT JOIN anteproyectos ant ON ant.id_postulacion = po.id_postulacion
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
      SELECT po.id_postulacion, po.estado, po.fecha_postulacion,
             u.nombre AS alumno, al.matricula, al.carrera, u.correo
      FROM   postulaciones po
      JOIN   alumnos  al ON al.id_alumno    = po.id_alumno
      JOIN   usuarios u  ON u.id_usuario    = al.id_alumno
      WHERE  po.id_proyecto = @id
      ORDER BY po.fecha_postulacion DESC
    `);
  return res.recordset;
}
 
async function actualizarEstado(id, estado) {
  const pool = await getPool();
  await pool.request()
    .input('id',     sql.Int,      id)
    .input('estado', sql.NVarChar, estado)
    .query('UPDATE postulaciones SET estado = @estado WHERE id_postulacion = @id');
}
 
async function buscarPorId(id) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, id)
    .query(`
      SELECT po.*, u.nombre AS alumno, al.matricula, al.carrera, u.correo,
             p.nombre AS proyecto, e.correo_empresa, e.nombre AS empresa,
             e.correo_responsable
      FROM   postulaciones po
      JOIN   alumnos  al ON al.id_alumno   = po.id_alumno
      JOIN   usuarios u  ON u.id_usuario   = al.id_alumno
      JOIN   proyectos p ON p.id_proyecto  = po.id_proyecto
      JOIN   empresas  e ON e.id_empresa   = p.id_empresa
      WHERE  po.id_postulacion = @id
    `);
  return res.recordset[0] || null;
}
 
module.exports = { crear, marcarCorreoEnviado, yaExiste, porAlumno, porProyecto, actualizarEstado, buscarPorId };
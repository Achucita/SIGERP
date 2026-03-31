const { getPool, sql } = require('../config/db');
 
async function crear({ idAlumno, idProyecto, titulo, descripcion, periodoInicio, periodoFin, rutaArchivo }) {
  const pool = await getPool();
  // calcular número de reporte
  const cnt  = await pool.request()
    .input('al', sql.Int, idAlumno)
    .input('pr', sql.Int, idProyecto)
    .query('SELECT COUNT(*) AS n FROM reportes WHERE id_alumno = @al AND id_proyecto = @pr');
  const numero = cnt.recordset[0].n + 1;
 
  const res = await pool.request()
    .input('alumno',   sql.Int,      idAlumno)
    .input('proyecto', sql.Int,      idProyecto)
    .input('numero',   sql.Int,      numero)
    .input('titulo',   sql.NVarChar, titulo)
    .input('desc',     sql.NVarChar, descripcion || null)
    .input('pini',     sql.Date,     periodoInicio)
    .input('pfin',     sql.Date,     periodoFin)
    .input('ruta',     sql.NVarChar, rutaArchivo)
    .query(`
      INSERT INTO reportes
        (id_alumno, id_proyecto, numero_reporte, titulo, descripcion,
         periodo_inicio, periodo_fin, ruta_archivo)
      OUTPUT INSERTED.id_reporte
      VALUES (@alumno, @proyecto, @numero, @titulo, @desc, @pini, @pfin, @ruta)
    `);
  return res.recordset[0].id_reporte;
}
 
async function porAlumno(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT r.id_reporte, r.numero_reporte, r.titulo, r.estado,
             r.periodo_inicio, r.periodo_fin, r.comentario_asesor, r.fecha_envio,
             p.nombre AS proyecto
      FROM   reportes r
      JOIN   proyectos p ON p.id_proyecto = r.id_proyecto
      WHERE  r.id_alumno = @id
      ORDER BY r.numero_reporte DESC
    `);
  return res.recordset;
}
 
async function porProyecto(idProyecto) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idProyecto)
    .query(`
      SELECT r.id_reporte, r.numero_reporte, r.titulo, r.estado,
             r.periodo_inicio, r.periodo_fin, r.comentario_asesor, r.fecha_envio,
             u.nombre AS alumno, al.matricula
      FROM   reportes r
      JOIN   alumnos  al ON al.id_alumno   = r.id_alumno
      JOIN   usuarios u  ON u.id_usuario   = al.id_alumno
      WHERE  r.id_proyecto = @id
      ORDER BY r.numero_reporte DESC
    `);
  return res.recordset;
}
 
async function comentar(id, { estado, comentario }) {
  const pool = await getPool();
  await pool.request()
    .input('id',        sql.Int,      id)
    .input('estado',    sql.NVarChar, estado)
    .input('comentario', sql.NVarChar, comentario || null)
    .query(`
      UPDATE reportes
      SET estado = @estado, comentario_asesor = @comentario
      WHERE id_reporte = @id
    `);
}
 
module.exports = { crear, porAlumno, porProyecto, comentar };
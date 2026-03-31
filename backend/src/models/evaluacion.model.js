const { getPool, sql } = require('../config/db');
 
async function crear({ idAlumno, idAsesor, idProyecto, tipo, calificacion, comentarios, periodoEvaluado }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno',   sql.Int,      idAlumno)
    .input('asesor',   sql.Int,      idAsesor)
    .input('proyecto', sql.Int,      idProyecto)
    .input('tipo',     sql.NVarChar, tipo)
    .input('cal',      sql.Decimal,  calificacion)
    .input('com',      sql.NVarChar, comentarios || null)
    .input('periodo',  sql.NVarChar, periodoEvaluado || null)
    .query(`
      INSERT INTO evaluaciones
        (id_alumno, id_asesor, id_proyecto, tipo, calificacion, comentarios, periodo_evaluado)
      OUTPUT INSERTED.id_evaluacion
      VALUES (@alumno, @asesor, @proyecto, @tipo, @cal, @com, @periodo)
    `);
  return res.recordset[0].id_evaluacion;
}
 
async function porAlumno(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT ev.id_evaluacion, ev.tipo, ev.calificacion, ev.comentarios,
             ev.periodo_evaluado, ev.fecha_evaluacion,
             u.nombre AS asesor, p.nombre AS proyecto
      FROM   evaluaciones ev
      JOIN   usuarios  u ON u.id_usuario  = ev.id_asesor
      JOIN   proyectos p ON p.id_proyecto = ev.id_proyecto
      WHERE  ev.id_alumno = @id
      ORDER BY ev.fecha_evaluacion DESC
    `);
  return res.recordset;
}
 
module.exports = { crear, porAlumno };
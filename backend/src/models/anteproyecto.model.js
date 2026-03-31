const { getPool, sql } = require('../config/db');
 
async function crear({ idPostulacion, titulo, descripcion, rutaArchivo }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('postulacion',  sql.Int,      idPostulacion)
    .input('titulo',       sql.NVarChar, titulo)
    .input('descripcion',  sql.NVarChar, descripcion || null)
    .input('ruta',         sql.NVarChar, rutaArchivo)
    .query(`
      INSERT INTO anteproyectos (id_postulacion, titulo, descripcion, ruta_archivo)
      OUTPUT INSERTED.id_anteproyecto
      VALUES (@postulacion, @titulo, @descripcion, @ruta)
    `);
  return res.recordset[0].id_anteproyecto;
}
 
async function buscarPorPostulacion(idPostulacion) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idPostulacion)
    .query(`
      SELECT ant.*, u.nombre AS alumno, al.matricula,
             p.nombre AS proyecto
      FROM   anteproyectos ant
      JOIN   postulaciones po ON po.id_postulacion = ant.id_postulacion
      JOIN   alumnos       al ON al.id_alumno      = po.id_alumno
      JOIN   usuarios      u  ON u.id_usuario      = al.id_alumno
      JOIN   proyectos     p  ON p.id_proyecto     = po.id_proyecto
      WHERE  ant.id_postulacion = @id
    `);
  return res.recordset[0] || null;
}
 
async function pendientes() {
  const pool = await getPool();
  const res  = await pool.request().query(`
    SELECT ant.id_anteproyecto, ant.titulo, ant.estado, ant.fecha_envio,
           u.nombre AS alumno, al.matricula,
           p.nombre AS proyecto, e.nombre AS empresa
    FROM   anteproyectos ant
    JOIN   postulaciones po ON po.id_postulacion = ant.id_postulacion
    JOIN   alumnos       al ON al.id_alumno      = po.id_alumno
    JOIN   usuarios      u  ON u.id_usuario      = al.id_alumno
    JOIN   proyectos     p  ON p.id_proyecto     = po.id_proyecto
    JOIN   empresas      e  ON e.id_empresa      = p.id_empresa
    WHERE  ant.estado = 'pendiente'
    ORDER BY ant.fecha_envio
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
      SET estado = @estado, comentario_admin = @comentario, fecha_revision = GETDATE()
      WHERE id_anteproyecto = @id
    `);
}
 
module.exports = { crear, buscarPorPostulacion, pendientes, actualizar };
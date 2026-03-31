const { getPool, sql } = require('../config/db');
 
async function listar({ estado, area } = {}) {
  const pool = await getPool();
  const req  = pool.request();
  const conds = ["p.estado != 'despublicado'"];
  if (estado) { req.input('estado', sql.NVarChar, estado); conds.push("p.estado = @estado"); }
  if (area)   { req.input('area',   sql.NVarChar, `%${area}%`); conds.push("p.area LIKE @area"); }
 
  const res = await req.query(`
    SELECT p.id_proyecto, p.nombre, p.descripcion, p.area, p.modalidad,
           p.num_alumnos, p.estado, p.fecha_creacion,
           e.nombre AS empresa, e.correo_empresa,
           ISNULL(u.nombre, NULL) AS asesor,
           (SELECT COUNT(*) FROM postulaciones po
            WHERE po.id_proyecto = p.id_proyecto
              AND po.estado = 'aceptada') AS alumnos_aceptados
    FROM   proyectos p
    JOIN   empresas  e   ON e.id_empresa = p.id_empresa
    LEFT JOIN asesores  a   ON a.id_asesor  = p.id_asesor
    LEFT JOIN usuarios  u   ON u.id_usuario = a.id_asesor
    WHERE  ${conds.join(' AND ')}
    ORDER BY p.fecha_creacion DESC
  `);
  return res.recordset;
}
 
async function buscarPorId(id) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, id)
    .query(`
      SELECT p.*, e.nombre AS empresa, e.correo_empresa,
             e.nombre_responsable, e.correo_responsable,
             ISNULL(u.nombre, NULL) AS asesor
      FROM   proyectos p
      JOIN   empresas  e   ON e.id_empresa = p.id_empresa
      LEFT JOIN asesores  a   ON a.id_asesor  = p.id_asesor
      LEFT JOIN usuarios  u   ON u.id_usuario = a.id_asesor
      WHERE  p.id_proyecto = @id
    `);
  return res.recordset[0] || null;
}
 
async function actualizarEstado(id, estado) {
  const pool = await getPool();
  await pool.request()
    .input('id',     sql.Int,      id)
    .input('estado', sql.NVarChar, estado)
    .query('UPDATE proyectos SET estado = @estado WHERE id_proyecto = @id');
}
 
async function asignarAsesor(idProyecto, idAsesor) {
  const pool = await getPool();
  await pool.request()
    .input('id',       sql.Int, idProyecto)
    .input('idAsesor', sql.Int, idAsesor)
    .query('UPDATE proyectos SET id_asesor = @idAsesor WHERE id_proyecto = @id');
}
 
module.exports = { listar, buscarPorId, actualizarEstado, asignarAsesor };
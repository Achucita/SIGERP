const { getPool, sql } = require('../config/db');
 
async function crear({ idUsuario, tipo, mensaje }) {
  const pool = await getPool();
  await pool.request()
    .input('usuario', sql.Int,      idUsuario)
    .input('tipo',    sql.NVarChar, tipo)
    .input('mensaje', sql.NVarChar, mensaje)
    .query('INSERT INTO notificaciones (id_usuario, tipo, mensaje) VALUES (@usuario, @tipo, @mensaje)');
}
 
async function porUsuario(idUsuario) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idUsuario)
    .query(`
      SELECT id_notificacion, tipo, mensaje, leida, fecha
      FROM   notificaciones
      WHERE  id_usuario = @id
      ORDER BY fecha DESC
    `);
  return res.recordset;
}
 
async function marcarLeida(id) {
  const pool = await getPool();
  await pool.request()
    .input('id', sql.Int, id)
    .query('UPDATE notificaciones SET leida = 1 WHERE id_notificacion = @id');
}
 
module.exports = { crear, porUsuario, marcarLeida };
const { getPool, sql } = require('../config/db');
 
async function buscarPorCorreo(correo) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('correo', sql.NVarChar, correo)
    .query(`
      SELECT u.id_usuario, u.nombre, u.correo, u.contrasena, u.rol,
             a.matricula, a.carrera,
             ase.area
      FROM   usuarios u
      LEFT JOIN alumnos        a   ON a.id_alumno  = u.id_usuario
      LEFT JOIN asesores       ase ON ase.id_asesor = u.id_usuario
      WHERE  u.correo = @correo AND u.activo = 1
    `);
  return res.recordset[0] || null;
}
 
async function buscarPorId(id) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, id)
    .query(`
      SELECT u.id_usuario, u.nombre, u.correo, u.rol, u.fecha_registro,
             a.matricula, a.carrera,
             ase.area
      FROM   usuarios u
      LEFT JOIN alumnos        a   ON a.id_alumno  = u.id_usuario
      LEFT JOIN asesores       ase ON ase.id_asesor = u.id_usuario
      WHERE  u.id_usuario = @id AND u.activo = 1
    `);
  return res.recordset[0] || null;
}
 
async function correoExiste(correo) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('correo', sql.NVarChar, correo)
    .query('SELECT 1 AS existe FROM usuarios WHERE correo = @correo');
  return res.recordset.length > 0;
}
 
async function crearUsuario({ nombre, correo, contrasenaHash, rol }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('nombre',    sql.NVarChar, nombre)
    .input('correo',    sql.NVarChar, correo)
    .input('contrasena', sql.NVarChar, contrasenaHash)
    .input('rol',       sql.NVarChar, rol)
    .query(`
      INSERT INTO usuarios (nombre, correo, contrasena, rol)
      OUTPUT INSERTED.id_usuario
      VALUES (@nombre, @correo, @contrasena, @rol)
    `);
  return res.recordset[0].id_usuario;
}
 
async function crearAlumno({ id, matricula, carrera }) {
  const pool = await getPool();
  await pool.request()
    .input('id',       sql.Int,      id)
    .input('matricula', sql.NVarChar, matricula)
    .input('carrera',  sql.NVarChar, carrera)
    .query('INSERT INTO alumnos (id_alumno, matricula, carrera) VALUES (@id, @matricula, @carrera)');
}
 
async function matriculaExiste(matricula) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('matricula', sql.NVarChar, matricula)
    .query('SELECT 1 AS existe FROM alumnos WHERE matricula = @matricula');
  return res.recordset.length > 0;
}
 
async function actualizarPerfil({ id, nombre, correo }) {
  const pool = await getPool();
  await pool.request()
    .input('id',     sql.Int,      id)
    .input('nombre', sql.NVarChar, nombre)
    .input('correo', sql.NVarChar, correo)
    .query('UPDATE usuarios SET nombre = @nombre, correo = @correo WHERE id_usuario = @id');
}
 
async function listarUsuarios({ rol } = {}) {
  const pool = await getPool();
  const req  = pool.request();
  let   where = 'WHERE u.activo = 1';
  if (rol) {
    req.input('rol', sql.NVarChar, rol);
    where += ' AND u.rol = @rol';
  }
  const res = await req.query(`
    SELECT u.id_usuario, u.nombre, u.correo, u.rol, u.fecha_registro,
           a.matricula, a.carrera, ase.area
    FROM   usuarios u
    LEFT JOIN alumnos  a   ON a.id_alumno  = u.id_usuario
    LEFT JOIN asesores ase ON ase.id_asesor = u.id_usuario
    ${where}
    ORDER BY u.rol, u.nombre
  `);
  return res.recordset;
}
 
async function darDeBaja(id) {
  const pool = await getPool();
  await pool.request()
    .input('id', sql.Int, id)
    .query('UPDATE usuarios SET activo = 0 WHERE id_usuario = @id');
}

async function actualizarContrasena(id, hash) {
  const pool = await getPool();
  await pool.request()
    .input('id',   sql.Int,      id)
    .input('hash', sql.NVarChar, hash)
    .query('UPDATE usuarios SET contrasena = @hash WHERE id_usuario = @id');
}
 
module.exports = {
  buscarPorCorreo, buscarPorId, correoExiste, crearUsuario,
  crearAlumno, matriculaExiste, actualizarPerfil, listarUsuarios, darDeBaja,
  darDeBaja, actualizarContrasena, 
};
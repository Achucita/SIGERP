// src/models/reporte.model.js
const { getPool, sql } = require('../config/db');

// ── Crear reporte formal ──────────────────────────────────────
async function crear({ idAlumno, numeroReporte, periodoCubre, rutaArchivo, comentariosAdicionales }) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('alumno',      sql.Int,      idAlumno)
    .input('numero',      sql.Int,      numeroReporte)
    .input('periodo',     sql.NVarChar, periodoCubre)
    .input('ruta',        sql.NVarChar, rutaArchivo)
    .input('comentarios', sql.NVarChar, comentariosAdicionales || null)
    .query(`
      INSERT INTO reportes (id_alumno, numero_reporte, periodo_cubre, ruta_archivo, comentarios_adicionales)
      OUTPUT INSERTED.id_reporte
      VALUES (@alumno, @numero, @periodo, @ruta, @comentarios)
    `);
  return res.recordset[0].id_reporte;
}

// ── Reportes del alumno ───────────────────────────────────────
async function porAlumno(idAlumno) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('id', sql.Int, idAlumno)
    .query(`
      SELECT id_reporte, numero_reporte, periodo_cubre,
             ruta_archivo, comentarios_adicionales,
             estado, fecha_envio, fecha_revision
      FROM   reportes
      WHERE  id_alumno = @id
      ORDER BY numero_reporte ASC
    `);
  return res.recordset;
}

// ── Todos los reportes (admin) ────────────────────────────────
async function listar({ idAlumno, estado } = {}) {
  const pool  = await getPool();
  const req   = pool.request();
  const conds = [];
  if (idAlumno) { req.input('alumno', sql.Int,      idAlumno); conds.push('r.id_alumno = @alumno'); }
  if (estado)   { req.input('estado', sql.NVarChar, estado);   conds.push('r.estado = @estado'); }
  const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
  const res   = await req.query(`
    SELECT r.id_reporte, r.numero_reporte, r.periodo_cubre,
           r.ruta_archivo, r.estado, r.fecha_envio, r.fecha_revision,
           r.comentarios_adicionales,
           u.nombre AS alumno, al.matricula, al.carrera
    FROM   reportes r
    JOIN   alumnos  al ON al.id_alumno = r.id_alumno
    JOIN   usuarios u  ON u.id_usuario = al.id_alumno
    ${where}
    ORDER BY r.fecha_envio DESC
  `);
  return res.recordset;
}

// ── Revisar reporte (admin) ───────────────────────────────────
async function actualizarEstado(id, { estado, comentario }) {
  const pool = await getPool();
  await pool.request()
    .input('id',         sql.Int,      id)
    .input('estado',     sql.NVarChar, estado)
    .input('comentario', sql.NVarChar, comentario || null)
    .query(`
      UPDATE reportes
      SET estado = @estado, comentario_admin = @comentario, fecha_revision = GETDATE()
      WHERE id_reporte = @id
    `);
}

// ── Periodos con fechas de desbloqueo ─────────────────────────
async function periodoHabilitado(numeroReporte) {
  const pool = await getPool();
  const res  = await pool.request()
    .input('numero', sql.Int, numeroReporte)
    .query(`
      SELECT 1 FROM periodos_reporte
      WHERE  numero_reporte = @numero
        AND  fecha_apertura IS NOT NULL
        AND  fecha_apertura <= GETDATE()
        AND  (fecha_cierre IS NULL OR fecha_cierre >= GETDATE())
    `);
  return res.recordset.length > 0;
}

async function listarPeriodos() {
  const pool = await getPool();

  // Garantizar que los 3 registros siempre existan en la tabla
  await pool.request().query(`
    MERGE periodos_reporte AS target
    USING (VALUES (1,'Primer Reporte'), (2,'Segundo Reporte'), (3,'Tercer Reporte'))
          AS src(numero_reporte, nombre)
      ON  target.numero_reporte = src.numero_reporte
    WHEN NOT MATCHED THEN
      INSERT (numero_reporte, nombre, fecha_apertura, fecha_cierre)
      VALUES (src.numero_reporte, src.nombre, NULL, NULL);
  `);

  const res = await pool.request().query(`
    SELECT numero_reporte, nombre, fecha_apertura, fecha_cierre,
      CASE
        WHEN fecha_apertura IS NULL             THEN 'no_habilitado'
        WHEN fecha_apertura > GETDATE()         THEN 'proximo'
        WHEN fecha_cierre IS NOT NULL
         AND fecha_cierre < GETDATE()           THEN 'cerrado'
        ELSE 'abierto'
      END AS estado_periodo
    FROM periodos_reporte
    ORDER BY numero_reporte ASC
  `);
  return res.recordset;
}

async function actualizarPeriodo({ numeroReporte, nombre, fechaApertura, fechaCierre }) {
  const pool = await getPool();
  await pool.request()
    .input('numero',   sql.Int,      numeroReporte)
    .input('nombre',   sql.NVarChar, nombre)
    .input('apertura', sql.DateTime, fechaApertura ? new Date(fechaApertura) : null)
    .input('cierre',   sql.DateTime, fechaCierre   ? new Date(fechaCierre)   : null)
    .query(`
      MERGE periodos_reporte AS target
      USING (SELECT @numero AS numero_reporte) AS source
        ON  target.numero_reporte = source.numero_reporte
      WHEN MATCHED THEN
        UPDATE SET nombre = @nombre, fecha_apertura = @apertura, fecha_cierre = @cierre
      WHEN NOT MATCHED THEN
        INSERT (numero_reporte, nombre, fecha_apertura, fecha_cierre)
        VALUES (@numero, @nombre, @apertura, @cierre);
    `);
}

module.exports = {
  crear, porAlumno, listar, actualizarEstado,
  periodoHabilitado, listarPeriodos, actualizarPeriodo,
};
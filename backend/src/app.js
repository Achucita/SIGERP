// src/app.js
const express = require('express');
const cors    = require('cors');
const path    = require('path');
require('./config/env');
const { getPool, sql } = require('./config/db');

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── Archivos subidos — protegidos por JWT ────────────────────
// El token llega como header Authorization: Bearer <token>
// URL: GET http://localhost:3000/uploads/anteproyectos/archivo.pdf
app.use('/uploads',
  require('./middlewares/auth'),
  express.static(path.join(__dirname, '..', 'uploads'))
);

app.get('/health', (req, res) =>
  res.json({ ok: true, message: 'SIGERP API funcionando.', env: process.env.NODE_ENV })
);

// ── Rutas ────────────────────────────────────────────────────
app.use('/api/usuarios',       require('./routes/usuario.routes'));
app.use('/api/proyectos',      require('./routes/proyecto.routes'));
app.use('/api/postulaciones',  require('./routes/postulacion.routes'));
app.use('/api/anteproyectos',  require('./routes/anteproyecto.routes'));
app.use('/api/reportes',       require('./routes/reporte.routes'));
app.use('/api/evidencias',     require('./routes/evidencia.routes'));
app.use('/api/documentos',     require('./routes/documento.routes'));
app.use('/api/expedientes',    require('./routes/expediente.routes'));
app.use('/api/evaluaciones',   require('./routes/evaluacion.routes'));
app.use('/api/notificaciones', require('./routes/notificacion.routes'));
app.use('/api/empresas',       require('./routes/empresa.routes'));

app.use((req, res) =>
  res.status(404).json({ ok: false, message: `Ruta no encontrada: ${req.method} ${req.path}` })
);
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ ok: false, message: 'Error interno del servidor.' });
});

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    console.log('Verificando conexion a SQL Server...');
    const pool   = await getPool();
    const result = await pool.request().query('SELECT DB_NAME() as db_name');
    console.log('Conexion establecida —', result.recordset[0].db_name);
    app.listen(PORT, () => {
      console.log(`SIGERP API corriendo en http://localhost:${PORT}`);
      console.log(`   Entorno: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error('Error critico:', error.message);
    process.exit(1);
  }
}

startServer();

process.on('SIGINT', async () => {
  console.log('\nCerrando...');
  await sql.close().catch(() => {});
  process.exit(0);
});

module.exports = app;
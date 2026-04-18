const express = require('express');
const cors    = require('cors');
require('./config/env');     // valida variables de entorno al arrancar
const { getPool, sql } = require('./config/db');  // ← Importa la conexión

const app = express();

// ── Middlewares globales ─────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── Ruta de salud (health check) ────────────────────────────
app.get('/health', (req, res) =>
  res.json({ ok: true, message: 'SIGERP API funcionando.', env: process.env.NODE_ENV })
);

// ── Rutas de la API ──────────────────────────────────────────
app.use('/api/usuarios',       require('./routes/usuario.routes'));
app.use('/api/proyectos',      require('./routes/proyecto.routes'));
app.use('/api/postulaciones',  require('./routes/postulacion.routes'));
app.use('/api/anteproyectos',  require('./routes/anteproyecto.routes'));
app.use('/api/reportes',       require('./routes/reporte.routes'));
app.use('/api/evaluaciones',   require('./routes/evaluacion.routes'));
app.use('/api/notificaciones', require('./routes/notificacion.routes'));

// ── Ruta no encontrada ───────────────────────────────────────
app.use((req, res) =>
  res.status(404).json({ ok: false, message: `Ruta no encontrada: ${req.method} ${req.path}` })
);

// ── Manejador global de errores ──────────────────────────────
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ ok: false, message: 'Error interno del servidor.' });
});

// ── Función para iniciar servidor con conexión a BD ──────────
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // Intentar conectar a la base de datos
    console.log('🔌 Verificando conexión a SQL Server...');
    const pool = await getPool();
    
    // Probar la conexión con una consulta simple
    const result = await pool.request().query('SELECT DB_NAME() as db_name, @@VERSION as version');
    console.log('✅ Conexión a base de datos establecida');
    console.log(`   Base de datos: ${result.recordset[0].db_name}`);
    
    // Iniciar servidor solo si la BD conecta
    app.listen(PORT, () => {
      console.log(`🚀 SIGERP API corriendo en http://localhost:${PORT}`);
      console.log(`   Entorno: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error('❌ Error crítico: No se pudo conectar a la base de datos');
    console.error(`   Detalle: ${error.message}`);
    process.exit(1); // Termina el proceso si no hay BD
  }
}

// Iniciar la aplicación
startServer();

// ── Manejar cierre graceful ──────────────────────────────────
process.on('SIGINT', async () => {
  console.log('\n👋 Cerrando conexiones...');
  if (sql) {
    await sql.close();
  }
  process.exit(0);
});

module.exports = app;  // exportar para tests
const express = require('express');
const cors    = require('cors');
require('./config/env');     // valida variables de entorno al arrancar
 
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
 
// ── Iniciar servidor ─────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 SIGERP API corriendo en http://localhost:${PORT}`);
  console.log(`   Entorno: ${process.env.NODE_ENV}`);
});
 
module.exports = app;  // exportar para tests
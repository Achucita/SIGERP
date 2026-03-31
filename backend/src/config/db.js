const sql  = require('mssql');
const env  = require('./env');
 
const config = {
  server:   env.db.server,
  port:     env.db.port,
  database: env.db.database,
  user:     env.db.user,
  password: env.db.password,
  options: {
    encrypt:              false,  // true si usas Azure
    trustServerCertificate: true, // necesario en desarrollo local
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};
 
// Singleton del pool
let pool = null;
 
async function getPool() {
  if (!pool) {
    pool = await sql.connect(config);
    console.log('✅ Conexión a SQL Server establecida.');
  }
  return pool;
}
 
module.exports = { getPool, sql };
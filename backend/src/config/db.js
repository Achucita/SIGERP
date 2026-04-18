// src/config/db.js
const sql = require('mssql');
require('./env');

const config = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT || '1433'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: false,
    trustServerCertificate: true,
    // Quita trustedConnection
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

let pool = null;

async function getPool() {
  if (!pool) {
    try {
      pool = await sql.connect(config);
      console.log('✅ Conexión a SQL Server establecida (SQL Auth).');
    } catch (error) {
      console.error('❌ Error de conexión:', error);
      throw error;
    }
  }
  return pool;
}

module.exports = { getPool, sql };
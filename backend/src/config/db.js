// src/config/db.js
const mysql = require('mysql2/promise');
require('./env');

const pool = mysql.createPool({
  host: process.env.DB_SERVER || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

async function getPool() {
  return pool;
}

module.exports = { getPool };
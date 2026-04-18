// src/config/env.js
require('dotenv').config();

// Con Windows Auth no se necesitan DB_USER ni DB_PASSWORD
const required = [
  'DB_SERVER',
  'DB_NAME',
  'JWT_SECRET',
  'SMTP_HOST',
  'SMTP_USER',
  'SMTP_PASS',
];

required.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Variable de entorno faltante: ${key}`);
  }
});

module.exports = {
  db: {
    server:   process.env.DB_SERVER,
    port:     parseInt(process.env.DB_PORT || '1433'),
    database: process.env.DB_NAME,
  },
  jwt: {
    secret:    process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '8h',
  },
  smtp: {
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587'),
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
    from: process.env.SMTP_FROM || 'noreply@sigerp.itl.edu.mx',
  },
  port: parseInt(process.env.PORT || '3000'),
  nodeEnv: process.env.NODE_ENV || 'development',
};
require('dotenv').config();
 
const required = [
  'DB_SERVER', 'DB_NAME', 'DB_USER', 'DB_PASSWORD',
  'JWT_SECRET', 'SMTP_HOST', 'SMTP_USER', 'SMTP_PASS',
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
    user:     process.env.DB_USER,
    password: process.env.DB_PASSWORD,
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
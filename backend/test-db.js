// test-final.js
const sql = require('mssql');
require('dotenv').config();

const config = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT || '1433'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
};

async function testConnection() {
  console.log('🔍 Probando conexión a SQL Server...');
  console.log(`   Servidor: ${config.server}`);
  console.log(`   Base de datos: ${config.database}`);
  console.log(`   Usuario: ${config.user}`);
  
  try {
    const pool = await sql.connect(config);
    console.log('✅ Conexión exitosa a la base de datos');
    
    const result = await pool.request().query('SELECT @@VERSION as version, DB_NAME() as db_name');
    console.log(`📊 Versión SQL Server: ${result.recordset[0].version.substring(0, 50)}...`);
    console.log(`🗄️  Base de datos actual: ${result.recordset[0].db_name}`);
    
    await sql.close();
    console.log('✅ Prueba completada con éxito');
  } catch (err) {
    console.error('❌ Error de conexión:', err.message);
    if (err.originalError) {
      console.error('   Detalle:', err.originalError.message);
    }
  }
}

testConnection();
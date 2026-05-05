// src/routes/empresa.routes.js
const router = require('express').Router();
const { getPool, sql } = require('../config/db');
const { created, serverError, badRequest } = require('../utils/response');

// POST /api/empresas/registro — público, sin autenticación
router.post('/registro', async (req, res) => {
  try {
    const {
      nombre, giro, direccion, telefono, correoEmpresa, paginaWeb,
      nombreResponsable, cargoResponsable, telefonoResponsable, correoResponsable,
      nombreProyecto, descripcion, area, requisitos, modalidad, numAlumnos,
    } = req.body;

    if (!nombre || !correoEmpresa || !nombreResponsable ||
        !correoResponsable || !nombreProyecto || !descripcion || !modalidad)
      return badRequest(res, 'Faltan campos obligatorios.');

    const pool = await getPool();

    // 1. Insertar empresa
    const empRes = await pool.request()
      .input('nombre',              sql.NVarChar, nombre)
      .input('giro',                sql.NVarChar, giro || null)
      .input('direccion',           sql.NVarChar, direccion || null)
      .input('telefono',            sql.NVarChar, telefono || null)
      .input('correoEmpresa',       sql.NVarChar, correoEmpresa)
      .input('paginaWeb',           sql.NVarChar, paginaWeb || null)
      .input('nombreResponsable',   sql.NVarChar, nombreResponsable)
      .input('cargoResponsable',    sql.NVarChar, cargoResponsable || null)
      .input('telefonoResponsable', sql.NVarChar, telefonoResponsable || null)
      .input('correoResponsable',   sql.NVarChar, correoResponsable)
      .query(`
        INSERT INTO empresas
          (nombre, giro, direccion, telefono, correo_empresa, pagina_web,
           nombre_responsable, cargo_responsable, telefono_responsable, correo_responsable)
        OUTPUT INSERTED.id_empresa
        VALUES
          (@nombre, @giro, @direccion, @telefono, @correoEmpresa, @paginaWeb,
           @nombreResponsable, @cargoResponsable, @telefonoResponsable, @correoResponsable)
      `);

    const idEmpresa = empRes.recordset[0].id_empresa;

    // 2. Insertar proyecto con estado 'revision'
    await pool.request()
      .input('idEmpresa',   sql.Int,      idEmpresa)
      .input('nombre',      sql.NVarChar, nombreProyecto)
      .input('descripcion', sql.NVarChar, descripcion)
      .input('area',        sql.NVarChar, area || null)
      .input('requisitos',  sql.NVarChar, requisitos || null)
      .input('modalidad',   sql.NVarChar, modalidad)
      .input('numAlumnos',  sql.Int,      parseInt(numAlumnos) || 1)
      .query(`
        INSERT INTO proyectos
          (id_empresa, nombre, descripcion, area, requisitos, modalidad, num_alumnos, estado)
        VALUES
          (@idEmpresa, @nombre, @descripcion, @area, @requisitos, @modalidad, @numAlumnos, 'revision')
      `);

    return created(res, { idEmpresa },
      'Proyecto registrado correctamente. El equipo del ITL lo revisará pronto.');
  } catch (err) {
    return serverError(res, err);
  }
});

module.exports = router;
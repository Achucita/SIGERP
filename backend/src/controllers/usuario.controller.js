const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const env     = require('../config/env');
const Model   = require('../models/usuario.model');
const { ok, created, badRequest, conflict, notFound, serverError } = require('../utils/response');
 
async function registro(req, res) {
  try {
    const { nombre, correo, contrasena, matricula, carrera } = req.body;
    if (!nombre || !correo || !contrasena || !matricula || !carrera)
      return badRequest(res, 'Faltan campos obligatorios: nombre, correo, contrasena, matricula, carrera.');
 
    if (await Model.correoExiste(correo))
      return conflict(res, 'El correo ya está registrado.');
    if (await Model.matriculaExiste(matricula))
      return conflict(res, 'La matrícula ya está registrada.');
 
    const hash = await bcrypt.hash(contrasena, 10);
    const id   = await Model.crearUsuario({ nombre, correo, contrasenaHash: hash, rol: 'alumno' });
    await Model.crearAlumno({ id, matricula, carrera });
 
    return created(res, { id }, 'Cuenta creada correctamente.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function login(req, res) {
  try {
    const { correo, contrasena } = req.body;
    if (!correo || !contrasena)
      return badRequest(res, 'Correo y contraseña son requeridos.');
 
    const usuario = await Model.buscarPorCorreo(correo);
    if (!usuario)
      return badRequest(res, 'Credenciales incorrectas.');
 
    const valida = await bcrypt.compare(contrasena, usuario.contrasena);
    if (!valida)
      return badRequest(res, 'Credenciales incorrectas.');
 
    const payload = { id: usuario.id_usuario, rol: usuario.rol, nombre: usuario.nombre };
    const token   = jwt.sign(payload, env.jwt.secret, { expiresIn: env.jwt.expiresIn });
 
    return ok(res, {
      token,
      usuario: { id: usuario.id_usuario, nombre: usuario.nombre, correo: usuario.correo, rol: usuario.rol },
    }, 'Sesión iniciada.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function perfil(req, res) {
  try {
    const usuario = await Model.buscarPorId(req.usuario.id);
    if (!usuario) return notFound(res, 'Usuario no encontrado.');
    return ok(res, usuario);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function actualizar(req, res) {
  try {
    const { nombre, correo } = req.body;
    const id = parseInt(req.params.id);
    // solo el propio usuario o un admin puede actualizar
    if (req.usuario.id !== id && req.usuario.rol !== 'admin')
      return badRequest(res, 'Solo puedes editar tu propio perfil.');
    await Model.actualizarPerfil({ id, nombre, correo });
    return ok(res, {}, 'Perfil actualizado.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function listar(req, res) {
  try {
    const usuarios = await Model.listarUsuarios({ rol: req.query.rol });
    return ok(res, usuarios);
  } catch (err) {
    return serverError(res, err);
  }
}
 
async function baja(req, res) {
  try {
    await Model.darDeBaja(parseInt(req.params.id));
    return ok(res, {}, 'Usuario dado de baja.');
  } catch (err) {
    return serverError(res, err);
  }
}

async function cambiarPassword(req, res) {
  try {
    const id = parseInt(req.params.id);
    if (req.usuario.id !== id)
      return forbidden(res, 'No puedes cambiar la contraseña de otro usuario.');

    const { contrasenaActual, contrasenaNueva } = req.body;
    if (!contrasenaActual || !contrasenaNueva)
      return badRequest(res, 'Se requieren contrasenaActual y contrasenaNueva.');

    const usuario = await Model.buscarPorId(id);
    if (!usuario) return notFound(res, 'Usuario no encontrado.');

    // Verificar contraseña actual
    const usuarioConHash = await Model.buscarPorCorreo(usuario.correo);
    const valida = await bcrypt.compare(contrasenaActual, usuarioConHash.contrasena);
    if (!valida) return badRequest(res, 'La contraseña actual es incorrecta.');

    const hash = await bcrypt.hash(contrasenaNueva, 10);
    await Model.actualizarContrasena(id, hash);
    return ok(res, {}, 'Contraseña actualizada.');
  } catch (err) {
    return serverError(res, err);
  }
}
 
module.exports = { registro, login, perfil, actualizar, listar, baja, cambiarPassword };
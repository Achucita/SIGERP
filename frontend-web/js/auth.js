// frontend-web/js/auth.js
// Manejo de sesión: guardar/leer/borrar token, checkAuth, logout

const AUTH_KEY = 'sigerp_token';
const USER_KEY = 'sigerp_user';

/**
 * Guarda el token y datos del usuario en localStorage.
 */
function guardarSesion(token, usuario) {
  localStorage.setItem(AUTH_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(usuario));
}

/**
 * Obtiene el token JWT guardado.
 */
function getToken() {
  return localStorage.getItem(AUTH_KEY);
}

/**
 * Obtiene los datos del usuario actual.
 * @returns {{ id, nombre, correo, rol } | null}
 */
function getUsuario() {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try { return JSON.parse(raw); }
  catch { return null; }
}

/**
 * Cierra la sesión: limpia localStorage y redirige al login.
 */
function logout() {
  localStorage.removeItem(AUTH_KEY);
  localStorage.removeItem(USER_KEY);
  window.location.href = '/pages/login.html';
}

/**
 * Verifica que haya sesión activa.
 * Si no hay token → redirige al login.
 * Si se pasan roles → verifica que el usuario tenga uno de esos roles.
 * @param {string[]} rolesPermitidos - ej: ['admin'] o ['admin','asesor']
 */
function checkAuth(rolesPermitidos = []) {
  const token   = getToken();
  const usuario = getUsuario();

  if (!token || !usuario) {
    window.location.href = '/pages/login.html';
    return null;
  }

  if (rolesPermitidos.length > 0 && !rolesPermitidos.includes(usuario.rol)) {
    // Redirigir al dashboard correcto según su rol real
    redirigirPorRol(usuario.rol);
    return null;
  }

  return usuario;
}

/**
 * Redirige al dashboard según el rol del usuario.
 */
function redirigirPorRol(rol) {
  const rutas = {
    admin:  '/pages/dashboard-admin.html',
    asesor: '/pages/dashboard-asesor.html',
    alumno: '/pages/dashboard-alumno.html',
  };
  window.location.href = rutas[rol] || '/pages/login.html';
}

/**
 * Iniciales del nombre (para el avatar).
 * "Jacziry Berenice Aragón" → "JB"
 */
function iniciales(nombre = '') {
  return nombre
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map(p => p[0].toUpperCase())
    .join('');
}
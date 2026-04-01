// frontend-web/js/api/client.js
// Cliente base para todas las llamadas al backend.
// Lee el JWT de localStorage y lo adjunta automáticamente.

const API_BASE = 'http://localhost:3000/api';  // ← cambiar si el backend está en otro puerto

/**
 * Fetch con JWT automático y manejo de errores centralizado.
 * @param {string} endpoint  - ej: '/usuarios' o '/proyectos/1'
 * @param {object} options   - opciones fetch (method, body, etc.)
 * @returns {Promise<any>}   - data del response (campo "data" del JSON)
 * @throws {Error}           - con el mensaje del backend si hay error
 */
async function apiFetch(endpoint, options = {}) {
  const token = localStorage.getItem('sigerp_token');

  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers || {}),
  };

  // Si el body es FormData no ponemos Content-Type (el browser lo pone solo)
  if (options.body instanceof FormData) {
    delete headers['Content-Type'];
  }

  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  });

  const json = await response.json().catch(() => ({}));

  if (!response.ok) {
    const msg = json.message || `Error ${response.status}`;
    throw new Error(msg);
  }

  return json.data ?? json;
}

// ── Métodos de conveniencia ────────────────────────────────────
const api = {
  get:    (url)          => apiFetch(url, { method: 'GET' }),
  post:   (url, body)    => apiFetch(url, { method: 'POST',   body: JSON.stringify(body) }),
  put:    (url, body)    => apiFetch(url, { method: 'PUT',    body: JSON.stringify(body) }),
  delete: (url)          => apiFetch(url, { method: 'DELETE' }),
  upload: (url, formData) => apiFetch(url, { method: 'POST',  body: formData }),
};

// ── Módulo: Usuarios ───────────────────────────────────────────
const usuariosApi = {
  login:   (correo, contrasena)    => api.post('/usuarios/login', { correo, contrasena }),
  perfil:  ()                      => api.get('/usuarios/perfil'),
  listar:  (rol)                   => api.get(`/usuarios${rol ? `?rol=${rol}` : ''}`),
  baja:    (id)                    => api.delete(`/usuarios/${id}`),
  actualizar: (id, datos)          => api.put(`/usuarios/${id}`, datos),
};

// ── Módulo: Proyectos ──────────────────────────────────────────
const proyectosApi = {
  listar:        (params = {})        => {
    const q = new URLSearchParams(params).toString();
    return api.get(`/proyectos${q ? `?${q}` : ''}`);
  },
  detalle:       (id)                 => api.get(`/proyectos/${id}`),
  cambiarEstado: (id, estado)         => api.put(`/proyectos/${id}/estado`, { estado }),
  asignarAsesor: (id, idAsesor)       => api.put(`/proyectos/${id}/asesor`, { idAsesor }),
};

// ── Módulo: Postulaciones ──────────────────────────────────────
const postulacionesApi = {
  crear:           (idProyecto)       => api.post('/postulaciones', { idProyecto }),
  mis:             ()                 => api.get('/postulaciones/mis'),
  porProyecto:     (id)               => api.get(`/postulaciones/proyecto/${id}`),
  actualizarEstado:(id, estado)       => api.put(`/postulaciones/${id}/estado`, { estado }),
};

// ── Módulo: Anteproyectos ──────────────────────────────────────
const anteproyectosApi = {
  pendientes:      ()                 => api.get('/anteproyectos/pendientes'),
  ver:             (idPostulacion)    => api.get(`/anteproyectos/${idPostulacion}`),
  revisar:         (id, datos)        => api.put(`/anteproyectos/${id}/revisar`, datos),
  subir:           (formData)         => api.upload('/anteproyectos', formData),
};

// ── Módulo: Reportes ───────────────────────────────────────────
const reportesApi = {
  subir:       (formData)             => api.upload('/reportes', formData),
  mis:         ()                     => api.get('/reportes/mis'),
  porProyecto: (id)                   => api.get(`/reportes/proyecto/${id}`),
  comentar:    (id, datos)            => api.put(`/reportes/${id}/comentar`, datos),
};

// ── Módulo: Evaluaciones ───────────────────────────────────────
const evaluacionesApi = {
  crear:       (datos)                => api.post('/evaluaciones', datos),
  mis:         ()                     => api.get('/evaluaciones/mis'),
  porAlumno:   (id)                   => api.get(`/evaluaciones/alumno/${id}`),
};

// ── Módulo: Notificaciones ─────────────────────────────────────
const notificacionesApi = {
  mis:         ()                     => api.get('/notificaciones'),
  marcarLeida: (id)                   => api.put(`/notificaciones/${id}/leer`),
};
// frontend-web/js/api/client.js
const API_BASE = 'http://localhost:3000/api';

async function apiFetch(endpoint, options = {}) {
  const token = localStorage.getItem('sigerp_token');
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers || {}),
  };
  if (options.body instanceof FormData) delete headers['Content-Type'];
  const response = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
  const json = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(json.message || `Error ${response.status}`);
  return json.data ?? json;
}

const api = {
  get:    (url)        => apiFetch(url, { method: 'GET' }),
  post:   (url, body)  => apiFetch(url, { method: 'POST',   body: JSON.stringify(body) }),
  put:    (url, body)  => apiFetch(url, { method: 'PUT',    body: JSON.stringify(body) }),
  delete: (url)        => apiFetch(url, { method: 'DELETE' }),
  upload: (url, fd)    => apiFetch(url, { method: 'POST',   body: fd }),
};

const usuariosApi = {
  login:      (correo, contrasena) => api.post('/usuarios/login', { correo, contrasena }),
  perfil:     ()                   => api.get('/usuarios/perfil'),
  listar:     (rol)                => api.get(`/usuarios${rol ? `?rol=${rol}` : ''}`),
  baja:       (id)                 => api.delete(`/usuarios/${id}`),
  actualizar: (id, datos)          => api.put(`/usuarios/${id}`, datos),
};

const proyectosApi = {
  listar:        (params = {}) => { const q = new URLSearchParams(params).toString(); return api.get(`/proyectos${q ? `?${q}` : ''}`); },
  detalle:       (id)          => api.get(`/proyectos/${id}`),
  cambiarEstado: (id, estado)  => api.put(`/proyectos/${id}/estado`, { estado }),
  asignarAsesor: (id, idAsesor)=> api.put(`/proyectos/${id}/asesor`, { idAsesor }),
};

const postulacionesApi = {
  crear:            (idProyecto) => api.post('/postulaciones', { idProyecto }),
  mis:              ()           => api.get('/postulaciones/mis'),
  porProyecto:      (id)         => api.get(`/postulaciones/proyecto/${id}`),
  actualizarEstado: (id, estado) => api.put(`/postulaciones/${id}/estado`, { estado }),
};

const anteproyectosApi = {
  // Admin
  listar:        (estado)         => api.get(`/anteproyectos${estado ? `?estado=${estado}` : ''}`),
  pendientes:    ()               => api.get('/anteproyectos/pendientes'),
  ver:           (id)             => api.get(`/anteproyectos/${id}`),
  asignarAsesor: (id, idAsesor)   => api.put(`/anteproyectos/${id}/asignar-asesor`, { idAsesor }),
  // Asesor
  misAsignados:  ()               => api.get('/anteproyectos/mis-asignados'),
  revisar:       (id, datos)      => api.put(`/anteproyectos/${id}/revisar-asesor`, datos),
  // Alumno
  subir:         (formData)       => api.upload('/anteproyectos', formData),
  // Utilidad para construir la URL del PDF
  urlArchivo:    (ruta)           => `${API_BASE.replace('/api', '')}/${ruta.replace(/\\/g, '/')}`,

  // Abre un PDF en nueva pestaña enviando el JWT (window.open no manda headers)
  async abrirPDF(ruta) {
    const rutaLimpia = (ruta || '').replace(/\\/g, '/').replace(/^\/+/, '');
    const url   = API_BASE.replace('/api', '') + '/' + rutaLimpia;
    const token = localStorage.getItem('sigerp_token');
    try {
      const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
      if (!res.ok) throw new Error(`Error ${res.status}`);
      const blob    = await res.blob();
      const blobUrl = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href     = blobUrl;
      a.target   = '_blank';
      a.download = rutaLimpia.split('/').pop();
      a.style.display = 'none';
      document.body.appendChild(a);
      a.click();
      setTimeout(() => { document.body.removeChild(a); URL.revokeObjectURL(blobUrl); }, 5000);
    } catch (err) {
      alert('No se pudo abrir el PDF: ' + err.message);
    }
  },
};

const evidenciasApi = {
  // Alumno
  subir:     (formData)                    => api.upload('/evidencias', formData),
  mis:       ()                            => api.get('/evidencias/mis'),
  // Asesor
  porAsesor: ()                            => api.get('/evidencias/asesor'),
  comentar:  (id, comentario, idAlumno)    => api.put(`/evidencias/${id}/comentar`, { comentario, idAlumno }),
};

const reportesApi = {
  subir:      (formData)   => api.upload('/reportes', formData),
  mis:        ()           => api.get('/reportes/mis'),
  porProyecto:(id)         => api.get(`/reportes/proyecto/${id}`),
  porAlumno:  (idAlumno)   => api.get(`/reportes?idAlumno=${idAlumno}`),
  todos:      ()           => api.get('/reportes'),
  comentar:   (id, datos)  => api.put(`/reportes/${id}`, datos),
};

const evaluacionesApi = {
  crear:     (datos) => api.post('/evaluaciones', datos),
  todas:     ()      => api.get('/evaluaciones'),
  mis:       ()      => api.get('/evaluaciones/mis'),
  porAlumno: (id)    => api.get(`/evaluaciones/alumno/${id}`),
};

const expedienteApi = {
  listarAlumnos:      ()   => api.get('/expedientes'),
  expediente:         (id) => api.get(`/expedientes/${id}`),
};

const notificacionesApi = {
  mis:         ()   => api.get('/notificaciones'),
  marcarLeida: (id) => api.put(`/notificaciones/${id}/leer`),
};
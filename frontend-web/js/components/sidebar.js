// frontend-web/js/components/sidebar.js
// Renderiza el sidebar dinámicamente según el rol del usuario.
// Uso: llamar renderSidebar() al cargar cada página protegida.

function renderSidebar(paginaActiva = '') {
  const usuario = getUsuario();
  if (!usuario) return;

  const navAdmin = [
    { seccion: 'Principal', items: [
      { href: 'dashboard-admin.html', icon: '⊞', label: 'Dashboard' },
      { href: 'usuarios.html',        icon: '👥', label: 'Usuarios' },
      { href: 'proyectos.html',       icon: '📁', label: 'Proyectos' },
      { href: 'anteproyectos.html',   icon: '📝', label: 'Anteproyectos' },
      { href: 'postulaciones.html',   icon: '📋', label: 'Postulaciones' },
    ]},
    { seccion: 'Reportes', items: [
      { href: 'reportes-sistema.html', icon: '📊', label: 'Reportes del sistema' },
    ]},
  ];

  const navAsesor = [
    { seccion: 'Principal', items: [
      { href: 'dashboard-asesor.html', icon: '⊞', label: 'Dashboard' },
      { href: 'mis-alumnos.html',      icon: '👥', label: 'Mis alumnos' },
      { href: 'reportes-alumno.html',  icon: '📄', label: 'Reportes' },
      { href: 'evaluaciones.html',     icon: '⭐', label: 'Evaluaciones' },
    ]},
  ];

  const nav = usuario.rol === 'admin' ? navAdmin : navAsesor;

  const seccionesHTML = nav.map(({ seccion, items }) => `
    <div class="nav-section">
      <div class="nav-section-label">${seccion}</div>
      ${items.map(item => `
        <a href="${item.href}"
           class="nav-item ${paginaActiva === item.href ? 'active' : ''}">
          <span class="nav-icon">${item.icon}</span>
          ${item.label}
        </a>
      `).join('')}
    </div>
  `).join('');

  const html = `
    <div class="sidebar-logo">
      <div class="logo-badge">SIGERP</div>
      <h1>Residencias<br>Profesionales</h1>
      <p>Instituto Tecnológico de León</p>
    </div>
    ${seccionesHTML}
    <div class="sidebar-footer">
      <div class="user-pill">
        <div class="av">${iniciales(usuario.nombre)}</div>
        <div class="user-info">
          <div class="user-name">${usuario.nombre}</div>
          <div class="user-role">${usuario.rol === 'admin' ? 'Administrador' : 'Asesor Académico'}</div>
        </div>
      </div>
      <button class="logout-btn" onclick="logout()">
        <span>⎋</span> Cerrar sesión
      </button>
    </div>
  `;

  const sidebar = document.getElementById('sidebar');
  if (sidebar) sidebar.innerHTML = html;
}


// ─────────────────────────────────────────────────────────────
// frontend-web/js/components/toast.js
// Sistema de notificaciones flotantes.
// Uso: toast('Guardado correctamente')  /  toast('Error', 'error')

function toast(mensaje, tipo = 'success', duracion = 3500) {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    document.body.appendChild(container);
  }

  const iconos = { success: '✓', error: '✗', warn: '⚠' };
  const clases = { success: '', error: 'toast-error', warn: 'toast-warn' };

  const el = document.createElement('div');
  el.className = `toast ${clases[tipo] || ''}`;
  el.innerHTML = `<span>${iconos[tipo] || '✓'}</span><span>${mensaje}</span>`;
  container.appendChild(el);

  setTimeout(() => {
    el.style.opacity = '0';
    el.style.transform = 'translateX(20px)';
    el.style.transition = 'all .3s';
    setTimeout(() => el.remove(), 300);
  }, duracion);
}


// ─────────────────────────────────────────────────────────────
// Utilidades de UI compartidas

/** Abre un modal */
function openModal(id) {
  document.getElementById(id)?.classList.add('open');
}

/** Cierra un modal */
function closeModal(id) {
  document.getElementById(id)?.classList.remove('open');
}

/** Formatea una fecha ISO a "26/03/2026" */
function fmtFecha(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('es-MX', {
    day: '2-digit', month: '2-digit', year: 'numeric'
  });
}

/** Devuelve el HTML de un badge según el estado de postulación/proyecto */
function badgeEstado(estado) {
  const map = {
    pendiente:    '<span class="badge badge-amber">Pendiente</span>',
    aceptada:     '<span class="badge badge-green">Aceptada</span>',
    rechazada:    '<span class="badge badge-red">Rechazada</span>',
    publicado:    '<span class="badge badge-green">Publicado</span>',
    revision:     '<span class="badge badge-amber">En revisión</span>',
    cerrado:      '<span class="badge badge-gray">Cerrado</span>',
    despublicado: '<span class="badge badge-red">Despublicado</span>',
    aprobado:     '<span class="badge badge-green">Aprobado</span>',
    enviado:      '<span class="badge badge-blue">Enviado</span>',
    revisado:     '<span class="badge badge-green">Revisado</span>',
    con_observaciones: '<span class="badge badge-amber">Con observaciones</span>',
    parcial:      '<span class="badge badge-blue">Parcial</span>',
    final:        '<span class="badge badge-purple">Final</span>',
    alumno:       '<span class="badge badge-blue">Alumno</span>',
    asesor:       '<span class="badge badge-amber">Asesor</span>',
    admin:        '<span class="badge badge-purple">Admin</span>',
  };
  return map[estado] || `<span class="badge badge-gray">${estado}</span>`;
}

/** Muestra estado de carga en una tabla */
function tablaLoading(tbodyId, colspan = 6) {
  const tbody = document.getElementById(tbodyId);
  if (tbody) tbody.innerHTML = `
    <tr class="loading-row">
      <td colspan="${colspan}"><div class="spinner"></div></td>
    </tr>`;
}

/** Muestra estado vacío en una tabla */
function tablaEmpty(tbodyId, msg = 'Sin registros', colspan = 6) {
  const tbody = document.getElementById(tbodyId);
  if (tbody) tbody.innerHTML = `
    <tr>
      <td colspan="${colspan}" style="text-align:center;padding:40px;color:var(--muted)">
        ${msg}
      </td>
    </tr>`;
}
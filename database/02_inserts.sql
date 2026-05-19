-- ============================================================
--  SIGERP - Script 02 - Datos de prueba (MySQL)
--  Compatible con el esquema oficial (Script.sql exportado SSMS)
--  Contraseña de todos los usuarios: Test1234
-- ============================================================

USE sigerpdb;

-- ── Limpiar datos previos ────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE notificaciones;
TRUNCATE TABLE evaluaciones;
TRUNCATE TABLE documentos_alumno;
TRUNCATE TABLE evidencias;
TRUNCATE TABLE reportes;
TRUNCATE TABLE anteproyectos;
TRUNCATE TABLE postulaciones;
TRUNCATE TABLE proyectos;
TRUNCATE TABLE periodos_reporte;
TRUNCATE TABLE empresas;
TRUNCATE TABLE administradores;
TRUNCATE TABLE asesores;
TRUNCATE TABLE alumnos;
TRUNCATE TABLE usuarios;
SET FOREIGN_KEY_CHECKS = 1;

-- ── 1. Usuarios (contraseña: Test1234) ──────────────────────
INSERT INTO usuarios (nombre, correo, contrasena, rol) VALUES
('José Luis Suárez y Gómez',          'jlsuarez@itl.edu.mx',  '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('Eduardo Ramírez García',             'e.ramirez@itl.edu.mx', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'asesor'),
('Lucía Moreno Pérez',                 'l.moreno@itl.edu.mx',  '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'asesor'),
('Aragón Guerrero Jacziry Berenice',   'jacziry@itl.edu.mx',   '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'alumno'),
('Cortez Iñiguez Juan José',           'juanjose@itl.edu.mx',  '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'alumno'),
('Ramírez Torres Mario',               'm.ramirez@itl.edu.mx', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'alumno');

-- ── 2. Tablas extendidas ────────────────────────────────────
INSERT INTO administradores (id_admin) VALUES (1);

INSERT INTO asesores (id_asesor, area) VALUES
(2, 'Sistemas y Computación'),
(3, 'Tecnologías de la Información');

INSERT INTO alumnos (id_alumno, matricula, carrera) VALUES
(4, '21240179', 'Ingeniería en Sistemas Computacionales'),
(5, '21240173', 'Ingeniería en Sistemas Computacionales'),
(6, '21240101', 'Ingeniería en Inteligencia Artificial');

-- ── 3. Periodos de reporte ──────────────────────────────────
INSERT INTO periodos_reporte (numero_reporte, nombre, fecha_apertura, fecha_cierre) VALUES
(1, 'Reporte 1 — Primer mes',  '2026-03-01 00:00:00', '2026-03-31 23:59:59'),
(2, 'Reporte 2 — Segundo mes', '2026-04-01 00:00:00', '2026-04-30 23:59:59'),
(3, 'Reporte 3 — Tercer mes',  '2026-05-01 00:00:00', '2026-05-31 23:59:59');

-- ── 4. Empresas ─────────────────────────────────────────────
INSERT INTO empresas (nombre, giro, direccion, telefono, correo_empresa,
    pagina_web, nombre_responsable, cargo_responsable,
    telefono_responsable, correo_responsable)
VALUES
('Tech Bajío S.A. de C.V.', 'Desarrollo de software industrial',
 'Blvd. Aeropuerto 3302, León, Gto.', '(477) 710-0100',
 'contacto@techbajio.mx', 'www.techbajio.mx',
 'Juan López Ortega', 'Gerente de RRHH', '(477) 710-0101', 'rrhh@techbajio.mx'),
('Innovatech MX S.A.', 'Inteligencia Artificial y Automatización',
 'Av. Insurgentes 450, León, Gto.', '(477) 715-2200',
 'proyectos@innovatech.mx', 'www.innovatech.mx',
 'Sofía Medina Torres', 'Directora de TI', '(477) 715-2201', 'dev@innovatech.mx'),
('DataCore León', 'Análisis de datos y Business Intelligence',
 'Calle Tecnológico 105, León, Gto.', '(477) 720-3300',
 'info@datacore.mx', NULL,
 'Roberto Chávez Ruiz', 'Coordinador de Proyectos', '(477) 720-3301', 'projects@datacore.mx');

-- ── 5. Proyectos ────────────────────────────────────────────
INSERT INTO proyectos (id_empresa, id_asesor, nombre, descripcion, area,
    requisitos, modalidad, num_alumnos, estado, apoyo_economico, monto_apoyo)
VALUES
(1, NULL, 'App móvil IoT',
 'Desarrollo de aplicación para monitoreo de sensores industriales en tiempo real.',
 'Desarrollo de Software',
 'Carrera ISC o IA. Conocimientos en Flutter y Node.js. Disponibilidad 6 meses.',
 'presencial', 2, 'publicado', 'si', 3500.00),
(2, NULL, 'Chatbot IA para atención a clientes',
 'Creación de asistente virtual con NLP para atención al cliente.',
 'Inteligencia Artificial',
 'Carrera ISC o IA. Conocimientos en Python y NLP. Experiencia con APIs REST.',
 'hibrido', 2, 'publicado', 'no', NULL),
(3, NULL, 'Dashboard de análisis de datos logísticos',
 'Tablero de visualización e inteligencia de negocios para el área comercial.',
 'Análisis de Datos',
 'Carrera ISC. Conocimientos en Python, SQL y Power BI o similar.',
 'remoto', 3, 'revision', 'no', NULL);

-- ── 6. Postulaciones ────────────────────────────────────────
INSERT INTO postulaciones (id_alumno, id_proyecto, estado, correo_enviado, fecha_postulacion, observaciones, cv_ruta)
VALUES
(4, 1, 'aceptada',  1, DATE_SUB(NOW(), INTERVAL 10 DAY), NULL, 'uploads/cvs/cv_alumno_4.pdf'),
(5, 1, 'pendiente', 1, DATE_SUB(NOW(), INTERVAL  8 DAY), NULL, 'uploads/cvs/cv_alumno_5.pdf'),
(6, 2, 'pendiente', 1, DATE_SUB(NOW(), INTERVAL  5 DAY), NULL, NULL),
(4, 2, 'rechazada', 1, DATE_SUB(NOW(), INTERVAL 15 DAY), 'El alumno ya cuenta con proyecto asignado.', NULL);

-- ── 7. Anteproyecto ─────────────────────────────────────────
INSERT INTO anteproyectos (id_postulacion, titulo, descripcion,
    ruta_archivo, estado, comentario_admin, fecha_envio, fecha_revision,
    id_alumno, asesores_propuestos, id_asesor_asignado)
VALUES (
    1,
    'Sistema de monitoreo IoT para sensores industriales con Flutter',
    'Aplicación móvil en Flutter con datos MQTT de sensores en tiempo real, con alertas y almacenamiento histórico.',
    'uploads/anteproyectos/antep_postulacion_1.pdf',
    'asignado',
    'Anteproyecto bien estructurado. Se aprueba y se asigna asesor.',
    DATE_SUB(NOW(), INTERVAL 7 DAY),
    DATE_SUB(NOW(), INTERVAL 5 DAY),
    4,
    'Eduardo Ramírez García, Lucía Moreno Pérez',
    2
);

UPDATE proyectos SET id_asesor = 2 WHERE id_proyecto = 1;

-- ── 8. Reportes ─────────────────────────────────────────────
INSERT INTO reportes (id_alumno, id_proyecto, numero_reporte, titulo,
    descripcion, periodo_inicio, periodo_fin,
    ruta_archivo, estado, comentario_asesor, comentario_admin, fecha_envio)
VALUES
(4, 1, 1, 'Reporte #1 — Configuración del entorno',
 'Se configuró el entorno Flutter y la conexión inicial al broker MQTT.',
 '2026-03-06', '2026-03-12',
 'uploads/reportes/rep_al4_proy1_1.pdf',
 'revisado', 'Buen avance inicial. Continuar con el módulo de visualización.', NULL,
 DATE_SUB(NOW(), INTERVAL 18 DAY)),
(4, 1, 2, 'Reporte #2 — Módulo de lectura de sensores',
 'Pantalla de monitoreo en tiempo real con gráficas. Pruebas con datos simulados.',
 '2026-03-13', '2026-03-19',
 'uploads/reportes/rep_al4_proy1_2.pdf',
 'revisado', 'Excelente avance. Mejorar documentación del código.', NULL,
 DATE_SUB(NOW(), INTERVAL 11 DAY)),
(4, 1, 3, 'Reporte #3 — Sistema de alertas',
 'Módulo de alertas configurables por umbral con notificaciones push.',
 '2026-03-20', '2026-03-26',
 'uploads/reportes/rep_al4_proy1_3.pdf',
 'con_observaciones', 'Funcionalidad correcta. Pendiente: agregar pruebas unitarias.', NULL,
 DATE_SUB(NOW(), INTERVAL 4 DAY));

-- ── 9. Evidencias ───────────────────────────────────────────
INSERT INTO evidencias (id_alumno, descripcion, ruta_archivo, fecha_envio)
VALUES
(4, 'Captura de pantalla del dashboard funcionando en dispositivo físico.',
 'uploads/evidencias/evid_al4_1.pdf', DATE_SUB(NOW(), INTERVAL 6 DAY));

-- ── 10. Documentos alumno ───────────────────────────────────
INSERT INTO documentos_alumno (id_alumno, nombre, ruta_archivo) VALUES
(4, 'Carta de presentación institucional', 'uploads/documentos/doc_al4_carta.pdf');

-- ── 11. Evaluaciones ────────────────────────────────────────
INSERT INTO evaluaciones (id_alumno, id_asesor, id_proyecto,
    tipo, calificacion, comentarios, periodo_evaluado, fecha_evaluacion)
VALUES (
    4, 2, 1,
    'parcial', 8.5,
    'Excelente avance técnico. Mejorar documentación y agregar pruebas unitarias.',
    '6 al 25 de marzo 2026',
    DATE_SUB(NOW(), INTERVAL 5 DAY)
);

-- ── 12. Notificaciones ──────────────────────────────────────
INSERT INTO notificaciones (id_usuario, tipo, mensaje, leida, fecha) VALUES
(4, 'postulacion_registrada', 'Tu postulación al proyecto "App móvil IoT" fue registrada.',       1, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(4, 'empresa_acepto',         '¡Tech Bajío aceptó tu postulación! Sube tu anteproyecto.',          1, DATE_SUB(NOW(), INTERVAL  9 DAY)),
(4, 'anteproyecto_aprobado',  'Tu anteproyecto fue aprobado. Se te ha asignado un asesor.',        1, DATE_SUB(NOW(), INTERVAL  5 DAY)),
(4, 'asesor_asignado',        'El Dr. Eduardo Ramírez García ha sido asignado como tu asesor.',    1, DATE_SUB(NOW(), INTERVAL  5 DAY)),
(4, 'reporte_revisado',       'Tu reporte #3 fue revisado. Revisa los comentarios.',               0, DATE_SUB(NOW(), INTERVAL  4 DAY)),
(4, 'evaluacion_recibida',    'Tienes una evaluación parcial del Dr. Ramírez con calificación 8.5.',0, DATE_SUB(NOW(), INTERVAL  5 DAY)),
(4, 'empresa_rechazo',        'Tu postulación al proyecto "Chatbot IA" fue rechazada.',            1, DATE_SUB(NOW(), INTERVAL 14 DAY)),
(5, 'postulacion_registrada', 'Tu postulación al proyecto "App móvil IoT" fue registrada.',        1, DATE_SUB(NOW(), INTERVAL  8 DAY)),
(6, 'postulacion_registrada', 'Tu postulación al proyecto "Chatbot IA" fue registrada.',           0, DATE_SUB(NOW(), INTERVAL  5 DAY));

SELECT 'Script 02 completado. Contraseña de todos los usuarios: Test1234' AS resultado;
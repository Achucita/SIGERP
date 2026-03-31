-- ============================================================
--  SIGERP - Script 02 - Datos de prueba
--  Cubre el flujo completo:
--  empresa registra → admin publica → alumno se postula →
--  empresa acepta → alumno sube anteproyecto → admin aprueba
--  → admin asigna asesor → alumno sube reportes → asesor evalúa
--
--  IMPORTANTE: Las contraseñas aquí son hashes bcrypt de "Test1234"
--  En producción el backend genera el hash. Estos son solo para pruebas.
-- ============================================================

USE SIGERP_DB;
GO

-- ── LIMPIAR datos previos (respeta el orden por FK) ──────────
DELETE FROM notificaciones;
DELETE FROM evaluaciones;
DELETE FROM reportes;
DELETE FROM anteproyectos;
DELETE FROM postulaciones;
DELETE FROM proyectos;
DELETE FROM empresas;
DELETE FROM administradores;
DELETE FROM asesores;
DELETE FROM alumnos;
DELETE FROM usuarios;

-- Reiniciar contadores IDENTITY
DBCC CHECKIDENT ('usuarios',        RESEED, 0);
DBCC CHECKIDENT ('empresas',        RESEED, 0);
DBCC CHECKIDENT ('proyectos',       RESEED, 0);
DBCC CHECKIDENT ('postulaciones',   RESEED, 0);
DBCC CHECKIDENT ('anteproyectos',   RESEED, 0);
DBCC CHECKIDENT ('reportes',        RESEED, 0);
DBCC CHECKIDENT ('evaluaciones',    RESEED, 0);
DBCC CHECKIDENT ('notificaciones',  RESEED, 0);
GO

-- ════════════════════════════════════════════════════════════
--  1. USUARIOS BASE
--  Contraseña de todos: "Test1234"
--  Hash bcrypt (cost 10): $2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
-- ════════════════════════════════════════════════════════════
INSERT INTO usuarios (nombre, correo, contrasena, rol) VALUES
-- Administrador
(N'José Luis Suárez y Gómez',    'jlsuarez@itl.edu.mx',      '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
-- Asesores
(N'Eduardo Ramírez García',       'e.ramirez@itl.edu.mx',     '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'asesor'),
(N'Lucía Moreno Pérez',           'l.moreno@itl.edu.mx',      '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'asesor'),
-- Alumnos
(N'Aragón Guerrero Jacziry Berenice', 'jacziry@itl.edu.mx',   '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'alumno'),
(N'Cortez Iñiguez Juan José',     'juanjose@itl.edu.mx',      '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'alumno'),
(N'Ramírez Torres Mario',         'm.ramirez@itl.edu.mx',     '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'alumno');
GO

-- ════════════════════════════════════════════════════════════
--  2. TABLAS EXTENDIDAS (usando los IDs que IDENTITY generó)
-- ════════════════════════════════════════════════════════════

-- Administrador (id_usuario = 1)
INSERT INTO administradores (id_admin) VALUES (1);

-- Asesores (id_usuario = 2, 3)
INSERT INTO asesores (id_asesor, area) VALUES
(2, N'Sistemas y Computación'),
(3, N'Tecnologías de la Información');

-- Alumnos (id_usuario = 4, 5, 6)
INSERT INTO alumnos (id_alumno, matricula, carrera) VALUES
(4, '21240179', N'Ingeniería en Sistemas Computacionales'),
(5, '21240173', N'Ingeniería en Sistemas Computacionales'),
(6, '21240101', N'Ingeniería en Inteligencia Artificial');
GO

-- ════════════════════════════════════════════════════════════
--  3. EMPRESAS (registradas por formulario público)
-- ════════════════════════════════════════════════════════════
INSERT INTO empresas (nombre, giro, direccion, telefono, correo_empresa,
    pagina_web, nombre_responsable, cargo_responsable,
    telefono_responsable, correo_responsable)
VALUES
(
    N'Tech Bajío S.A. de C.V.',
    N'Desarrollo de software industrial',
    N'Blvd. Aeropuerto 3302, Fraccionamiento Industrial, León, Gto.',
    '(477) 710-0100',
    'contacto@techbajio.mx',
    'www.techbajio.mx',
    N'Juan López Ortega',
    N'Gerente de Recursos Humanos',
    '(477) 710-0101',
    'rrhh@techbajio.mx'
),
(
    N'Innovatech MX S.A.',
    N'Inteligencia Artificial y Automatización',
    N'Av. Insurgentes 450, Col. Centro, León, Gto.',
    '(477) 715-2200',
    'proyectos@innovatech.mx',
    'www.innovatech.mx',
    N'Sofía Medina Torres',
    N'Directora de TI',
    '(477) 715-2201',
    'dev@innovatech.mx'
),
(
    N'DataCore León',
    N'Análisis de datos y Business Intelligence',
    N'Calle Tecnológico 105, Parque Industrial, León, Gto.',
    '(477) 720-3300',
    'info@datacore.mx',
    NULL,
    N'Roberto Chávez Ruiz',
    N'Coordinador de Proyectos',
    '(477) 720-3301',
    'projects@datacore.mx'
);
GO

-- ════════════════════════════════════════════════════════════
--  4. PROYECTOS
--  id_empresa: 1=Tech Bajío, 2=Innovatech, 3=DataCore
--  id_asesor se asigna después del anteproyecto (flujo correcto)
-- ════════════════════════════════════════════════════════════
INSERT INTO proyectos (id_empresa, id_asesor, nombre, descripcion, area,
    requisitos, modalidad, num_alumnos, estado)
VALUES
(
    1, NULL,
    N'App móvil IoT',
    N'Desarrollo de aplicación para monitoreo de sensores industriales en tiempo real desde dispositivos móviles. El sistema debe integrarse con plataforma MQTT y contar con visualizaciones en tiempo real.',
    N'Desarrollo de Software',
    N'Carrera ISC o IA. Conocimientos en Flutter y Node.js. Disponibilidad 6 meses. Inglés básico deseable.',
    'presencial', 2, 'publicado'
),
(
    2, NULL,
    N'Chatbot IA para atención a clientes',
    N'Creación de asistente virtual con procesamiento de lenguaje natural para atención al cliente de una empresa financiera. Integración con plataformas de mensajería.',
    N'Inteligencia Artificial',
    N'Carrera ISC o IA. Conocimientos en Python y NLP. Experiencia con APIs REST.',
    'hibrido', 2, 'publicado'
),
(
    3, NULL,
    N'Dashboard de análisis de datos logísticos',
    N'Desarrollo de tablero de visualización e inteligencia de negocios para el área comercial y logística de la empresa.',
    N'Análisis de Datos',
    N'Carrera ISC. Conocimientos en Python, SQL y Power BI o similar. Disponibilidad 6 meses.',
    'remoto', 3, 'revision'   -- aún en revisión por el admin
);
GO

-- ════════════════════════════════════════════════════════════
--  5. POSTULACIONES
--  Flujo del proyecto 1 (App IoT) — completo de punta a punta
--  Flujo del proyecto 2 (Chatbot) — postulación pendiente
-- ════════════════════════════════════════════════════════════
INSERT INTO postulaciones (id_alumno, id_proyecto, estado, correo_enviado, fecha_postulacion)
VALUES
-- Jacziry (id=4) → App IoT (id=1): empresa aceptó ✓
(4, 1, 'aceptada',  1, DATEADD(DAY, -10, GETDATE())),
-- Juan José (id=5) → App IoT (id=1): pendiente
(5, 1, 'pendiente', 1, DATEADD(DAY,  -8, GETDATE())),
-- Mario (id=6) → Chatbot (id=2): pendiente
(6, 2, 'pendiente', 1, DATEADD(DAY,  -5, GETDATE())),
-- Jacziry (id=4) → Chatbot (id=2): rechazada
(4, 2, 'rechazada', 1, DATEADD(DAY, -15, GETDATE()));
GO

-- ════════════════════════════════════════════════════════════
--  6. ANTEPROYECTO
--  Solo Jacziry subió el suyo (postulación id=1, aceptada)
--  El admin ya lo aprobó → se asigna asesor al proyecto
-- ════════════════════════════════════════════════════════════
INSERT INTO anteproyectos (id_postulacion, titulo, descripcion,
    ruta_archivo, estado, comentario_admin, fecha_envio, fecha_revision)
VALUES (
    1,  -- postulacion de Jacziry
    N'Sistema de monitoreo IoT para sensores industriales con Flutter',
    N'Desarrollo de una aplicación móvil en Flutter que consuma datos MQTT de sensores de temperatura, presión y vibración en tiempo real, con alertas configurables y almacenamiento histórico.',
    'uploads/anteproyectos/antep_postulacion_1.pdf',
    'aprobado',
    N'Anteproyecto bien estructurado. Se aprueba y se procede a asignar asesor.',
    DATEADD(DAY, -7, GETDATE()),
    DATEADD(DAY, -5, GETDATE())
);
GO

-- Una vez aprobado el anteproyecto, el admin asigna el asesor al proyecto
UPDATE proyectos
SET id_asesor = 2   -- Dr. Eduardo Ramírez
WHERE id_proyecto = 1;
GO

-- ════════════════════════════════════════════════════════════
--  7. REPORTES (Jacziry, proyecto App IoT, con asesor asignado)
-- ════════════════════════════════════════════════════════════
INSERT INTO reportes (id_alumno, id_proyecto, numero_reporte, titulo,
    descripcion, periodo_inicio, periodo_fin,
    ruta_archivo, estado, comentario_asesor, fecha_envio)
VALUES
(
    4, 1, 1,
    N'Reporte semanal #1 — Configuración del entorno',
    N'Se configuró el entorno de desarrollo Flutter, se instalaron dependencias y se realizó la conexión inicial al broker MQTT de prueba.',
    '2026-03-06', '2026-03-12',
    'uploads/reportes/rep_al4_proy1_1.pdf',
    'revisado',
    N'Buen avance inicial. Continuar con el módulo de visualización.',
    DATEADD(DAY, -18, GETDATE())
),
(
    4, 1, 2,
    N'Reporte semanal #2 — Módulo de lectura de sensores',
    N'Se implementó la pantalla de monitoreo en tiempo real con gráficas de temperatura y presión. Se realizaron pruebas con datos simulados.',
    '2026-03-13', '2026-03-19',
    'uploads/reportes/rep_al4_proy1_2.pdf',
    'revisado',
    N'Excelente avance. Las visualizaciones son claras. Mejorar documentación del código.',
    DATEADD(DAY, -11, GETDATE())
),
(
    4, 1, 3,
    N'Reporte semanal #3 — Sistema de alertas',
    N'Se desarrolló el módulo de alertas configurables por umbral. El usuario puede establecer rangos de operación normal y recibe notificaciones push cuando se supera el umbral.',
    '2026-03-20', '2026-03-26',
    'uploads/reportes/rep_al4_proy1_3.pdf',
    'con_observaciones',
    N'Funcionalidad correcta. Pendiente: agregar pruebas unitarias al módulo de alertas.',
    DATEADD(DAY,  -4, GETDATE())
);
GO

-- ════════════════════════════════════════════════════════════
--  8. EVALUACIONES (asesor Dr. Ramírez evalúa a Jacziry)
-- ════════════════════════════════════════════════════════════
INSERT INTO evaluaciones (id_alumno, id_asesor, id_proyecto,
    tipo, calificacion, comentarios, periodo_evaluado, fecha_evaluacion)
VALUES (
    4, 2, 1,
    'parcial', 8.5,
    N'Excelente avance técnico en el desarrollo de la aplicación. Se recomienda mejorar la documentación del proceso y agregar pruebas unitarias al código entregado.',
    N'6 al 25 de marzo 2026',
    DATEADD(DAY, -5, GETDATE())
);
GO

-- ════════════════════════════════════════════════════════════
--  9. NOTIFICACIONES
-- ════════════════════════════════════════════════════════════
INSERT INTO notificaciones (id_usuario, tipo, mensaje, leida, fecha)
VALUES
-- Para Jacziry (id=4)
(4, 'postulacion_registrada',
    N'Tu postulación al proyecto "App móvil IoT" fue registrada. Se notificó a la empresa por correo.',
    1, DATEADD(DAY, -10, GETDATE())),
(4, 'empresa_acepto',
    N'¡Tech Bajío S.A. aceptó tu postulación al proyecto "App móvil IoT"! Sube tu anteproyecto para continuar.',
    1, DATEADD(DAY,  -9, GETDATE())),
(4, 'anteproyecto_aprobado',
    N'Tu anteproyecto fue aprobado por el administrador. Pronto se te asignará un asesor.',
    1, DATEADD(DAY,  -5, GETDATE())),
(4, 'asesor_asignado',
    N'El Dr. Eduardo Ramírez García ha sido asignado como tu asesor académico. Ya puedes subir tus reportes de avance.',
    1, DATEADD(DAY,  -5, GETDATE())),
(4, 'reporte_revisado',
    N'Tu reporte semanal #3 fue revisado por el Dr. Ramírez. Revisa los comentarios.',
    0, DATEADD(DAY,  -4, GETDATE())),
(4, 'evaluacion_recibida',
    N'Tienes una nueva evaluación parcial del Dr. Eduardo Ramírez con calificación 8.5.',
    0, DATEADD(DAY,  -5, GETDATE())),
(4, 'empresa_rechazo',
    N'Tu postulación al proyecto "Chatbot IA" fue rechazada. Puedes postularte a otros proyectos disponibles.',
    1, DATEADD(DAY, -14, GETDATE())),
-- Para Juan José (id=5)
(5, 'postulacion_registrada',
    N'Tu postulación al proyecto "App móvil IoT" fue registrada. Se notificó a la empresa por correo.',
    1, DATEADD(DAY,  -8, GETDATE())),
-- Para Mario (id=6)
(6, 'postulacion_registrada',
    N'Tu postulación al proyecto "Chatbot IA" fue registrada. Se notificó a la empresa por correo.',
    0, DATEADD(DAY,  -5, GETDATE()));
GO

-- ════════════════════════════════════════════════════════════
--  VERIFICACIÓN FINAL — mostrar recuento de todas las tablas
-- ════════════════════════════════════════════════════════════
SELECT 'usuarios'        AS tabla, COUNT(*) AS registros FROM usuarios       UNION ALL
SELECT 'alumnos',                  COUNT(*)               FROM alumnos        UNION ALL
SELECT 'asesores',                 COUNT(*)               FROM asesores       UNION ALL
SELECT 'administradores',          COUNT(*)               FROM administradores UNION ALL
SELECT 'empresas',                 COUNT(*)               FROM empresas       UNION ALL
SELECT 'proyectos',                COUNT(*)               FROM proyectos      UNION ALL
SELECT 'postulaciones',            COUNT(*)               FROM postulaciones  UNION ALL
SELECT 'anteproyectos',            COUNT(*)               FROM anteproyectos  UNION ALL
SELECT 'reportes',                 COUNT(*)               FROM reportes       UNION ALL
SELECT 'evaluaciones',             COUNT(*)               FROM evaluaciones   UNION ALL
SELECT 'notificaciones',           COUNT(*)               FROM notificaciones;
GO

PRINT '================================================';
PRINT 'Script 02 completado. Datos de prueba insertados.';
PRINT 'Contraseña de todos los usuarios: Test1234';
PRINT '================================================';
GO
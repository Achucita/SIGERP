-- ============================================================
--  SIGERP - Script 03 - Consultas de verificación y utilidad
--  Ejecuta cada bloque por separado seleccionándolo con F5
-- ============================================================

USE SIGERP_DB;
GO

-- ────────────────────────────────────────────────────────────
--  Q1. Ver todos los usuarios con su rol
-- ────────────────────────────────────────────────────────────
SELECT
    u.id_usuario,
    u.nombre,
    u.correo,
    u.rol,
    u.activo,
    u.fecha_registro
FROM usuarios u
ORDER BY u.rol, u.nombre;
GO

-- ────────────────────────────────────────────────────────────
--  Q2. Alumnos con datos completos
-- ────────────────────────────────────────────────────────────
SELECT
    a.id_alumno,
    u.nombre,
    a.matricula,
    a.carrera,
    u.correo
FROM alumnos a
JOIN usuarios u ON u.id_usuario = a.id_alumno
ORDER BY a.matricula;
GO

-- ────────────────────────────────────────────────────────────
--  Q3. Proyectos con empresa y asesor asignado
-- ────────────────────────────────────────────────────────────
SELECT
    p.id_proyecto,
    p.nombre                    AS proyecto,
    e.nombre                    AS empresa,
    p.estado,
    p.modalidad,
    p.num_alumnos               AS cupo,
    ISNULL(u_ase.nombre, '— Sin asignar —') AS asesor
FROM proyectos p
JOIN  empresas e        ON e.id_empresa = p.id_empresa
LEFT JOIN asesores  a   ON a.id_asesor  = p.id_asesor
LEFT JOIN usuarios u_ase ON u_ase.id_usuario = a.id_asesor
ORDER BY p.estado DESC, p.id_proyecto;
GO

-- ────────────────────────────────────────────────────────────
--  Q4. Estado del flujo completo — postulaciones
-- ────────────────────────────────────────────────────────────
SELECT
    pos.id_postulacion,
    u_al.nombre                 AS alumno,
    al.matricula,
    p.nombre                    AS proyecto,
    e.nombre                    AS empresa,
    pos.estado                  AS estado_postulacion,
    pos.correo_enviado          AS correo_enviado,
    ISNULL(ant.estado, '— sin anteproyecto —') AS anteproyecto,
    ISNULL(u_ase.nombre, '— sin asesor —')     AS asesor_asignado,
    pos.fecha_postulacion
FROM postulaciones pos
JOIN alumnos    al      ON al.id_alumno   = pos.id_alumno
JOIN usuarios   u_al    ON u_al.id_usuario = al.id_alumno
JOIN proyectos  p       ON p.id_proyecto  = pos.id_proyecto
JOIN empresas   e       ON e.id_empresa   = p.id_empresa
LEFT JOIN anteproyectos ant ON ant.id_postulacion = pos.id_postulacion
LEFT JOIN asesores  a_rec   ON a_rec.id_asesor     = p.id_asesor
LEFT JOIN usuarios  u_ase   ON u_ase.id_usuario    = a_rec.id_asesor
ORDER BY pos.fecha_postulacion DESC;
GO

-- ────────────────────────────────────────────────────────────
--  Q5. Reportes de un alumno específico (cambiar matrícula)
-- ────────────────────────────────────────────────────────────
DECLARE @matricula NVARCHAR(20) = '21240179';

SELECT
    r.numero_reporte,
    r.titulo,
    r.periodo_inicio,
    r.periodo_fin,
    r.estado,
    r.comentario_asesor,
    r.fecha_envio
FROM reportes r
JOIN alumnos al ON al.id_alumno = r.id_alumno
WHERE al.matricula = @matricula
ORDER BY r.numero_reporte;
GO

-- ────────────────────────────────────────────────────────────
--  Q6. Evaluaciones de un alumno
-- ────────────────────────────────────────────────────────────
SELECT
    ev.tipo,
    ev.calificacion,
    ev.comentarios,
    ev.periodo_evaluado,
    ev.fecha_evaluacion,
    u_ase.nombre            AS asesor,
    p.nombre                AS proyecto
FROM evaluaciones ev
JOIN usuarios u_al  ON u_al.id_usuario = ev.id_alumno
JOIN usuarios u_ase ON u_ase.id_usuario = ev.id_asesor
JOIN proyectos p    ON p.id_proyecto   = ev.id_proyecto
WHERE u_al.correo = 'jacziry@itl.edu.mx'
ORDER BY ev.fecha_evaluacion;
GO

-- ────────────────────────────────────────────────────────────
--  Q7. Notificaciones no leídas de un usuario
-- ────────────────────────────────────────────────────────────
SELECT
    n.tipo,
    n.mensaje,
    n.fecha
FROM notificaciones n
JOIN usuarios u ON u.id_usuario = n.id_usuario
WHERE u.correo = 'jacziry@itl.edu.mx'
  AND n.leida = 0
ORDER BY n.fecha DESC;
GO

-- ────────────────────────────────────────────────────────────
--  Q8. Resumen estadístico del sistema (para el dashboard admin)
-- ────────────────────────────────────────────────────────────
SELECT
    (SELECT COUNT(*) FROM alumnos)                          AS total_alumnos,
    (SELECT COUNT(*) FROM asesores)                         AS total_asesores,
    (SELECT COUNT(*) FROM proyectos WHERE estado = 'publicado') AS proyectos_publicados,
    (SELECT COUNT(*) FROM proyectos WHERE estado = 'revision')  AS proyectos_en_revision,
    (SELECT COUNT(*) FROM postulaciones)                    AS total_postulaciones,
    (SELECT COUNT(*) FROM postulaciones WHERE estado = 'pendiente')  AS post_pendientes,
    (SELECT COUNT(*) FROM postulaciones WHERE estado = 'aceptada')   AS post_aceptadas,
    (SELECT COUNT(*) FROM postulaciones WHERE estado = 'rechazada')  AS post_rechazadas,
    (SELECT COUNT(*) FROM anteproyectos WHERE estado = 'pendiente')  AS antep_pendientes,
    (SELECT COUNT(*) FROM anteproyectos WHERE estado = 'aprobado')   AS antep_aprobados,
    (SELECT COUNT(*) FROM reportes)                         AS total_reportes,
    (SELECT COUNT(*) FROM evaluaciones)                     AS total_evaluaciones;
GO
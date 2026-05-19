-- ============================================================
--  SIGERP — Script oficial convertido a MySQL 8.x
--  Origen: Script.sql exportado desde SSMS (SQL Server)
--  Fecha exportación: 18/05/2026
-- ============================================================

CREATE DATABASE IF NOT EXISTS sigerpdb
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;

-- Crea el usuario de la app y le da permisos (ajusta la contraseña)
CREATE USER IF NOT EXISTS 'sigerp'@'localhost' IDENTIFIED BY 'CAMBIA_ESTA_CONTRASENA';
GRANT ALL PRIVILEGES ON sigerpdb.* TO 'sigerp'@'localhost';
FLUSH PRIVILEGES;

USE sigerpdb;

-- ── usuarios ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario      INT             NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(120)    NOT NULL,
    correo          VARCHAR(150)    NOT NULL,
    contrasena      VARCHAR(255)    NOT NULL,
    rol             VARCHAR(20)     NOT NULL,
    fecha_registro  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo          TINYINT(1)      NOT NULL DEFAULT 1,

    CONSTRAINT PK_usuarios         PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_usuarios_correo  UNIQUE (correo),
    CONSTRAINT CK_usuarios_rol     CHECK (rol IN ('alumno','asesor','admin'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── administradores ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS administradores (
    id_admin INT NOT NULL,

    CONSTRAINT PK_admins    PRIMARY KEY (id_admin),
    CONSTRAINT FK_admins_usr FOREIGN KEY (id_admin)
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── asesores ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS asesores (
    id_asesor   INT          NOT NULL,
    area        VARCHAR(100) NOT NULL,

    CONSTRAINT PK_asesores      PRIMARY KEY (id_asesor),
    CONSTRAINT FK_asesores_usr  FOREIGN KEY (id_asesor)
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── alumnos ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS alumnos (
    id_alumno   INT          NOT NULL,
    matricula   VARCHAR(20)  NOT NULL,
    carrera     VARCHAR(100) NOT NULL,

    CONSTRAINT PK_alumnos       PRIMARY KEY (id_alumno),
    CONSTRAINT FK_alumnos_usr   FOREIGN KEY (id_alumno)
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT UQ_alumnos_mat   UNIQUE (matricula)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── empresas ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS empresas (
    id_empresa              INT          NOT NULL AUTO_INCREMENT,
    nombre                  VARCHAR(150) NOT NULL,
    giro                    VARCHAR(100) NULL,
    direccion               VARCHAR(250) NULL,
    telefono                VARCHAR(20)  NULL,
    correo_empresa          VARCHAR(150) NOT NULL,
    pagina_web              VARCHAR(200) NULL,
    nombre_responsable      VARCHAR(120) NOT NULL,
    cargo_responsable       VARCHAR(100) NULL,
    telefono_responsable    VARCHAR(20)  NULL,
    correo_responsable      VARCHAR(150) NOT NULL,
    fecha_registro          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activa                  TINYINT(1)   NOT NULL DEFAULT 1,

    CONSTRAINT PK_empresas PRIMARY KEY (id_empresa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── periodos_reporte ─────────────────────────────────────────
-- Tabla nueva que no estaba en el script anterior del proyecto
CREATE TABLE IF NOT EXISTS periodos_reporte (
    numero_reporte  INT          NOT NULL,
    nombre          VARCHAR(100) NOT NULL DEFAULT '',
    fecha_apertura  DATETIME     NULL,
    fecha_cierre    DATETIME     NULL,

    PRIMARY KEY (numero_reporte),
    CONSTRAINT CK_periodos_num CHECK (numero_reporte IN (1, 2, 3))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── proyectos ────────────────────────────────────────────────
-- Columnas nuevas respecto al script viejo: apoyo_economico, monto_apoyo
CREATE TABLE IF NOT EXISTS proyectos (
    id_proyecto     INT             NOT NULL AUTO_INCREMENT,
    id_empresa      INT             NOT NULL,
    id_asesor       INT             NULL,
    nombre          VARCHAR(200)    NOT NULL,
    descripcion     TEXT            NOT NULL,
    area            VARCHAR(100)    NULL,
    requisitos      TEXT            NULL,
    modalidad       VARCHAR(20)     NOT NULL,
    num_alumnos     INT             NOT NULL DEFAULT 1,
    estado          VARCHAR(20)     NOT NULL DEFAULT 'revision',
    fecha_creacion  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    apoyo_economico VARCHAR(20)     NULL,
    monto_apoyo     DECIMAL(10,2)   NULL,

    CONSTRAINT PK_proyectos         PRIMARY KEY (id_proyecto),
    CONSTRAINT FK_proy_empresa      FOREIGN KEY (id_empresa)
        REFERENCES empresas(id_empresa),
    CONSTRAINT FK_proy_asesor       FOREIGN KEY (id_asesor)
        REFERENCES asesores(id_asesor),
    CONSTRAINT CK_proyectos_estado    CHECK (estado    IN ('revision','publicado','cerrado','despublicado')),
    CONSTRAINT CK_proyectos_modalidad CHECK (modalidad IN ('presencial','remoto','hibrido'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── postulaciones ────────────────────────────────────────────
-- Columnas nuevas respecto al script viejo: observaciones, cv_ruta
CREATE TABLE IF NOT EXISTS postulaciones (
    id_postulacion      INT          NOT NULL AUTO_INCREMENT,
    id_alumno           INT          NOT NULL,
    id_proyecto         INT          NOT NULL,
    estado              VARCHAR(20)  NOT NULL DEFAULT 'pendiente',
    correo_enviado      TINYINT(1)   NOT NULL DEFAULT 0,
    fecha_postulacion   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observaciones       VARCHAR(500) NULL,
    cv_ruta             VARCHAR(500) NULL,

    CONSTRAINT PK_postulaciones     PRIMARY KEY (id_postulacion),
    CONSTRAINT FK_post_alumno       FOREIGN KEY (id_alumno)
        REFERENCES alumnos(id_alumno),
    CONSTRAINT FK_post_proyecto     FOREIGN KEY (id_proyecto)
        REFERENCES proyectos(id_proyecto),
    CONSTRAINT UQ_post_alumno_proy  UNIQUE (id_alumno, id_proyecto),
    CONSTRAINT CK_post_estado       CHECK (estado IN ('pendiente','aceptada','rechazada'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── anteproyectos ────────────────────────────────────────────
-- Diferencias importantes vs script viejo:
--   - id_postulacion es NULL (no NOT NULL) → un alumno puede subir sin postulación directa
--   - Columna nueva: id_alumno (FK directa al usuario)
--   - Columna nueva: asesores_propuestos
--   - Columna nueva: id_asesor_asignado (FK a usuarios, no a asesores)
--   - Estado tiene valor adicional: 'asignado'
CREATE TABLE IF NOT EXISTS anteproyectos (
    id_anteproyecto     INT          NOT NULL AUTO_INCREMENT,
    id_postulacion      INT          NULL,
    titulo              VARCHAR(200) NOT NULL,
    descripcion         TEXT         NULL,
    ruta_archivo        VARCHAR(500) NOT NULL,
    estado              VARCHAR(20)  NOT NULL DEFAULT 'pendiente',
    comentario_admin    TEXT         NULL,
    fecha_envio         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_revision      DATETIME     NULL,
    id_alumno           INT          NOT NULL,
    asesores_propuestos VARCHAR(500) NULL,
    id_asesor_asignado  INT          NULL,

    CONSTRAINT PK_anteproyectos        PRIMARY KEY (id_anteproyecto),
    CONSTRAINT FK_antep_post           FOREIGN KEY (id_postulacion)
        REFERENCES postulaciones(id_postulacion),
    CONSTRAINT FK_anteproyectos_alumno FOREIGN KEY (id_alumno)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT FK_anteproyectos_asesor FOREIGN KEY (id_asesor_asignado)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT CK_antep_estado         CHECK (estado IN ('pendiente','aprobado','rechazado','asignado','con_observaciones'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── documentos_alumno ────────────────────────────────────────
-- Tabla renombrada (antes era 'documentos') y con estructura diferente
CREATE TABLE IF NOT EXISTS documentos_alumno (
    id_documento    INT          NOT NULL AUTO_INCREMENT,
    id_alumno       INT          NOT NULL,
    nombre          VARCHAR(255) NOT NULL,
    ruta_archivo    VARCHAR(500) NOT NULL,
    fecha_subida    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_documento),
    FOREIGN KEY (id_alumno) REFERENCES alumnos(id_alumno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── evidencias ───────────────────────────────────────────────
-- Diferencias vs script viejo: sin id_proyecto, sin titulo,
-- comentario_asesor y fecha_comentario en lugar de comentario
CREATE TABLE IF NOT EXISTS evidencias (
    id_evidencia        INT          NOT NULL AUTO_INCREMENT,
    id_alumno           INT          NOT NULL,
    descripcion         VARCHAR(500) NULL,
    ruta_archivo        VARCHAR(500) NOT NULL,
    comentario_asesor   TEXT         NULL,
    fecha_envio         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_comentario    DATETIME     NULL,

    PRIMARY KEY (id_evidencia),
    FOREIGN KEY (id_alumno) REFERENCES alumnos(id_alumno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── reportes ─────────────────────────────────────────────────
-- Diferencias vs script viejo: id_proyecto es NULL, titulo NULL,
-- columna nueva: comentario_admin
CREATE TABLE IF NOT EXISTS reportes (
    id_reporte          INT          NOT NULL AUTO_INCREMENT,
    id_alumno           INT          NOT NULL,
    id_proyecto         INT          NULL,
    numero_reporte      INT          NOT NULL,
    titulo              VARCHAR(200) NULL,
    descripcion         TEXT         NULL,
    periodo_inicio      DATE         NULL,
    periodo_fin         DATE         NULL,
    ruta_archivo        VARCHAR(500) NOT NULL,
    estado              VARCHAR(20)  NOT NULL DEFAULT 'enviado',
    comentario_asesor   TEXT         NULL,
    fecha_envio         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    comentario_admin    TEXT         NULL,

    CONSTRAINT PK_reportes      PRIMARY KEY (id_reporte),
    CONSTRAINT FK_rep_alumno    FOREIGN KEY (id_alumno)
        REFERENCES alumnos(id_alumno),
    CONSTRAINT FK_rep_proyecto  FOREIGN KEY (id_proyecto)
        REFERENCES proyectos(id_proyecto),
    CONSTRAINT CK_rep_estado    CHECK (estado IN ('enviado','revisado','con_observaciones'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── evaluaciones ─────────────────────────────────────────────
-- Diferencia: id_proyecto es NULL (ON DELETE SET NULL)
CREATE TABLE IF NOT EXISTS evaluaciones (
    id_evaluacion   INT             NOT NULL AUTO_INCREMENT,
    id_alumno       INT             NOT NULL,
    id_asesor       INT             NOT NULL,
    id_proyecto     INT             NULL,
    tipo            VARCHAR(20)     NOT NULL,
    calificacion    DECIMAL(4,1)    NOT NULL,
    comentarios     TEXT            NULL,
    periodo_evaluado VARCHAR(100)   NULL,
    fecha_evaluacion DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_evaluaciones  PRIMARY KEY (id_evaluacion),
    CONSTRAINT FK_eval_alumno   FOREIGN KEY (id_alumno)
        REFERENCES alumnos(id_alumno),
    CONSTRAINT FK_eval_asesor   FOREIGN KEY (id_asesor)
        REFERENCES asesores(id_asesor),
    CONSTRAINT FK_eval_proyecto FOREIGN KEY (id_proyecto)
        REFERENCES proyectos(id_proyecto) ON DELETE SET NULL,
    CONSTRAINT CK_eval_cal      CHECK (calificacion BETWEEN 0 AND 10),
    CONSTRAINT CK_eval_tipo     CHECK (tipo IN ('parcial','final'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── notificaciones ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notificaciones (
    id_notificacion INT          NOT NULL AUTO_INCREMENT,
    id_usuario      INT          NOT NULL,
    tipo            VARCHAR(50)  NOT NULL,
    mensaje         VARCHAR(500) NOT NULL,
    leida           TINYINT(1)   NOT NULL DEFAULT 0,
    fecha           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_notificaciones PRIMARY KEY (id_notificacion),
    CONSTRAINT FK_notif_usuario  FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ── Índices ──────────────────────────────────────────────────
CREATE INDEX IX_postulaciones_alumno    ON postulaciones(id_alumno);
CREATE INDEX IX_postulaciones_proyecto  ON postulaciones(id_proyecto);
CREATE INDEX IX_reportes_alumno         ON reportes(id_alumno);
CREATE INDEX IX_evaluaciones_alumno     ON evaluaciones(id_alumno);
CREATE INDEX IX_notificaciones_usr_leida ON notificaciones(id_usuario, leida);
CREATE INDEX IX_proyectos_estado        ON proyectos(estado);
CREATE INDEX IX_anteproyectos_alumno    ON anteproyectos(id_alumno);

SELECT 'Script oficial convertido a MySQL — completado.' AS resultado;
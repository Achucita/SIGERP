-- ============================================================
--  SIGERP - Sistema Integral Inteligente para la Gestión
--           de Residencias Profesionales
--  Script 01 - Creación de base de datos y tablas
--  SSMS 22 / SQL Server
--  Ejecutar completo de una sola vez
-- ============================================================

-- ── 1. Crear y usar la base de datos ────────────────────────
IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = 'SIGERP_DB'
)
BEGIN
    CREATE DATABASE SIGERP_DB
    COLLATE Modern_Spanish_CI_AI;   -- acentos y ñ sin problemas
    PRINT 'Base de datos SIGERP_DB creada.';
END
ELSE
    PRINT 'Base de datos SIGERP_DB ya existe. Continuando...';
GO

USE SIGERP_DB;
GO

-- ── 2. Tabla: usuarios (base para herencia) ─────────────────
-- Todos los actores internos del sistema heredan de esta tabla.
-- El rol determina de qué tabla extendida son parte.
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'usuarios')
BEGIN
    CREATE TABLE usuarios (
        id_usuario      INT             IDENTITY(1,1)   NOT NULL,
        nombre          NVARCHAR(120)                   NOT NULL,
        correo          NVARCHAR(150)                   NOT NULL,
        contrasena      NVARCHAR(255)                   NOT NULL,  -- hash bcrypt
        rol             NVARCHAR(20)                    NOT NULL   -- 'alumno' | 'asesor' | 'admin'
            CONSTRAINT CK_usuarios_rol CHECK (rol IN ('alumno', 'asesor', 'admin')),
        fecha_registro  DATETIME2       DEFAULT GETDATE() NOT NULL,
        activo          BIT             DEFAULT 1       NOT NULL,  -- 0 = baja lógica

        CONSTRAINT PK_usuarios PRIMARY KEY (id_usuario),
        CONSTRAINT UQ_usuarios_correo UNIQUE (correo)
    );
    PRINT 'Tabla usuarios creada.';
END
GO

-- ── 3. Tabla: alumnos ────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'alumnos')
BEGIN
    CREATE TABLE alumnos (
        id_alumno       INT             NOT NULL,       -- FK → usuarios.id_usuario
        matricula       NVARCHAR(20)                    NOT NULL,
        carrera         NVARCHAR(100)                   NOT NULL,

        CONSTRAINT PK_alumnos       PRIMARY KEY (id_alumno),
        CONSTRAINT FK_alumnos_usr   FOREIGN KEY (id_alumno)
            REFERENCES usuarios(id_usuario)
            ON DELETE CASCADE,
        CONSTRAINT UQ_alumnos_mat   UNIQUE (matricula)
    );
    PRINT 'Tabla alumnos creada.';
END
GO

-- ── 4. Tabla: asesores ───────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'asesores')
BEGIN
    CREATE TABLE asesores (
        id_asesor       INT             NOT NULL,       -- FK → usuarios.id_usuario
        area            NVARCHAR(100)                   NOT NULL,

        CONSTRAINT PK_asesores      PRIMARY KEY (id_asesor),
        CONSTRAINT FK_asesores_usr  FOREIGN KEY (id_asesor)
            REFERENCES usuarios(id_usuario)
            ON DELETE CASCADE
    );
    PRINT 'Tabla asesores creada.';
END
GO

-- ── 5. Tabla: administradores ───────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'administradores')
BEGIN
    CREATE TABLE administradores (
        id_admin        INT             NOT NULL,       -- FK → usuarios.id_usuario

        CONSTRAINT PK_admins        PRIMARY KEY (id_admin),
        CONSTRAINT FK_admins_usr    FOREIGN KEY (id_admin)
            REFERENCES usuarios(id_usuario)
            ON DELETE CASCADE
    );
    PRINT 'Tabla administradores creada.';
END
GO

-- ── 6. Tabla: empresas ───────────────────────────────────────
-- Registradas por el formulario público (sin cuenta de usuario).
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'empresas')
BEGIN
    CREATE TABLE empresas (
        id_empresa          INT             IDENTITY(1,1)   NOT NULL,
        nombre              NVARCHAR(150)                   NOT NULL,
        giro                NVARCHAR(100)                   NULL,
        direccion           NVARCHAR(250)                   NULL,
        telefono            NVARCHAR(20)                    NULL,
        correo_empresa      NVARCHAR(150)                   NOT NULL,
        pagina_web          NVARCHAR(200)                   NULL,
        nombre_responsable  NVARCHAR(120)                   NOT NULL,
        cargo_responsable   NVARCHAR(100)                   NULL,
        telefono_responsable NVARCHAR(20)                   NULL,
        correo_responsable  NVARCHAR(150)                   NOT NULL,
        fecha_registro      DATETIME2       DEFAULT GETDATE() NOT NULL,
        activa              BIT             DEFAULT 1       NOT NULL,

        CONSTRAINT PK_empresas PRIMARY KEY (id_empresa)
    );
    PRINT 'Tabla empresas creada.';
END
GO

-- ── 7. Tabla: proyectos ──────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'proyectos')
BEGIN
    CREATE TABLE proyectos (
        id_proyecto         INT             IDENTITY(1,1)   NOT NULL,
        id_empresa          INT                             NOT NULL,   -- FK → empresas
        id_asesor           INT                             NULL,       -- FK → asesores (se asigna después)
        nombre              NVARCHAR(200)                   NOT NULL,
        descripcion         NVARCHAR(MAX)                   NOT NULL,
        area                NVARCHAR(100)                   NULL,
        requisitos          NVARCHAR(MAX)                   NULL,
        modalidad           NVARCHAR(20)                    NOT NULL
            CONSTRAINT CK_proyectos_modalidad CHECK (modalidad IN ('presencial', 'remoto', 'hibrido')),
        num_alumnos         INT             DEFAULT 1       NOT NULL,
        estado              NVARCHAR(20)    DEFAULT 'revision' NOT NULL
            CONSTRAINT CK_proyectos_estado CHECK (estado IN ('revision', 'publicado', 'cerrado', 'despublicado')),
        fecha_creacion      DATETIME2       DEFAULT GETDATE() NOT NULL,

        CONSTRAINT PK_proyectos         PRIMARY KEY (id_proyecto),
        CONSTRAINT FK_proy_empresa      FOREIGN KEY (id_empresa)
            REFERENCES empresas(id_empresa),
        CONSTRAINT FK_proy_asesor       FOREIGN KEY (id_asesor)
            REFERENCES asesores(id_asesor)
    );
    PRINT 'Tabla proyectos creada.';
END
GO

-- ── 8. Tabla: postulaciones ──────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'postulaciones')
BEGIN
    CREATE TABLE postulaciones (
        id_postulacion      INT             IDENTITY(1,1)   NOT NULL,
        id_alumno           INT                             NOT NULL,   -- FK → alumnos
        id_proyecto         INT                             NOT NULL,   -- FK → proyectos
        estado              NVARCHAR(20)    DEFAULT 'pendiente' NOT NULL
            CONSTRAINT CK_post_estado CHECK (estado IN ('pendiente', 'aceptada', 'rechazada')),
        correo_enviado      BIT             DEFAULT 0       NOT NULL,  -- ¿se mandó el mail a la empresa?
        fecha_postulacion   DATETIME2       DEFAULT GETDATE() NOT NULL,

        CONSTRAINT PK_postulaciones     PRIMARY KEY (id_postulacion),
        CONSTRAINT FK_post_alumno       FOREIGN KEY (id_alumno)
            REFERENCES alumnos(id_alumno),
        CONSTRAINT FK_post_proyecto     FOREIGN KEY (id_proyecto)
            REFERENCES proyectos(id_proyecto),
        -- Un alumno no puede postularse dos veces al mismo proyecto
        CONSTRAINT UQ_post_alumno_proy  UNIQUE (id_alumno, id_proyecto)
    );
    PRINT 'Tabla postulaciones creada.';
END
GO

-- ── 9. Tabla: anteproyectos ──────────────────────────────────
-- Nuevo en el flujo: el alumno sube esto DESPUÉS de que la empresa acepta.
-- El admin lo revisa y, si lo aprueba, asigna el asesor.
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'anteproyectos')
BEGIN
    CREATE TABLE anteproyectos (
        id_anteproyecto     INT             IDENTITY(1,1)   NOT NULL,
        id_postulacion      INT                             NOT NULL,   -- FK → postulaciones (1:1)
        titulo              NVARCHAR(200)                   NOT NULL,
        descripcion         NVARCHAR(MAX)                   NULL,
        ruta_archivo        NVARCHAR(500)                   NOT NULL,   -- ruta del PDF en el servidor
        estado              NVARCHAR(20)    DEFAULT 'pendiente' NOT NULL
            CONSTRAINT CK_antep_estado CHECK (estado IN ('pendiente', 'aprobado', 'rechazado')),
        comentario_admin    NVARCHAR(MAX)                   NULL,       -- nota del admin al revisar
        fecha_envio         DATETIME2       DEFAULT GETDATE() NOT NULL,
        fecha_revision      DATETIME2                       NULL,

        CONSTRAINT PK_anteproyectos     PRIMARY KEY (id_anteproyecto),
        CONSTRAINT FK_antep_post        FOREIGN KEY (id_postulacion)
            REFERENCES postulaciones(id_postulacion),
        CONSTRAINT UQ_antep_post        UNIQUE (id_postulacion)        -- 1 anteproyecto por postulación
    );
    PRINT 'Tabla anteproyectos creada.';
END
GO

-- ── 10. Tabla: reportes ──────────────────────────────────────
-- Solo disponibles una vez que el alumno tiene asesor asignado.
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'reportes')
BEGIN
    CREATE TABLE reportes (
        id_reporte          INT             IDENTITY(1,1)   NOT NULL,
        id_alumno           INT                             NOT NULL,   -- FK → alumnos
        id_proyecto         INT                             NOT NULL,   -- FK → proyectos
        numero_reporte      INT                             NOT NULL,   -- 1, 2, 3...
        titulo              NVARCHAR(200)                   NOT NULL,
        descripcion         NVARCHAR(MAX)                   NULL,
        periodo_inicio      DATE                            NOT NULL,
        periodo_fin         DATE                            NOT NULL,
        ruta_archivo        NVARCHAR(500)                   NOT NULL,
        estado              NVARCHAR(20)    DEFAULT 'enviado' NOT NULL
            CONSTRAINT CK_rep_estado CHECK (estado IN ('enviado', 'revisado', 'con_observaciones')),
        comentario_asesor   NVARCHAR(MAX)                   NULL,
        fecha_envio         DATETIME2       DEFAULT GETDATE() NOT NULL,

        CONSTRAINT PK_reportes          PRIMARY KEY (id_reporte),
        CONSTRAINT FK_rep_alumno        FOREIGN KEY (id_alumno)
            REFERENCES alumnos(id_alumno),
        CONSTRAINT FK_rep_proyecto      FOREIGN KEY (id_proyecto)
            REFERENCES proyectos(id_proyecto)
    );
    PRINT 'Tabla reportes creada.';
END
GO

-- ── 11. Tabla: evaluaciones ──────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'evaluaciones')
BEGIN
    CREATE TABLE evaluaciones (
        id_evaluacion       INT             IDENTITY(1,1)   NOT NULL,
        id_alumno           INT                             NOT NULL,   -- FK → alumnos
        id_asesor           INT                             NOT NULL,   -- FK → asesores
        id_proyecto         INT                             NOT NULL,   -- FK → proyectos
        tipo                NVARCHAR(20)                    NOT NULL
            CONSTRAINT CK_eval_tipo CHECK (tipo IN ('parcial', 'final')),
        calificacion        DECIMAL(4, 1)                   NOT NULL
            CONSTRAINT CK_eval_cal CHECK (calificacion BETWEEN 0 AND 10),
        comentarios         NVARCHAR(MAX)                   NULL,
        periodo_evaluado    NVARCHAR(100)                   NULL,
        fecha_evaluacion    DATETIME2       DEFAULT GETDATE() NOT NULL,

        CONSTRAINT PK_evaluaciones      PRIMARY KEY (id_evaluacion),
        CONSTRAINT FK_eval_alumno       FOREIGN KEY (id_alumno)
            REFERENCES alumnos(id_alumno),
        CONSTRAINT FK_eval_asesor       FOREIGN KEY (id_asesor)
            REFERENCES asesores(id_asesor),
        CONSTRAINT FK_eval_proyecto     FOREIGN KEY (id_proyecto)
            REFERENCES proyectos(id_proyecto)
    );
    PRINT 'Tabla evaluaciones creada.';
END
GO

-- ── 12. Tabla: notificaciones ────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'notificaciones')
BEGIN
    CREATE TABLE notificaciones (
        id_notificacion     INT             IDENTITY(1,1)   NOT NULL,
        id_usuario          INT                             NOT NULL,   -- FK → usuarios (destinatario)
        tipo                NVARCHAR(50)                    NOT NULL,
            -- 'postulacion_registrada' | 'empresa_acepto' | 'empresa_rechazo' |
            -- 'anteproyecto_aprobado' | 'anteproyecto_rechazado' | 'asesor_asignado' |
            -- 'reporte_revisado' | 'evaluacion_recibida'
        mensaje             NVARCHAR(500)                   NOT NULL,
        leida               BIT             DEFAULT 0       NOT NULL,
        fecha               DATETIME2       DEFAULT GETDATE() NOT NULL,

        CONSTRAINT PK_notificaciones    PRIMARY KEY (id_notificacion),
        CONSTRAINT FK_notif_usuario     FOREIGN KEY (id_usuario)
            REFERENCES usuarios(id_usuario)
            ON DELETE CASCADE
    );
    PRINT 'Tabla notificaciones creada.';
END
GO

-- ── 13. Índices para mejorar rendimiento en consultas comunes ─
-- (SSMS los muestra en el árbol de la tabla → Indexes)

CREATE INDEX IX_postulaciones_alumno
    ON postulaciones(id_alumno);

CREATE INDEX IX_postulaciones_proyecto
    ON postulaciones(id_proyecto);

CREATE INDEX IX_reportes_alumno
    ON reportes(id_alumno);

CREATE INDEX IX_evaluaciones_alumno
    ON evaluaciones(id_alumno);

CREATE INDEX IX_notificaciones_usuario_leida
    ON notificaciones(id_usuario, leida);

CREATE INDEX IX_proyectos_estado
    ON proyectos(estado);

PRINT '================================================';
PRINT 'Script 01 completado exitosamente.';
PRINT 'Tablas creadas: usuarios, alumnos, asesores,';
PRINT '  administradores, empresas, proyectos,';
PRINT '  postulaciones, anteproyectos, reportes,';
PRINT '  evaluaciones, notificaciones.';
PRINT '================================================';
GO
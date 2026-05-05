# SIGERP - Frontend App Alumno (Flutter)

## Estructura del proyecto

```
lib/
├── main.dart                    # Entry point + AuthGate
├── utils/
│   └── theme.dart               # Colores, estilos, tema global
├── services/
│   ├── api_service.dart         # Todas las llamadas HTTP al backend
│   └── auth_provider.dart       # Estado de sesión (Provider)
├── widgets/
│   └── common_widgets.dart      # Widgets reutilizables
└── screens/
    ├── login_screen.dart        # Pantalla de inicio de sesión
    ├── register_screen.dart     # Crear cuenta
    ├── main_shell.dart          # Navegación inferior (4 tabs)
    ├── home_screen.dart         # Inicio / Dashboard
    ├── proyectos_screen.dart    # Catálogo + Detalle + Postular
    ├── tramites_screen.dart     # Postulaciones / Anteproyecto / Reportes / Evaluaciones
    └── perfil_screen.dart       # Perfil + Cerrar sesión
```

## Configuración inicial

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Configurar la URL del backend

En `lib/services/api_service.dart`, línea ~9:

```dart
// Emulador Android (usa la IP especial del host):
static const String baseUrl = 'http://10.0.2.2:3000/api';

// Dispositivo físico (usa la IP local de tu PC):
static const String baseUrl = 'http://192.168.X.X:3000/api';

// iOS Simulator:
static const String baseUrl = 'http://localhost:3000/api';
```

### 3. Arrancar el backend

```bash
cd SIGERP/backend
node src/app.js
```

Asegúrate de que el archivo `.env` tenga los datos correctos de SQL Server.

### 4. Permisos en Android

En `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Para HTTP (no HTTPS) en desarrollo, dentro de `<application>`:
```xml
android:usesCleartextTraffic="true"
```

### 5. Ejecutar la app

```bash
flutter run
```

---

## Pantallas implementadas

| Pantalla | Descripción | API usada |
|---|---|---|
| Login | Inicio de sesión con correo/contraseña | `POST /api/usuarios/login` |
| Registro | Crear cuenta de alumno | `POST /api/usuarios/registro` |
| Inicio | Dashboard con proyecto activo y accesos rápidos | `GET /api/usuarios/perfil`, `GET /api/postulaciones/mis` |
| Proyectos | Catálogo filtrable con búsqueda | `GET /api/proyectos` |
| Detalle proyecto | Info completa + botón postularse | `POST /api/postulaciones` |
| Trámites > Postulaciones | Estado de mis postulaciones | `GET /api/postulaciones/mis` |
| Trámites > Anteproyecto | Subir archivo PDF/DOCX | `POST /api/anteproyectos` |
| Trámites > Reportes | Subir reportes de avance | `POST /api/reportes` |
| Trámites > Evaluaciones | Ver calificaciones del asesor | `GET /api/evaluaciones/mis` |
| Perfil | Datos del alumno + logout | `GET /api/usuarios/perfil` |

---

## Notas de desarrollo

- El token JWT se guarda en `SharedPreferences` y se carga automáticamente al iniciar la app.
- Al abrir la app, si hay sesión guardada, va directo al Dashboard.
- El tema es completamente oscuro (dark mode), siguiendo los prototipos.
- Colores principales: `#00D084` (verde) y `#58A6FF` (azul de empresa).

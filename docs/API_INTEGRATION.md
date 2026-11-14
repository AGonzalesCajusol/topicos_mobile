# Integración móvil con el backend Laravel

Repositorio backend revisado: `ErickCJS/project-topicos` (rama `main`).
Este documento describe únicamente rutas y comportamientos existentes; no se modificó el backend.

## Hallazgos confirmados

### Autenticación y marcación de asistencia

- Ruta web: `POST /employee/login`.
- Controlador: `EmployeeAttendanceController@authenticate`.
- Campos: `dni` (8 dígitos), `password`, `shift_id` opcional.
- Respuesta JSON de éxito: `message`, `type` (Entrada/Salida), `shift_id`, `shift_name`, `status`.
- Importante: esta acción registra una entrada o salida de asistencia. No crea una sesión/token de autenticación móvil. No debe invocarse como un login de app porque podría marcar asistencia al conductor.

### API actual

- `GET /api/user` está protegido por `auth:sanctum`.
- En `routes/api.php` no se encontró endpoint de login, programaciones del conductor, asistencias consultables desde móvil ni recorridos/GPS.

### Programaciones existentes

Las rutas de programación están registradas bajo el prefijo `/admin` y el middleware `web, auth`. Entre ellas:
- `GET /admin/programming`
- `GET /admin/programming/{programming}`
- `GET /admin/programming/{id}/history`

Aunque algunas respuestas son JSON cuando se solicita, son rutas administrativas protegidas por sesión web, no endpoints móviles autenticados.

## Estado de integración

La pantalla Flutter ahora solicita DNI de 8 dígitos, alineándose con el identificador que usa el backend. El botón no envía credenciales ni simula un inicio de sesión exitoso: muestra un aviso porque no existe un flujo de autenticación móvil seguro en las rutas actuales.

Para conectar las funciones reales sin cambiar el backend, se necesita que el backend ya exponga endpoints móviles compatibles con Sanctum (login/token y recursos del conductor). No se deben reutilizar rutas administrativas ni el endpoint que marca asistencia como autenticación.

## Funciones del avance 06 pendientes de API

- Listar programaciones asignadas al conductor autenticado.
- Consultar programaciones del día.
- Consultar/validar asistencias vinculadas a una programación.
- Iniciar recorrido y registrar coordenadas GPS cada 5 segundos.
- Finalizar recorrido con observaciones.
- Consultar historial y puntos de trayectoria.

No se inventaron rutas ni payloads para estas funciones.

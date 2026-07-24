# PituApp — PetBienestar

Aplicación Flutter para la **gestión del cuidado y la salud de mascotas**
(local-first, Fase 1 / MVP). *El cuidado de tu mascota, siempre al día.*

> Homenaje interno: la mascota de ejemplo se llama Pitufo. 🐾

## Arquitectura

Clean Architecture por feature, con patrón repositorio, para que el dominio no
dependa de la fuente de datos y la Fase 2 (backend Spring Boot + PostgreSQL)
consista en cambiar la implementación de los repositorios (ERS §8.3).

```
lib/
├── core/                     # Transversal
│   ├── domain/               # SyncMetadata (UUID, timestamps, borrado lógico — RD-18)
│   ├── data/                 # Base in-memory (stub de Drift) + seed
│   ├── di/                   # Composición de dependencias (Riverpod)
│   ├── theme/                # Tokens de diseño (colores, tipografía, formas)
│   ├── utils/                # Reloj, generador de UUID, fechas
│   └── widgets/              # Componentes del sistema de diseño
└── features/
    ├── pets/                 # Mascotas (dominio · datos · presentación)
    ├── care/                 # Catálogo, programación y cumplimiento
    ├── clinical/             # Historial: visitas, vacunas, diagnósticos, peso
    ├── plan/                 # Planes Free / Pro (entitlement, paywall)
    ├── dashboard/            # Inicio
    ├── calendar/             # Calendario
    ├── settings/             # Ajustes
    └── shell/                # Navegación principal (bottom nav + FAB)
```

**Decisiones clave**
- **Estado / DI:** Riverpod (lógica de negocio fuera de la UI).
- **RD-18 desde el día 1:** UUID de cliente, `created_at`/`updated_at`,
  `created_by` reservado y borrado lógico en todas las entidades.
- **Persistencia:** implementación in-memory reactiva en el MVP (se despliega a
  web para revisión); Drift/SQLite cifrado entra después como otra
  implementación del mismo contrato, sin tocar dominio.
- **Diseño:** tokens 1:1 del entregable de Identidad Visual (teal petróleo
  "cálido sereno", tipografía Nunito, semánticos verde/ámbar/rojo). Ver
  `design/` para la identidad y el prototipo de referencia.

## Funciones implementadas (iteración 1)

- Inicio con saludo, filtro por mascota, panel de cumplimiento (Pro) y tareas
  de hoy / próximos 7 días.
- Alta de mascota con **precarga del plan de cuidados por especie**.
- Marcar cuidado como hecho con **recálculo de próxima fecha** y deshacer.
- Detalle de mascota (Resumen · Cuidados · Historial · Docs) con semáforo de
  cumplimiento, condiciones activas, próximas tareas y curva de peso.
- Calendario (vista de lista por cercanía).
- Planes Free / Pro (paywall honesto, "pago único · para siempre").
- Ajustes con perfil, suscripción, notificaciones, seguridad, datos y
  privacidad. Tema claro/oscuro según el sistema.

## Ejecutar

```bash
flutter pub get
flutter run          # móvil o web
flutter test         # pruebas de dominio
```

## Despliegue

Cada push a `main` compila la app para web y la publica en GitHub Pages:
**https://yesithv.github.io/pitu-app/** (ver `.github/workflows/deploy.yml`).

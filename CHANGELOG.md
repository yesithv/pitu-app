# Registro de cambios (Changelog)

Todos los cambios notables de **PituApp — PetBienestar** se documentan en este
archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el
proyecto se adhiere a [Versionado Semántico](https://semver.org/lang/es/) (SemVer).

## Política de versionado

La versión canónica vive en `pubspec.yaml` con el formato `MAYOR.MENOR.PARCHE+BUILD`
(p. ej. `0.1.0+1`):

- **MAYOR** — cambios incompatibles hacia atrás (formato de datos, contrato de API
  de la Fase 2, migraciones destructivas).
- **MENOR** — funcionalidad nueva compatible hacia atrás (nuevos RF).
- **PARCHE** — correcciones compatibles hacia atrás.
- **BUILD** (`+N`) — el `versionCode` de Android. **Debe incrementarse en cada
  subida a Google Play**, aunque no cambie el nombre de versión. En los builds de
  release lo inyecta CI automáticamente con `--build-number` (ver más abajo), de
  modo que dos artefactos nunca comparten `versionCode`.

### Tags y releases

Cada versión publicada se marca con un tag Git `vMAYOR.MENOR.PARCHE` (p. ej.
`v0.1.0`). Al empujar un tag `v*`, el workflow `.github/workflows/release.yml`
compila el App Bundle con un `versionCode` incremental (derivado del número de
corrida de CI) y publica el `.aab` como artefacto. El nombre de versión se toma de
`pubspec.yaml`; el `versionCode` lo fija CI. Ver `docs/RELEASE_ANDROID.md`.

> Convención de mensajes de commit: se recomienda
> [Conventional Commits](https://www.conventionalcommits.org/es/) (`feat:`, `fix:`,
> `docs:`, `test:`, `chore:`, `refactor:`), como ya se practica en el historial.

---

## [Sin publicar]

### Añadido
- `CHANGELOG.md` con política de versionado (SemVer) y convención de tags.
- Workflow `release.yml`: compila el AAB en cada tag `v*` con `versionCode`
  incremental inyectado por CI.
- `LICENSE` y `CONTRIBUTING.md`.
- `docs/DEMO_ENFOQUE.md`: enfoque del demo (mostrar funcionalidades, no solo datos)
  y diferenciación Pro vs. Free.
- Reglas de lint explícitas en `analysis_options.yaml`.
- Pruebas de widget (login, paywall, formularios) y de cumplimiento con estados
  mixtos.

### Cambiado
- El CI de Android (`android.yml`) compila con `--build-number` incremental para
  ejercitar el mismo camino de versionado que el release.
- Toolchain de Android al día con Flutter stable: Gradle 8.14 (wrapper), Android
  Gradle Plugin 8.11.1 y Kotlin 2.2.20, mínimos exigidos por la versión actual de
  Flutter.
- README: la matriz de estado por requisito (RF) deja de duplicarse; ahora vive
  solo en `docs/ESTADO_MVP.md` (fuente única de verdad), y el README enlaza a ella.
- Documentado en código el límite de escala esperado del modelo en memoria
  (`InMemoryDatabase`).

---

## [0.1.0] — 2026-08-08

Primera línea base del MVP (Fase 1, local-first). Todos los requisitos funcionales
de Fase 1 (RF-01–50) implementados en código. Detalle y trazabilidad por requisito
en `docs/ESTADO_MVP.md`.

### Añadido
- Gestión de mascotas (crear/editar/archivar/desarchivar/eliminar) con foto.
- Catálogo de cuidados por especie, programación, cálculo de próxima fecha y
  cumplimiento (semáforo e indicador por mascota).
- Historial clínico: visitas, vacunas (con próxima dosis), diagnósticos con estado,
  registro de peso con aviso de variación (>10%) y línea de tiempo con filtros.
- Documentos adjuntos con compresión de imágenes.
- Recordatorios y notificaciones locales (móvil), con reprogramación tras
  reinstalar/restaurar y alarmas exactas en Android.
- Reporte PDF para el veterinario (función Pro) y resumen de cumplimiento.
- Respaldo/restauración (exportar gratis, combinar por UUID) y portabilidad.
- Planes Free/Pro con compras in-app y entitlement persistido.
- Persistencia cifrada (SQLCipher + llavero del SO) en móvil y snapshot en web.
- Bloqueo biométrico opcional, perfil local editable, tema claro/oscuro e i18n
  (es, en, fr, pt, de).

[Sin publicar]: https://github.com/yesithv/pitu-app/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yesithv/pitu-app/releases/tag/v0.1.0

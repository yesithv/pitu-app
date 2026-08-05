# Resumen de avance — Preparación para producción

_Ramas: `claude/prod-readiness-requirements-g23s9m` (fases 1–4) y
`claude/app-prod-review-next-317lxl` (fase 5) · Última actualización: 2026-08-05._

Documento de estado del trabajo hecho para acercar PituApp a producción, con lo
completado y lo que queda pendiente. Es una **bitácora histórica**; para el estado
vigente ver los documentos canónicos:

- **`docs/ESTADO_MVP.md`** — estado funcional del MVP (RF/RNF) y qué falta.
- **`docs/ROADMAP_V2.md`** — todo lo de la Fase 2.
- **`docs/WEB_IRONCODING.md`** — ficha de producto para la web/tienda (copiar/pegar).
- **`docs/PRODUCCION_PENDIENTES.md`** — guía técnica de publicación.

---

## 1. Qué se hizo (por fases)

Todo el trabajo está en la rama indicada, con **CI en verde** en cada paso
(`flutter analyze --fatal-infos` + `flutter test`).

### Fase 1 — Arrancar en Free + auto-restore (#2) + documentación
Commit `1906916`.
- **Flag de modo demo** `kDemoMode` (`lib/core/config/app_config.dart`):
  `bool.fromEnvironment('PITU_DEMO', defaultValue: kDebugMode)`. Separa **demo**
  (Pro, para exhibir/probar) de **producción** (Free).
- **Seed** (`lib/core/data/seed.dart`): los datos de ejemplo (Firulais/Luna) se
  siembran siempre; solo el *grant* de Pro y el nombre del dueño quedan tras el
  flag. Producción arranca en **Free** con datos de ejemplo.
- **Códec** (`lib/core/data/db_codec.dart`): un snapshot sin `planType` decodifica
  **Free** (antes Pro), para no regalar Pro por omisión.
- **Auto-restore** (`lib/features/plan/presentation/entitlement_sync.dart`): al
  inicio, en segundo plano y **solo si el plan es Free**, intenta restaurar la
  compra (upgrade-only, no molesta a quien ya es Pro; no-op en web).
- **Gating de demo**: el conmutador de plan de Ajustes y el desbloqueo sin tienda
  solo existen en modo demo.
- **CI web** (`deploy.yml`): la demo pública se compila con
  `--dart-define=PITU_DEMO=true` para seguir mostrando Pro.
- **Documentación**: `docs/PRODUCCION_PENDIENTES.md` con los 8 pendientes.

### Fase 2 — Gate de CI (#6) + cobertura de pruebas (#5)
Commits `5f25d50`, `64c9650`.
- **`.github/workflows/ci.yml`**: corre en PR y push a ramas de trabajo
  (`flutter pub get` → `analyze` → `test`). Antes la CI **solo desplegaba** web.
- **Pruebas** de lógica pura: `db_codec` (round-trip + versión), `backup`
  (export, validación de import, replace/combine por UUID), `scheduling`
  (ventana, etiquetas, bordes) y `plan` (límites Free/Pro).

### Fase 3 — Huecos de spec (#7): RF-15/26 + RF-21
Commit `4e695d2`.
- **RF-15/26**: `CareRegisterScreen` permite **adjuntar documentos** al registrar
  un cuidado (reutiliza `AttachmentAddButton`).
- **RF-21**: cada **cambio de estado de un diagnóstico** se registra como entrada
  propia del historial (`DiagnosisStatusChange`, esquema v4 retrocompatible), con
  su entrada en la línea de tiempo.

### Fase 3.5 — Saldar deuda de lint + gate estricto
Commit `8df792a`.
- Corregidos ~35 avisos: `withOpacity`→`withValues`, `activeColor`→
  `activeThumbColor`, guards `context.mounted` en gaps async, `prefer_const`, y
  `dart:html` (web) silenciado de forma acotada.
- Gate endurecido a **`flutter analyze --fatal-infos`**: no reacumula deuda.

### Fase 4 — Privacidad + crash reporting (#8) + catálogo (RF-13)
Commit `8825571`.
- **Privacidad**: `docs/PRIVACIDAD.md` (política local-first).
- **Crash reporting (scaffolding)**: `CrashReporter` + `NoopCrashReporter` +
  provider, cableado en `main` a `FlutterError.onError` y
  `platformDispatcher.onError`. Sin dependencias nuevas; listo para enchufar un
  backend real.
- **RF-13**: `CatalogUpdater` aplica de forma **aditiva e idempotente** los
  cuidados nuevos del catálogo a mascotas existentes sin sobrescribir
  personalizaciones (RN-09); persiste `catalogAppliedVersion` y reconcilia al
  arrancar.

### Fase 5 — Persistencia cifrada en reposo (#3, RNF-10)
Rama `claude/app-prod-review-next-317lxl`.
- **Móvil/escritorio**: base **SQLite cifrada con SQLCipher** (Drift), con la
  clave en el **llavero del SO** (`flutter_secure_storage`). **Web** conserva el
  snapshot en `localStorage` (sin llavero ni SQLCipher en el navegador).
- **Interfaz** `LocalPersistence` con dos implementaciones (`SnapshotPersistence`
  web / `DriftPersistence` móvil) elegidas por conditional import
  (`persistence_factory.dart`). Los consumidores (backup, adjuntos, DI) no
  cambian de forma.
- **Esquema** `(kind, id)` en `drift/app_database.dart`, adjuntos como BLOB fuera
  del JSON; se **reutiliza `DbCodec`** como formato de fila y respaldo.
- **Migración sin pérdida** del snapshot `v1` previo a la base cifrada al primer
  arranque. Codegen de Drift añadido a `ci.yml`.
- **Pruebas**: `drift_persistence_test.dart` (round-trip + BLOB) y
  `snapshot_migration_test.dart` (migración).
- **Pendiente**: validar en dispositivo (depende de #1/#4); follow-ups de
  escrituras incrementales y adjuntos al filesystem (RF-29).

---

## 2. Estado de los 8 pendientes de producción

| # | Pendiente | Estado |
|---|---|---|
| 1 | Proyectos nativos Android/iOS + firma | 🔴 pendiente (requiere `flutter create` + firma/tiendas) |
| 2 | Entitlement: arrancar en Free + auto-restore | ✅ hecho (falta validar en dispositivo) |
| 3 | Persistencia SQLite/Drift cifrada (RNF-10) | 🟠 hecho en código (Drift + SQLCipher); falta validar en dispositivo |
| 4 | Validación en dispositivo de funciones 📱 | 🔴 pendiente (requiere Android/iOS) |
| 5 | Cobertura de pruebas | ✅ hecho (base sólida; ampliable) |
| 6 | Gate de calidad en CI | ✅ hecho (estricto, `--fatal-infos`) |
| 7 | Huecos de spec | 🟠 RF-15/26, RF-21 y RF-13 hechos; **RF-33 y RF-35 pendientes** (móvil; ver `ESTADO_MVP.md`) |
| 8 | Publicación / cumplimiento | 🟠 privacidad (borrador) + crash scaffolding hechos; resto pendiente |
| — | Deuda de lint | ✅ saldada |

---

## 3. Qué queda pendiente

**Requieren dispositivos o cuentas de tienda (no cerrables solo en este entorno):**
- **#1** Generar y configurar los proyectos nativos Android/iOS (firma, permisos,
  iconos, `minSdk`/deployment target).
- **#3 (cierre)** Persistencia SQLite/Drift **cifrada** ya implementada (fase 5);
  falta **validar en dispositivo** que el `.sqlite` queda cifrado en reposo y que
  la migración del snapshot previo no pierde datos. Follow-up: separar adjuntos al
  filesystem (RF-29).
- **#4** Validar en dispositivo las funciones 📱 (recordatorios, biometría,
  compras, archivos nativos) — guía en `docs/PRUEBAS_EN_DISPOSITIVO.md`.
- **#2 (cierre)** Crear el producto `pituapp_pro_lifetime` en App Store Connect y
  Google Play y validar compra/restauración reales.
- **RF-33 / RF-35** Recordatorios fiables: fijar la zona horaria local + listeners
  de cambio, y alarmas exactas de Android con permiso (móvil).

**Se pueden hacer aquí más adelante:**
- **#8** Enchufar un backend real de crash reporting (Sentry/Crashlytics)
  reemplazando `createCrashReporter()`; completar el correo de contacto de
  `docs/PRIVACIDAD.md` y **alojarla en una URL pública**.
- Formularios de privacidad / Data Safety, capturas, descripción y clasificación
  por edad para las tiendas.
- Ampliar pruebas (widget-tests del paywall y flujos de UI).

---

## 4. Pruebas y CI

- **11 archivos de test** en `test/` (dominio, persistencia, respaldo, entitlement,
  scheduling, clínico, catálogo, crash reporter, y ahora Drift + migración del
  snapshot).
- CI (`ci.yml`) corre en cada PR/push a ramas de trabajo y **bloquea** ante
  errores, warnings e infos, además de fallos de test.
- La web (`deploy.yml`) sigue desplegándose a GitHub Pages en `main`, en modo demo
  (Pro) vía `--dart-define=PITU_DEMO=true`.

---

## 5. Commits de la rama

```
8825571  #8 privacidad + crash reporting scaffolding y RF-13 (catálogo aditivo)
8df792a  Saldar la deuda de lint y endurecer el gate a --fatal-infos
4e695d2  Cerrar huecos de spec #7: adjuntar desde cuidado (RF-15/26) y cambio de estado (RF-21)
64c9650  Poner verde la CI: limpiar warnings y no bloquear por infos
5f25d50  Añadir gate de CI (analyze + test) y ampliar cobertura de pruebas
1906916  Arrancar en Free en producción + auto-restore, y documentar pendientes
```

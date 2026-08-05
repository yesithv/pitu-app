# Pendientes para producción

Guía para otras sesiones sobre lo que falta para llevar **PituApp / PetBienestar**
de un MVP local-first (funcionalmente completo en web) a una app publicable en
tiendas. Cada ítem indica **estado**, **archivos afectados** y **cómo continuar**.

Leyenda de estado: 🔴 bloqueante · 🟠 riesgo de calidad · 🟢 deseable.

> **Fuente de verdad del estado funcional: `docs/ESTADO_MVP.md`.** Este documento
> es la guía técnica de *publicación*; el estado detallado RF/RNF vive en
> `ESTADO_MVP.md`, y la Fase 2 en `docs/ROADMAP_V2.md`.
>
> Última actualización: 2026-08-05.

---

## 1. Proyectos nativos Android/iOS — 🟠 Android en curso · iOS pendiente

**Android: ✅ creado.** Existe el proyecto `android/` versionado con
`applicationId = com.ironcoding.pituapp`, `minSdk 23`/`compileSdk 34`, permisos y
receivers de notificaciones en el manifiesto (RF-30..RF-35), `MainActivity` como
`FlutterFragmentActivity` (biometría), core library desugaring
(`flutter_local_notifications`) y firma vía `key.properties` con fallback a debug.
La CI `android.yml` **compila un APK debug** en cada PR para verificarlo.

Los binarios que no se versionan (`gradle-wrapper.jar`, iconos del launcher) se
restauran en CI/local (ver `docs/RELEASE_ANDROID.md`).

**Pendiente Android:**
- **Firma de release** (keystore del usuario) y generar el **AAB**
  (`flutter build appbundle --release`) — ver `docs/RELEASE_ANDROID.md`.
- **Iconos definitivos** con `flutter_launcher_icons` (hoy son los genéricos).
- **Validar en dispositivo** las funciones 📱 (ver #4).

**iOS: 🔴 pendiente** — `flutter create --platforms=ios .`, `bundleId`,
`Info.plist` (`NSFaceIDUsageDescription`), certificados y perfiles, deployment
target.

## 2. Entitlement de producción (arrancar en Free + auto-restore) — 🟠 EN CURSO

**Estado: implementado en la rama `claude/prod-readiness-requirements-g23s9m`.**
- Un flag de compilación `kDemoMode` (`lib/core/config/app_config.dart`) separa
  **demo** (Pro, para exhibir/probar) de **producción** (Free). En debug es
  `true`; en release de tienda es `false`; la demo web lo fuerza con
  `--dart-define=PITU_DEMO=true`.
- Los datos de ejemplo (Firulais/Luna) se siembran en todos los builds; solo el
  *grant* de Pro y el conmutador de plan de Ajustes quedan tras el flag
  (`lib/core/data/seed.dart`, `lib/features/settings/settings_screen.dart`).
- El códec ya no otorga Pro a snapshots sin `planType`
  (`lib/core/data/db_codec.dart`).
- Auto-restore al inicio, en segundo plano y solo si el plan es Free
  (`lib/features/plan/presentation/entitlement_sync.dart`), reutilizando
  `EntitlementController.unlockPro()`.

**Pendiente aquí:** crear el producto de compra `pituapp_pro_lifetime`
(`lib/features/purchases/domain/purchase_service.dart`) en App Store Connect y
Google Play Console, y **validar en dispositivo** el flujo de compra/restauración
(depende de #1 y #4).

## 3. Persistencia definitiva — SQLite/Drift cifrado (RNF-10) — 🟠 EN CURSO

**Estado: implementado en código; pendiente de validación en dispositivo (#4).**

En móvil/escritorio los datos residen ahora en una base **SQLite cifrada con
SQLCipher** (Drift), con la clave de 32 bytes guardada en el **llavero del SO**
(`flutter_secure_storage` → Android Keystore / iOS Keychain). La web conserva el
snapshot en `localStorage` (no hay llavero ni SQLCipher en el navegador); la
plataforma se elige con el patrón de factory por conditional import.

- **Interfaz común** `LocalPersistence` (`lib/core/data/local_persistence.dart`);
  dos implementaciones: `SnapshotPersistence` (web, `lib/core/data/persistence.dart`)
  y `DriftPersistence` (móvil, `lib/core/data/drift_persistence.dart`). El factory
  es `lib/core/data/persistence_factory.dart` (`persistence_stub.dart` /
  `persistence_io.dart`).
- **Esquema** en `lib/core/data/drift/app_database.dart` (una fila por entidad,
  clave `(kind, id)`); apertura cifrada en `drift/app_database_open.dart`
  (`PRAGMA key`). El **códec JSON** (`db_codec.dart`) se reutiliza como formato de
  fila y de respaldo, así que no se duplica el mapeo de dominio.
- **Migración sin pérdida**: al arrancar por primera vez el build cifrado, si hay
  un snapshot `pituapp.snapshot.v1` previo, se vuelca a la base. Cubierto por
  `test/snapshot_migration_test.dart` y `test/drift_persistence_test.dart`.
- **Codegen**: Drift genera `*.g.dart` con `build_runner` (paso añadido a
  `ci.yml`); no se versiona.

**Pendiente aquí:**
- **Validar en dispositivo** (depende de #1 y #4): crear datos, cerrar/abrir la
  app, y confirmar que el archivo `.sqlite` está cifrado en reposo (no legible en
  claro) y que un usuario con snapshot previo migra sin pérdida.
- **Follow-ups** (fuera de este alcance): escrituras **incrementales** por entidad
  en vez del reemplazo transaccional completo, y separar los adjuntos al
  filesystem guardando solo la referencia (**RF-29**).

## 4. Validación en dispositivo de funciones móviles — 🔴

Las funciones marcadas 📱 (recordatorios locales, biometría, compras in-app,
guardar/seleccionar archivos nativos) están implementadas con aislamiento por
plataforma (conditional imports) pero **no se han probado en Android/iOS**.

**Cómo continuar:** seguir la guía `docs/PRUEBAS_EN_DISPOSITIVO.md` una vez
existan los proyectos nativos (#1).

## 5. Pruebas automatizadas — 🟠

Cobertura mínima: `test/widget_test.dart` (dominio de scheduling) y
`test/entitlement_seed_test.dart` (seed Free/Pro y fallback del códec, añadido en
esta rama).

**Cómo continuar:** cubrir persistencia/backup round-trip (`db_codec`,
`backup_service`), import/merge por UUID, cálculo de próximas fechas, cumplimiento
y paywall; añadir pruebas de widget de los flujos principales.

## 6. Gate de calidad en CI — ✅ hecho

`.github/workflows/ci.yml` corre en cada Pull Request y push a ramas de trabajo:
`flutter pub get` → `flutter analyze --fatal-infos` → `flutter test`. La deuda de
lint preexistente se saldó y el gate ahora falla ante errores, warnings **e
infos** (los avisos inherentes, como `dart:html` del import web condicional, se
silencian de forma acotada en su archivo).

**Posible mejora:** añadir también un build Android/iOS al gate cuando existan los
proyectos nativos (ver #1).

## 7. Huecos del spec — 🔴 recordatorios / 🟠 resto

Detalle y severidad en `docs/ESTADO_MVP.md` §4. Resumen:

- **RF-13:** ✅ hecho — `CatalogUpdater` aditivo e idempotente
  (`lib/features/care/application/catalog_updater.dart`, RN-09).
- **RF-15 / RF-26:** ✅ hecho — adjuntar documentos desde el registro de un cuidado
  (`lib/features/care/presentation/care_register_screen.dart` reutiliza
  `AttachmentAddButton`).
- **RF-21:** ✅ hecho — el cambio de estado de un diagnóstico se registra como
  entrada propia del historial (`DiagnosisStatusChange` +
  `lib/features/clinical/data/clinical_repository_impl.dart`; esquema v4).
- **RF-33:** ✅ hecho (en código) — se fija la zona horaria local del dispositivo
  (`flutter_timezone` + `tz.setLocalLocation`) y se reprograma al reanudar si cambió
  (observer en `lib/main.dart`). Pendiente: validar en dispositivo (#4).
- **RF-35:** ✅ hecho (en código) — se pide `SCHEDULE_EXACT_ALARM` (declarado en el
  manifiesto) y se usa `exactAllowWhileIdle` cuando está concedido, degradando a
  inexacto si no. Pendiente: validar en dispositivo (#4).
- **RF-29 / RNF-04:** ✅ hecho (en código) — adjuntos en el filesystem
  (`AttachmentFileStore`); la fila Drift guarda la ruta. Web sigue con snapshot.
  Pendiente: validar en dispositivo (#4).
- **RNF-06 / RNF-13:** ✅ hecho — espacio ocupado por documentos y "Borrar todos
  mis datos" (doble confirmación) en Ajustes → Datos.

## 8. Publicación y cumplimiento — 🟠 (parcialmente hecho)

- **Política de privacidad**: ✅ borrador en `docs/PRIVACIDAD.md` (local-first).
  Pendiente: completar el correo de contacto (**será `yesithvalencia@gmail.com`**)
  y **alojarla en una URL pública** (requisito de App Store y Google Play).
- **Observabilidad**: ✅ scaffolding de crash reporting montado
  (`lib/core/observability/crash_reporter.dart` + `crash_reporter_providers.dart`,
  cableado en `main.dart` a `FlutterError.onError` y `platformDispatcher.onError`).
  Hoy es no-op; pendiente enchufar un backend real (Sentry/Crashlytics)
  reemplazando `createCrashReporter()` y añadiendo la dependencia.
- Pendiente (no-código): formularios de privacidad / Data Safety en ambas
  tiendas, capturas, descripción, clasificación por edad y cuentas de
  desarrollador.

---

## Fuera del alcance de la Fase 1 (van en Fase 2)

Cuenta de usuario, hogar compartido, sincronización en la nube, multi-dispositivo,
plan Premium (suscripción) y link de solo lectura para el veterinario.

# Pendientes para producción

Guía para otras sesiones sobre lo que falta para llevar **PituApp / PetBienestar**
de un MVP local-first (funcionalmente completo en web) a una app publicable en
tiendas. Cada ítem indica **estado**, **archivos afectados** y **cómo continuar**.

Leyenda de estado: 🔴 bloqueante · 🟠 riesgo de calidad · 🟢 deseable.

> Última actualización: 2026-08-01.

---

## 1. Proyectos nativos Android/iOS — 🔴

El repo solo contiene `lib/`, `test/`, `pubspec.yaml`, etc. **No existen las
carpetas `android/` ni `ios/`.** La CI (`.github/workflows/deploy.yml`) genera la
plataforma **web** al vuelo con `flutter create --platforms=web`, por lo que
nunca se han construido los proyectos nativos.

**Cómo continuar:**
- `flutter create --platforms=android,ios .` para generar los proyectos.
- Configurar `applicationId` / `bundleId`, iconos y splash, versión/build.
- Firma: keystore de Android; certificados y perfiles de aprovisionamiento iOS.
- Permisos: `AndroidManifest.xml` e `Info.plist` (notificaciones locales,
  `NSFaceIDUsageDescription` para biometría, alarmas exactas en Android 13+),
  `minSdkVersion` y deployment target.
- Ninguna función marcada 📱 se ha ejecutado en un dispositivo real (ver #4).

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

## 3. Persistencia definitiva — SQLite/Drift cifrado (RNF-10) — 🔴

Hoy se guarda un **snapshot JSON completo** en `shared_preferences`
(`lib/core/data/persistence.dart`, clave `pituapp.snapshot.v1`), reserializado en
cada cambio, con los adjuntos embebidos en base64. **No está cifrado en reposo**
y no escala.

**Cómo continuar:** implementar una capa de repositorio sobre Drift/SQLite con
cifrado vía el llavero del SO (Keychain/Keystore) y separar los adjuntos al
filesystem (RF-29). Gracias al patrón repositorio, se cambia solo la capa de
datos sin tocar dominio ni pantallas.

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

## 7. Huecos del spec (menores) — 🟢

- **RF-15 / RF-26:** ✅ hecho — adjuntar documentos desde el registro de un cuidado
  (`lib/features/care/presentation/care_register_screen.dart` reutiliza
  `AttachmentAddButton`).
- **RF-21:** ✅ hecho — el cambio de estado de un diagnóstico se registra como
  entrada propia del historial (`DiagnosisStatusChange` +
  `lib/features/clinical/data/clinical_repository_impl.dart`; esquema v4).
- **RF-13:** ⏳ pendiente — lógica de actualización de catálogo versionado sin
  sobrescribir personalizaciones (`lib/features/care/data/care_catalog.dart`).
  Bajo valor hasta publicar updates de catálogo.
- **RF-33:** ⏳ pendiente — listeners de zona horaria para reprogramar
  recordatorios (`lib/features/reminders/`). Solo móvil; validar en dispositivo.

## 8. Publicación y cumplimiento — 🟠 (parcialmente hecho)

- **Política de privacidad**: ✅ borrador en `docs/PRIVACIDAD.md` (local-first).
  Pendiente: completar el correo de contacto y **alojarla en una URL pública**
  (requisito de App Store y Google Play).
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

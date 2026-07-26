# Guía de pruebas en dispositivo — PituApp

Todo lo probable en el navegador ya está validado en
https://yesithv.github.io/pitu-app/. Esta guía cubre **lo que solo se puede
verificar en un móvil real** y cómo dejar el proyecto listo para hacerlo.

## 1. Qué falta validar en móvil

Estas funciones están construidas con aislamiento por plataforma (*conditional
imports*): en web son no-op y en móvil usan el plugin real. No se rompen el
build web, pero **su comportamiento real solo se ve en Android/iOS**:

| Función | Plugin | Dónde probar |
|---|---|---|
| Recordatorios locales | `flutter_local_notifications` + `timezone` | Ajustes → Notificaciones |
| Bloqueo biométrico | `local_auth` | Ajustes → Seguridad |
| Adjuntar / guardar archivos | `dart:io` (foto/PDF) | Detalle de mascota → Docs |
| Compras Pro (pago único) | `in_app_purchase` | Paywall (Ajustes → Suscripción) |

## 2. Requisitos

- Flutter SDK (canal `stable`) instalado localmente.
- Android Studio (Android) y/o Xcode (iOS).
- Un **dispositivo físico** (recomendado para biometría y notificaciones) o
  emulador/simulador.

## 3. Generar las plataformas nativas

El repositorio solo versiona el código de la app; las carpetas de plataforma se
generan (el CI crea `web/` en cada build). Para móvil, en la raíz del proyecto:

```bash
flutter create --platforms=android,ios --project-name pitu_app .
flutter pub get
```

Esto crea `android/` e `ios/` sin tocar `lib/`. No hace falta subirlas al repo:
el despliegue web no las necesita.

## 4. Configuración necesaria por plugin

### 4.1 Notificaciones
- **Android 13+**: la app ya solicita el permiso `POST_NOTIFICATIONS`
  (`requestPermission` al activar el switch). Para alarmas exactas, en
  `android/app/src/main/AndroidManifest.xml` añade dentro de `<manifest>`:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  ```
  Sigue el README de `flutter_local_notifications` si necesitas los *receivers*
  para reprogramar tras reinicio.
- **iOS**: el plugin solicita el permiso en tiempo de ejecución; no requiere
  clave adicional en `Info.plist` para notificaciones locales.
- La zona horaria ya se inicializa en el arranque (`timezone`).
- Los recordatorios se agendan a las **9:00** del día correspondiente, dentro de
  una ventana de ~60 días (ver `RemindersCoordinator`).

### 4.2 Biometría (`local_auth`)
- **Android**: `MainActivity` debe extender `FlutterFragmentActivity` (no
  `FlutterActivity`). Edita
  `android/app/src/main/kotlin/.../MainActivity.kt`:
  ```kotlin
  import io.flutter.embedding.android.FlutterFragmentActivity
  class MainActivity : FlutterFragmentActivity()
  ```
- **iOS**: en `ios/Runner/Info.plist` añade:
  ```xml
  <key>NSFaceIDUsageDescription</key>
  <string>Usa Face ID para desbloquear PituApp.</string>
  ```

### 4.3 Compras (`in_app_purchase`)
- Producto **no consumible** (pago único), con el id **exacto**
  `pituapp_pro_lifetime` (constante `kProProductId` en
  `lib/features/purchases/domain/purchase_service.dart`).
- **Android (Google Play)**:
  1. Sube un *app bundle* firmado a un track interno/cerrado.
  2. Crea el producto in-app con ese id y actívalo.
  3. Agrega tu cuenta como *license tester* para comprar sin cobro real.
  4. El plugin añade el permiso `com.android.vending.BILLING`.
- **iOS (App Store Connect)**:
  1. Crea el In-App Purchase (no consumible) con el mismo id.
  2. Crea un usuario **Sandbox** y prueba con esa cuenta en el dispositivo.
  3. Habilita la capacidad *In-App Purchase* en el target `Runner`.

## 5. Cómo ejecutar

```bash
flutter devices          # lista dispositivos/emuladores
flutter run              # elige el dispositivo
# release Android:
flutter build appbundle --release
```

## 6. Checklist de pruebas

- [ ] **Recordatorios**: Ajustes → Recordatorios ON → concede permiso. Crea o
      mueve un cuidado con fecha próxima y verifica que llega la notificación.
- [ ] **Biometría**: Ajustes → Seguridad → Desbloqueo ON → autentica. Cierra y
      reabre la app: debe pedir huella/Face ID antes de mostrar el contenido.
- [ ] **Documentos**: Detalle de mascota → Docs → Agregar documento → elige
      foto/PDF → verifica miniatura, vista previa y Abrir/Descargar.
- [ ] **Límites de plan**: Ajustes → "Demo: ver como plan Free" → intenta una 2.ª
      mascota o un 3.er documento → aparece el paywall.
- [ ] **Compra Pro**: Paywall → Desbloquear Pro → completa la compra sandbox →
      concede Pro. Prueba "Restaurar compra" tras reinstalar.

## 7. Pendientes de producción (fuera del MVP)

- **Auto-restauración del entitlement**: el plan ya **se persiste** (una compra o
  el desbloqueo se conservan entre sesiones). Falta que producción arranque en
  **Free** (hoy la demo siembra Pro para exhibir todo) y que **restaure la
  compra automáticamente al inicio** en móvil, además del botón manual.
- **Cifrado en reposo**: pendiente (punto 2 aplazado). Al migrar el
  almacenamiento local a **Drift/SQLite cifrado** en móvil, se reemplaza la
  implementación del repositorio sin tocar el dominio. Hoy es
  `shared_preferences` + JSON.
- **Permisos de `file_picker`/`share_plus` por plataforma**: verificar en
  dispositivo el guardado (hoja de compartir) y la selección de archivos
  (importar respaldo, adjuntar documentos, foto de mascota); ya están integrados.

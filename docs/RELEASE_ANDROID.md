# Publicar en Android — build y firma

Guía para compilar el AAB de release de **PituApp** y prepararlo para Google Play.
El proyecto nativo vive en `android/` (`applicationId = com.ironcoding.pituapp`).

## 0. Requisitos

- Flutter (canal stable) y JDK 17.
- Android SDK (platform 34).

## 1. Restaurar los binarios que no se versionan

Dos archivos binarios **no** están en el repo (no se pueden versionar como texto):
el `gradle-wrapper.jar` y los iconos PNG por defecto del launcher. Restáuralos una
vez tras clonar:

```bash
flutter create --platforms=android --org com.ironcoding --project-name pitu_app .
```

`flutter create` **solo añade los archivos que faltan** (el wrapper y los iconos);
no sobrescribe la configuración ya versionada (manifiesto, `build.gradle`,
`MainActivity.kt`). Alternativamente, un `flutter build` regenera parte de esto.

> En CI esto lo hace automáticamente `.github/workflows/android.yml`, que además
> compila un APK debug para verificar que todo enlaza.

## 2. Crear el keystore de firma (una sola vez)

```bash
keytool -genkey -v -keystore pituapp-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias pituapp
```

Guarda el `.jks` **fuera del repositorio** y en un lugar seguro: si lo pierdes, no
podrás publicar actualizaciones de la app.

## 3. Configurar `key.properties`

Copia la plantilla y complétala:

```bash
cp android/key.properties.example android/key.properties
```

```properties
storePassword=...
keyPassword=...
keyAlias=pituapp
storeFile=/ruta/absoluta/a/pituapp-release.jks
```

`android/key.properties` y el `.jks` están en `.gitignore` (no se suben). Si el
archivo no existe, el build de release cae a la firma **debug** (útil para probar,
pero **no** válido para publicar en Play).

## 4. Compilar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # genera el código de Drift
flutter build appbundle --release                          # -> build/app/outputs/bundle/release/app-release.aab
```

Sube el `.aab` a Google Play Console.

### Versionado automático (recomendado)

En lugar de compilar a mano, empuja un tag SemVer y deja que CI arme el AAB con un
`versionCode` incremental (así nunca subes dos artefactos con el mismo `versionCode`,
requisito de Play):

```bash
git tag v0.1.0        # MAYOR.MENOR.PARCHE; ver CHANGELOG.md → "Política de versionado"
git push origin v0.1.0
```

El workflow `.github/workflows/release.yml` compila el App Bundle con
`--build-number=<corrida CI>` y lo publica como artefacto. El `versionName` sale de
`pubspec.yaml`; el `versionCode` lo fija CI. Para un AAB **firmado**, configura los
secretos del keystore (pasos 2–3) en el runner o firma localmente.

## 5. Iconos definitivos (opcional, recomendado)

Los iconos restaurados son los genéricos de Flutter. Para los definitivos, genera
un set desde el logo con `flutter_launcher_icons` (ver
`design/PetBienestar-Identidad-Visual.md` para la marca).

## 6. Pendientes de tienda (fuera de este build)

Ver `docs/WEB_IRONCODING.md` y `docs/PRODUCCION_PENDIENTES.md`: política de
privacidad en URL pública, Data Safety, clasificación por edad, capturas, feature
graphic y el producto de compra `pituapp_pro_lifetime`.

## 7. Validación en dispositivo

Tras instalar el APK/AAB, sigue `docs/PRUEBAS_EN_DISPOSITIVO.md`. Presta atención a
los recordatorios (RF-33/RF-35): que la notificación llegue a la **hora local
correcta**, que al conceder el permiso de **alarmas exactas** el aviso sea puntual,
y que tras un **reinicio** del teléfono se reprogramen (BootReceiver).

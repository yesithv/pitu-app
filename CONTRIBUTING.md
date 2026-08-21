# Guía de contribución — PituApp (PetBienestar)

Gracias por trabajar en PituApp. Esta guía resume cómo preparar el entorno, correr
las verificaciones que exige CI y las convenciones del proyecto. Para el **estado
funcional** ve a `docs/ESTADO_MVP.md`; para la **arquitectura**, al §5 del `README.md`.

## Requisitos

- **Flutter** (canal `stable`) y **Dart** incluido.
- **JDK 17** (para el build de Android).
- Android SDK (platform 34+) si vas a compilar el proyecto nativo.

El toolchain de Android está alineado con Flutter stable: **Gradle 8.14** (wrapper),
**Android Gradle Plugin 8.11.1** y **Kotlin 2.2.20**. Si actualizas Flutter y CI se
queja de versiones mínimas, sube estos tres en `android/` de forma coherente.

## Puesta en marcha

```bash
flutter pub get

# Genera el código de Drift (`*.g.dart`). NO se versiona: hay que generarlo tras
# clonar y tras tocar tablas/DAOs. CI lo corre antes de analyze/test.
dart run build_runner build --delete-conflicting-outputs

flutter run    # móvil o web
```

> El `gradle-wrapper.jar` y los iconos PNG por defecto son binarios y no se
> versionan; se restauran con `flutter create` (ver `docs/RELEASE_ANDROID.md`).

## Antes de abrir un PR: verificaciones locales

CI es un **gate estricto** (`.github/workflows/ci.yml`): falla ante errores,
warnings **e infos**. Corre localmente lo mismo antes de subir:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
```

- **`flutter analyze --fatal-infos`** debe salir limpio ("No issues found!").
- **`flutter test`** cubre el dominio, la capa de aplicación y widgets clave
  (login, paywall). Las funciones de hardware móvil (notificaciones, biometría,
  compras, archivos) se validan en dispositivo, no por unidad
  (`docs/PRUEBAS_EN_DISPOSITIVO.md`).

## Estilo de código

- Se respeta `analysis_options.yaml` (base `flutter_lints` + reglas explícitas del
  proyecto). Mantén la lógica **fuera de la UI** (Riverpod) y el dominio **puro**
  (sin dependencias de Flutter) para que sea testeable.
- Los comentarios explican el **porqué**, no el **qué**. Escribe en español, como el
  resto del código.
- Nada de `print()` ni de `TODO`/`FIXME` sueltos en `main`.

## Internacionalización (i18n)

Los textos viven en `lib/l10n/app_*.arb`. **`app_en.arb` es la plantilla**; al
añadir una clave, agrégala a **todos** los idiomas (`es`, `en`, `fr`, `pt`, `de`).
`flutter pub get` regenera `AppLocalizations`. No dejes idiomas con claves faltantes.

## Ramas y commits

- Trabaja en una rama por cambio (p. ej. `claude/…`, `feat/…`, `fix/…`); no empujes
  directo a `main`.
- Mensajes de commit en **[Conventional Commits](https://www.conventionalcommits.org/es/)**:
  `feat:`, `fix:`, `docs:`, `test:`, `chore:`, `refactor:`. En español, imperativo.
- Un push a `main` compila y publica la demo web (GitHub Pages); mantén `main`
  siempre en verde.

## Versionado y releases

La versión canónica está en `pubspec.yaml` (`MAYOR.MENOR.PARCHE+BUILD`) y sigue
SemVer. Anota los cambios en `CHANGELOG.md` (sección **[Sin publicar]**). Para
publicar, empuja un tag `vX.Y.Z`: `release.yml` compila el AAB con `versionCode`
incremental. Detalle en `CHANGELOG.md` → "Política de versionado" y
`docs/RELEASE_ANDROID.md`.

## Licencia

PituApp es software **propietario** (ver `LICENSE`). Al contribuir, aceptas que tu
aportación se incorpore bajo esos términos.

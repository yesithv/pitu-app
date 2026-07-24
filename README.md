# Pitu App

Aplicación Flutter de ejemplo con un "¡Hola Mundo!".

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.0 o superior

## Cómo ejecutar

```bash
flutter pub get
flutter run
```

## Cómo ejecutar los tests

```bash
flutter test
```

## Estructura

- `lib/main.dart` — Punto de entrada de la app. Muestra "¡Hola Mundo!" en el centro de la pantalla.
- `test/widget_test.dart` — Test de widget que verifica que se muestra el mensaje.
- `.github/workflows/deploy.yml` — Workflow que compila la app para web y la despliega en GitHub Pages.

## Despliegue automático en GitHub Pages

Cada cambio que llega a la rama `main` (por ejemplo, al mezclar un Pull Request)
dispara el workflow `Desplegar en GitHub Pages`, que compila la app para web y la
publica automáticamente.

El sitio queda disponible en:

```
https://yesithv.github.io/pitu-app/
```

### Configuración inicial (una sola vez)

Para que funcione, activa GitHub Pages con origen en Actions:

1. Ve a **Settings → Pages** en el repositorio.
2. En **Build and deployment → Source**, selecciona **GitHub Actions**.

A partir de ahí, cada push a `main` desplegará la versión más reciente.

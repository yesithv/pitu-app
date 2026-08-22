# PituApp — PetBienestar

Aplicación **Flutter local-first** para la gestión del cuidado y la salud de
mascotas. *El cuidado de tu mascota, siempre al día.*

> Homenaje interno: la mascota de ejemplo se llama Pitufo. 🐾

**Demo web (para revisión):** https://yesithv.github.io/pitu-app/
Se recomienda recargar con **Ctrl/Cmd + F5** tras cada despliegue.

---

## 1. Estado del proyecto (resumen ejecutivo)

- **Fase:** 1 — MVP local-first (sin backend).
- **Estado:** **núcleo funcional completo en código.** Los requisitos `[F1]` están
  implementados (incluidos RF-33/RF-35 de recordatorios) y ya existe el **proyecto
  nativo `android/`** (compila en CI). Quedan **validación en dispositivo**, firma y
  publicación.
  > ⚠️ **Fuente de verdad del estado: `docs/ESTADO_MVP.md`** (esta tabla §3 es
  > orientativa; ante cualquier duda prevalece `ESTADO_MVP.md`).
- **Última actualización de este documento:** 2026-08-05.
- **Dónde se dejó:** la app se despliega automáticamente a GitHub Pages en cada
  cambio a `main`. La superficie de prueba es la **web**; las funciones que
  requieren hardware móvil (notificaciones, biometría, compras, guardado/selección
  de archivos nativos) están implementadas con aislamiento por plataforma y
  quedan **pendientes de validación en dispositivo**.
- **Qué falta para el MVP:** (1) **validar en dispositivo** los recordatorios y
  funciones 📱, (2) **firma de release + AAB** (`docs/RELEASE_ANDROID.md`),
  (3) assets y cumplimiento de tienda, y (4) el proyecto **iOS**. Ya hechos:
  RF-33/RF-35, persistencia cifrada (RNF-10) y el proyecto `android/`. Detalle en
  `docs/ESTADO_MVP.md` y `docs/PRODUCCION_PENDIENTES.md`; Fase 2 en `docs/ROADMAP_V2.md`.

---

## 2. Cómo probar (web)

En https://yesithv.github.io/pitu-app/ :

- Al abrir se muestra la **pantalla de acceso**. Puedes **crear una cuenta local**
  (correo + contraseña, guardados solo en el dispositivo — sin backend) e ingresar,
  o pulsar **"Ver demo"** para entrar sin cuenta a una sesión de exhibición. La
  demo carga datos de ejemplo en **Pro** y es **efímera**: puedes explorar y editar,
  pero los cambios **no se guardan** ni tocan la base local. En Ajustes hay un
  interruptor *"Demo: ver como plan Free"* para explorar los límites y el paywall.
- La **cuenta local** es la base de la Fase 1: usa un `AuthRepository` (patrón
  repositorio) preparado para sustituirse por el backend en la Fase 2 (RF-53) sin
  tocar la interfaz. No hay servidor ni nube todavía.
- **La persistencia funciona en web:** crea o edita algo y **recarga la página**;
  tus datos siguen ahí (se guardan en el `localStorage` del navegador).
- Prueba el respaldo (Ajustes → Datos → Crear/Restaurar), los formularios con sus
  validaciones, el historial con filtros, los documentos, etc.

---

## 3. Estado por funcionalidad

> **Fuente única de verdad: [`docs/ESTADO_MVP.md`](docs/ESTADO_MVP.md).** Ahí vive la
> matriz completa y canónica por requisito (RF-01–50 y RNF), con su estado, la nota
> por requisito y el archivo que lo implementa. Este README ya **no duplica** esa
> tabla para evitar que ambas versiones diverjan.

Resumen: **todos los requisitos funcionales de Fase 1 (RF-01–50) están implementados
en código**, incluidos los adjuntos al filesystem (RF-29), los recordatorios
(RF-33/RF-35) y la persistencia cifrada (RNF-10). Las funciones que dependen de
hardware móvil (📱 notificaciones, biometría, compras, archivos nativos) están
implementadas con aislamiento por plataforma y quedan **pendientes de validación en
dispositivo**. El detalle por requisito, la leyenda (✅ / ⚠️ / 📱) y el mapa de
pruebas están en `docs/ESTADO_MVP.md`.

---

## 4. Pendientes del MVP

> Lista resumida. **Estado detallado y canónico en `docs/ESTADO_MVP.md`.**
> El núcleo está en código; queda validación, firma y publicación:

1. **Validación en dispositivo.** Las funciones marcadas 📱 (recordatorios,
   biometría, compras, guardar/seleccionar archivos nativos) están implementadas
   pero requieren probarse en Android. Guía en `docs/PRUEBAS_EN_DISPOSITIVO.md`.
2. **Firma de release + AAB.** El proyecto `android/` ya existe; falta el keystore
   y generar el App Bundle. Ver `docs/RELEASE_ANDROID.md`.
3. **Publicación en tiendas.** Assets (icono/feature graphic/capturas), política de
   privacidad en URL pública, Data Safety, clasificación por edad, y crear el
   producto de compra `pituapp_pro_lifetime`. Proyecto **iOS** aún por generar.
> Ya resueltos (no confundir con versiones viejas de este README): RF-13, RF-15/26,
> RF-21, **RF-29** (adjuntos al filesystem), **RF-33/RF-35** (recordatorios),
> **RNF-06** (espacio de documentos), **RNF-13** (borrar todos mis datos), el
> proyecto **`android/`**, el **entitlement de producción** (Free + auto-restore) y
> la **persistencia cifrada** (RNF-10).

> **Fuera del alcance de la Fase 1 (van en Fase 2):** cuenta de usuario, hogar
> compartido, sincronización en la nube, multi-dispositivo, plan Premium
> (suscripción) y link de solo lectura para el veterinario.

---

## 5. Arquitectura

Clean Architecture por *feature* con **patrón repositorio**: el dominio no
depende de la fuente de datos, de modo que la Fase 2 (backend Spring Boot +
PostgreSQL) consiste en cambiar la implementación de los repositorios (ERS §8.3).

```
lib/
├── core/
│   ├── domain/     # SyncMetadata: UUID, timestamps, borrado lógico (RD-18)
│   ├── data/       # Base en memoria + códec JSON + persistencia (localStorage) + seed
│   ├── di/         # Composición de dependencias (Riverpod)
│   ├── theme/      # Tokens de diseño
│   ├── utils/      # Reloj, UUID, fechas, límites de formulario, compresión de imagen
│   └── widgets/    # Componentes del sistema de diseño
└── features/
    ├── pets/         # Mascotas (+ archivadas, foto)
    ├── care/         # Catálogo, programación, cumplimiento, cumpleaños
    ├── clinical/     # Visitas, vacunas, diagnósticos, peso, historial con filtros
    ├── attachments/  # Documentos adjuntos (galería, compresión)
    ├── backup/       # Exportar/importar (resumen, combinar por UUID)
    ├── reports/      # Reporte PDF para el veterinario
    ├── reminders/    # Notificaciones locales (móvil)
    ├── security/     # Bloqueo biométrico (móvil)
    ├── purchases/    # Compras in-app (móvil)
    ├── plan/         # Entitlement Free/Pro, paywall
    ├── dashboard/ · calendar/ · settings/ · shell/
```

**Decisiones clave**
- **Estado / DI:** Riverpod (lógica fuera de la UI).
- **RD-18 desde el día 1:** UUID de cliente, `created_at`/`updated_at`,
  `created_by` reservado y borrado lógico en todas las entidades → habilita la
  sincronización de la Fase 2 sin migraciones destructivas.
- **Persistencia:** modelo en memoria reactivo + **códec JSON versionado**
  (esquema v4). En reposo se elige por plataforma (`LocalPersistence`): **SQLite
  cifrado con SQLCipher** (Drift + llavero del SO) en móvil/escritorio y snapshot
  en `localStorage` en web. El mismo códec JSON es el formato del **respaldo**
  (RF-41) y la base del contrato de la API de la Fase 2.
- **Aislamiento web/móvil:** las funciones que dependen de plugins nativos
  (`flutter_local_notifications`, `local_auth`, `in_app_purchase`, `share_plus`,
  `file_picker`) se eligen por plataforma mediante *conditional imports*; en web
  se usa una implementación no-op o basada en el navegador, de modo que **el build
  web nunca se rompe**.
- **Diseño:** tokens 1:1 del entregable de Identidad Visual. Ver `design/`.

---

## 6. Ejecutar y desplegar

```bash
flutter pub get
flutter run          # móvil o web
flutter test         # 132 pruebas unitarias de dominio/aplicación (verde)
```

La lógica de negocio de Fase 1 está cubierta por **pruebas unitarias** (dominio y
capa de aplicación, sin UI). El mapa de qué requisito valida cada archivo está en
`docs/ESTADO_MVP.md` §6. Los plugins nativos (notificaciones, biometría, compras,
archivos) se validan en dispositivo, no por unidad.

Cada push a `main` compila la web y la publica en GitHub Pages
(`.github/workflows/deploy.yml`). El flujo de trabajo valida el build en la rama
antes de promover a `main`, de modo que el sitio publicado siempre está verde.

---

## 7. Documentos de referencia

- `PetBienestar-Especificacion-Requisitos.md` — especificación de requisitos (ERS).
- `docs/PRUEBAS_EN_DISPOSITIVO.md` — guía para validar las funciones móviles.
- `design/` — identidad visual, diseño UX/UI y prototipo de referencia.

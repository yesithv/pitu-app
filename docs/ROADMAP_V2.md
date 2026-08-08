# Roadmap — Fase 2 y posteriores (PituApp)

> Todo lo que queda **fuera del alcance del MVP (Fase 1)** según la
> especificación (`PetBienestar-Especificacion-Requisitos.md`), organizado para
> planificación y para alimentar una sección "roadmap / próximamente" en la web.
>
> El estado del MVP vive en `docs/ESTADO_MVP.md`. Última actualización: 2026-08-05.

La Fase 1 es **local-first, sin backend**: los datos viven en el dispositivo, con
planes **Free** y **Pro** (pago único). Incluye un **gate de cuenta local**
(login/registro con credenciales guardadas solo en el dispositivo — no hay nube) y
un **acceso a demo efímero** para exhibición. Esa cuenta local usa un
`AuthRepository` (patrón repositorio); la Fase 2 sustituye su implementación por
una contra el backend, sin tocar la interfaz. La Fase 2 añade **backend, cuenta de
usuario en la nube, sincronización, hogar compartido y plan Premium** (suscripción),
conservando el funcionamiento offline (local-first).

> Nota Fase 1 → Fase 2: **RF-53** (crear cuenta, iniciar sesión) queda parcialmente
> cubierto en local por la cuenta del dispositivo; falta la parte remota (correo /
> Google / Apple, recuperar contraseña) y **RF-54** (migrar los datos locales a la
> cuenta al conectarse al backend).

---

## 1. Funcionalidades de Fase 2

### Cuenta, hogar y sincronización
- **RF-53** — Crear cuenta (correo / Google / Apple), iniciar sesión y recuperar
  contraseña.
- **RF-54** — Al crear cuenta, **migrar los datos locales existentes** sin pérdida
  (el JSON del respaldo de Fase 1 es la base del contrato de migración).
- **RF-55** — Un usuario Premium crea un **hogar** e invita por código o link.
- **RF-56** — Todos los miembros del hogar acceden a las mismas mascotas,
  historial y cuidados, y pueden registrar acciones.
- **RF-57** — Acciones y recordatorios generan notificaciones a todos los miembros
  y un **feed de actividad**.
- **RF-58** — El administrador del hogar puede remover miembros y eliminar el hogar.
- **RF-59** — Sincronizar datos entre dispositivos y la nube, conservando uso
  offline (local-first).

### Veterinario y reportes
- **RF-40** — Generar un **link de solo lectura** temporal (vencimiento por
  defecto 7 días); ver links activos, contador de accesos y revocarlos.
  *(Función Premium.)*

### Planes y compras
- **RF-51** — Ofrecer plan **Premium** (suscripción mensual/anual) que habilita las
  funciones de backend.
- **RF-52** — Validar las suscripciones Premium **del lado del servidor**.

---

## 2. Reglas, datos y calidad de Fase 2

- **RN-03** — Plan **Premium**: suscripción recurrente; incluye todo lo de Pro más
  hogar compartido, respaldo y sincronización en la nube, multi-dispositivo y link
  de solo lectura para el veterinario.
- **RN-10** (transversal) — El **Pro se respeta de por vida**: un Pro que tome
  Premium conserva sus funciones locales aunque cancele Premium (solo pierde nube
  y hogar).
- **RN-13** — La eliminación de datos se propaga por **borrado lógico** para
  sincronizar borrados entre dispositivos.
- **RNF-14** — Cifrado en tránsito (TLS 1.3) y en reposo (AES-256) en backend;
  autenticación/autorización robustas; control de acceso por rol en el hogar.
- **RD-13…RD-17** — Nuevas entidades: `Usuario`, `Hogar`, `MembresiaHogar`,
  `SuscripcionPremium`, `LinkVeterinario`.

### Stack previsto (ERS §8.2)
Spring Boot 3 + API REST · PostgreSQL · bucket S3-compatible · Firebase Cloud
Messaging (+ APNs) · sincronización local-first bidireccional · validación de
recibos server-side.

---

## 3. Endurecimiento y follow-ups (no son Fase 2 estricta)

Mejoras técnicas que conviene abordar pronto, aunque no dependan del backend:

- **Carga perezosa de adjuntos** — Hoy los bytes de los adjuntos (ya en el
  filesystem, RF-29) se **hidratan en memoria** al cargar; conviene cargarlos bajo
  demanda para reducir el uso de RAM con muchos documentos.
- **Escrituras incrementales en Drift** — Sustituir el reemplazo transaccional
  completo por upserts/borrados por entidad para rendimiento con volúmenes grandes.
- **Crash reporting real** — Reemplazar el `NoopCrashReporter`
  (`lib/core/observability/`) por un backend real (Sentry/Crashlytics).
- **Foto de la mascota al filesystem** — La foto sigue en base64 (es pequeña);
  podría unificarse con el almacén de adjuntos.

---

## 4. Fuera del alcance de la Fase 1 (resumen para la web)

> Cuenta de usuario, hogar compartido, notificaciones entre miembros y feed de
> actividad, sincronización y respaldo en la nube, uso multi-dispositivo, link de
> solo lectura para el veterinario, plan Premium (suscripción), rol de veterinario
> e integración con clínicas.

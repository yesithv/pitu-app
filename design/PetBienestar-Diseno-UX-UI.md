# PetBienestar — Documento de Diseño UX/UI

**Versión:** 3.0 — MVP local-first + modelo de dos fases y tres planes
**Estado:** Diseño cerrado, listo para prototipado en generador de diseños (Google Stitch) y desarrollo.

**Cambios frente a v2.0:**
- Modelo de negocio definido en dos fases y tres planes (Free / Pro / Premium).
- **Pro** pasa a ser **pago único de por vida** (no recurrente).
- **Premium** es la **suscripción recurrente**, y solo aparece en Fase 2 (cuando existe backend).
- Interfaz ajustada para que la diferencia entre planes sea clara y honesta.

---

## 0. Fases del producto y arquitectura

El producto se construye en dos fases. El diseño contempla ambas desde el día uno, aunque solo la Fase 1 se lanza al inicio.

### Fase 1 — MVP (local-first, sin backend)

Toda la información vive en el dispositivo. Sin servidor, sin cuenta, sin login. Reduce drásticamente el tiempo y costo de lanzamiento y elimina la operación de infraestructura.

**Planes disponibles en Fase 1:** Free y Pro (pago único). Premium **no existe todavía**, porque sus funciones requieren backend.

**Funciones del MVP:** catálogo de cuidados por especie, recordatorios locales, historial clínico completo (visitas, vacunas, diagnósticos, peso), documentos adjuntos, panel *recomendado vs. realizado*, reporte PDF para el veterinario (generado en el dispositivo), exportar/importar respaldo manual.

**Riesgo asumido:** sin nube, si el usuario pierde el teléfono pierde el historial. Mitigación: exportar/importar respaldo, que por eso es función central y **gratuita**.

### Fase 2 — Con backend

Se introduce servidor, cuenta de usuario y sincronización. La app pasa de *local-only* a *local-first con sincronización* (conserva su capacidad offline).

**Planes disponibles en Fase 2:** Free, Pro (sigue igual) y **Premium** (nuevo, recurrente).

**Funciones que habilita:** hogar compartido entre cuidadores, notificaciones sincronizadas y feed de actividad, respaldo y sincronización en la nube, uso multi-dispositivo, link de solo lectura para el veterinario, y (futuro) rol de veterinario e integración con clínicas.

### Principio transversal

La app se construye **lista para el backend** aunque no lo tenga: UUIDs desde el día uno, `created_at`/`updated_at`, `created_by` reservado, borrado lógico y patrón repositorio. Ver sección 8.

---

## 1. Concepto del producto

Aplicación móvil (Android e iOS) para la **gestión del cuidado y la salud de mascotas**.

**Pilares del MVP:** recordatorios de cuidados periódicos + historial clínico digital.
**Diferenciador del MVP:** el panel *recomendado vs. realizado* (semáforo de cumplimiento).
**Diferenciador de Fase 2:** el cuidado compartido en familia.

**Nombre:** PetBienestar · **Tagline:** *El cuidado de tu mascota, siempre al día.*

**Homenaje interno a Pitufo:** mascota de ejemplo del onboarding llamada Pitufo; símbolo del logo inspirado en su huella; en Ajustes → Acerca de: *"Hecho con cariño, en memoria de Pitufo."* 🐾

---

## 2. Modelo de datos (entidades)

En Fase 1 todas viven en la base local del dispositivo.

| Entidad | Descripción | Fase |
|---|---|---|
| **Perfil local** | Datos del dueño (nombre, foto, preferencias). Sin cuenta. | 1 |
| **Mascota** | Perro, gato u otro. Estado: activa / archivada. | 1 |
| **Tipo de cuidado** | Catálogo predefinido por especie + personalizadas | 1 |
| **Programación** | Frecuencia y próxima fecha por tarea y mascota | 1 |
| **Registro de ejecución** | Tarea realizada: cuándo, notas, adjuntos | 1 |
| **Visita médica** | Fecha, veterinario, motivo, diagnóstico, tratamiento, adjuntos | 1 |
| **Vacuna** | Tipo, fecha, próxima dosis, veterinario, adjunto | 1 |
| **Diagnóstico** | Condición con estado: activo / en tratamiento / resuelto / crónico | 1 |
| **Registro de peso** | Valor, unidad, fecha | 1 |
| **Documento adjunto** | Foto o PDF en el sistema de archivos de la app | 1 |
| **Notificación local** | Recordatorio programado en el sistema operativo | 1 |
| **Entitlement de plan** | Estado del plan (Free / Pro). Pro = compra única. | 1 |
| **Usuario (cuenta)** | Identidad con credenciales, sincronizable | 2 |
| **Hogar** | Grupo de cuidadores que comparten mascotas | 2 |
| **Membresía de hogar** | Relación usuario–hogar con rol | 2 |
| **Suscripción Premium** | Estado de la suscripción recurrente | 2 |
| **Link de veterinario** | URL temporal de solo lectura | 2 |

**Nota de implementación (desde Fase 1):** identificadores **UUID**, campos `created_at`/`updated_at`, `created_by` reservado, borrado lógico (`deleted_at`). Ver sección 8.

---

## 3. Modelo de negocio y planes

### 3.1 Estructura de planes

| Plan | Cobro | Disponible en | Para quién |
|---|---|---|---|
| **Free** | Gratis | Fase 1 y 2 | Quien tiene una sola mascota y quiere lo esencial |
| **Pro** | **Pago único, de por vida** | Fase 1 y 2 | Quien quiere todas las funciones locales para siempre, sin suscripción |
| **Premium** | **Suscripción (mensual / anual)** | Solo Fase 2 | Quien quiere hogar compartido, nube y multi-dispositivo |

### 3.2 Relación de precios

- **Pro (pago único)** ≈ **3 a 4 meses** del precio mensual de Premium.
- **Premium anual** ≈ **10 meses** del precio mensual (dos meses gratis frente a pagar mes a mes).

Ejemplo **ilustrativo** (valores por definir por mercado, en COP):

| Plan | Precio ilustrativo |
|---|---|
| Free | $0 |
| Pro (único) | $34.900 una sola vez |
| Premium mensual | $9.900 / mes |
| Premium anual | $99.000 / año (equivale a ~$8.250/mes) |

*Estos números son solo para visualizar la relación; el precio real se define más adelante.*

### 3.3 Qué incluye cada plan

| Función | Free | Pro (único) | Premium (recurrente) |
|---|---|---|---|
| Mascotas | 1 | Ilimitadas | Ilimitadas |
| Catálogo de cuidados + recordatorios locales | ✅ | ✅ | ✅ |
| Historial clínico (visitas, vacunas, diagnósticos, peso) | ✅ | ✅ | ✅ |
| Adjuntos por mascota | 2 | Ilimitados | Ilimitados |
| Tareas personalizadas por mascota | 3 | Ilimitadas | Ilimitadas |
| Panel recomendado vs. realizado | ❌ | ✅ | ✅ |
| Reporte PDF para veterinario | ❌ | ✅ | ✅ |
| Recordatorios avanzados (anticipación configurable) | ❌ | ✅ | ✅ |
| Exportar / importar respaldo manual | ✅ | ✅ | ✅ |
| **Hogar compartido entre cuidadores** | ❌ | ❌ | ✅ |
| **Respaldo y sincronización en la nube** | ❌ | ❌ | ✅ |
| **Uso multi-dispositivo** | ❌ | ❌ | ✅ |
| **Link de solo lectura para veterinario** | ❌ | ❌ | ✅ |

**Reglas del modelo:**
1. **Pro es para siempre.** Un solo pago; nunca vence ni se cobra de nuevo. El lenguaje de la interfaz es *"desbloquear"*, no *"suscribirse"*.
2. **Premium es la capa conectada.** Cubre las funciones con costo recurrente de servidor; por eso es recurrente.
3. **Pro se respeta dentro de Premium.** Quien compró Pro y luego toma Premium conserva sus funciones locales de por vida aunque cancele Premium; al cancelar, solo pierde las funciones de nube/hogar.
4. **La exportación de respaldo es gratuita en todos los planes.** Sin backend, es el único seguro contra la pérdida de datos; cobrarlo sería cobrar por no perder lo propio.

### 3.4 Cómo se comunica en la interfaz (clave de este ajuste)

El objetivo es que un usuario entienda las diferencias **sin leer un manual**:

- **Etiqueta de plan siempre visible** en Ajustes → Suscripción: *"Plan Free"*, *"Pro · Comprado"* o *"Premium · renueva el 15 de ago"*.
- **Distinción visual y de lenguaje entre único y recurrente:**
  - Pro: tarjeta con sello *"Pago único · Para siempre"* y botón *"Desbloquear Pro"*.
  - Premium: tarjeta con selector Mensual/Anual, etiqueta *"2 meses gratis"* en el anual, y botón *"Suscribirme"*.
- **En Fase 1 solo se muestran Free y Pro.** Nada de Premium hasta que exista backend, para no prometer lo que no hay.
- **Comparación de un vistazo:** la pantalla de planes usa una tabla de tres columnas (o dos en Fase 1) con íconos ✓ / — , encabezada por el precio y el tipo de cobro de cada plan.
- **Candados honestos:** cada función bloqueada muestra a qué plan pertenece (*"Disponible en Pro"* / *"Disponible en Premium"*), nunca un candado mudo.

---

## 4. Flujos de usuario

### Flujo 1 — Onboarding (primera vez)

Sin registro ni login en Fase 1. Máximo **90 segundos** hasta un home funcional.

1. **Bienvenida** — logo, tagline, botón "Comenzar". Enlace secundario: "Ya tengo un respaldo".
2. **Mascota, paso 1/2** — foto (opcional) + nombre.
3. **Mascota, paso 2/2** — especie (selector visual: Perro / Gato / Otro), edad/fecha de nacimiento, peso inicial, raza (opcional). Al elegir especie precarga el catálogo: *"Preparamos un plan de cuidados para [nombre]"*.
4. **Permiso de notificaciones** — pantalla previa que explica el porqué antes del diálogo del sistema: *"Te avisaremos cuando [nombre] necesite algo."* Crítica: sin permiso, la propuesta de valor se cae.
5. **Home** — con el plan cargado. Sin tutorial obligatorio.

**Aviso de respaldo:** a los 7 días o al registrar la segunda mascota, aparece una sola vez, descartable.

### Flujo 2 — Home / Dashboard

1. Header: saludo, avatar (→ Ajustes), campana con badge.
2. Chips de mascota (scroll horizontal): "Todas" + una por mascota. Filtro persistente.
3. Tarjeta de estado general (Pro/Premium): *"Firulais está al día · 8 de 10 cuidados"* + barra. En Free, teaser discreto con *"Disponible en Pro"*.
4. Sección **Hoy**: vencidas primero (rojo), luego las del día.
5. Sección **Próximos 7 días**: tarjetas compactas por día.
6. **FAB (+)**: Registrar cuidado / Agregar visita médica / Registrar peso / Nueva mascota.

**Tarjeta de tarea:** ícono + nombre, mascota (en vista "Todas"), estado con color **e ícono** (nunca solo color), botón "Marcar como hecha" en la tarjeta.
- 🔴 Atrasado — *"Venció hace 5 días"* · 🟡 Próximo — *"En 3 días"* · 🟢 Al día

### Flujo 3 — Marcar tarea como hecha (el más frecuente)

**Rápido (1 toque):** desde la tarjeta → "Marcar como hecha" → registro con fecha de hoy → toast con "Deshacer" → recalcula próxima fecha y reprograma la notificación.

**Detallado (al tocar la tarjeta):** fecha (hoy, editable), notas, adjuntos → Guardar → recalcula → reprograma.

**Local-first:** operación instantánea, sin spinner ni posibilidad de fallo por red.

### Flujo 4 — Perfil de mascota e historial clínico

Cuatro tabs: **Resumen · Cuidados · Historial · Documentos** (sección 5).

Formularios: **visita médica** (fecha, veterinario, motivo, diagnóstico, tratamiento, notas, adjuntos); **vacuna** (tipo, fecha, próxima dosis autosugerida, veterinario, adjunto); **diagnóstico** (condición, fecha, estado, notas, visita asociada opcional).

### Flujo 5 — Compartir con el veterinario

**Fase 1 — Reporte PDF:** menú "..." → "Compartir con veterinario" → selector (historial completo / solo vacunas / rango de fechas) → PDF generado en el dispositivo → hoja de compartir del sistema. *(Función Pro.)*

**Fase 2 — Link de solo lectura:** URL temporal (7 días), abre en navegador sin cuenta, revocable. *(Función Premium.)*

### Flujo 6 — Notificaciones locales (Fase 1)

**Tipos:** anticipado (Pro: 1/3/7 días antes), del día, vencida.
**Restricciones que el diseño respeta:** límite de 64 notificaciones pendientes en iOS (reprogramar por ventanas); reprogramar tras reinstalar, restaurar respaldo o cambiar de zona horaria; manejar restricciones de alarmas exactas y batería en Android.

En Fase 2 conviven con notificaciones push del hogar.

### Flujo 7 — Planes y compra

**Puntos de activación del paywall:** intentar segunda mascota, superar adjuntos, tocar el panel de cumplimiento, generar PDF, configurar anticipación de recordatorios. En Fase 2 se suman: crear hogar, activar nube, generar link de veterinario.

**Pantalla de planes:**
- **Fase 1:** dos columnas — Free vs. Pro. Pro con sello *"Pago único · Para siempre"* y botón *"Desbloquear Pro"*. Botón *"Restaurar compra"* obligatorio (único modo de recuperar Pro tras reinstalar sin backend).
- **Fase 2:** tres columnas — Free / Pro / Premium. Premium con selector Mensual/Anual, *"2 meses gratis"* en anual, prueba gratuita de 7 días, botón *"Suscribirme"*. Pro mantiene su tarjeta de pago único.

**Regla de UX:** nunca bloquear sin explicar. Mostrar qué desbloquea cada plan y a cuál pertenece la función, sin agresividad.

### Flujo 8 — Registrar peso

Entradas: FAB, tab Resumen → gráfico → "+ Registrar", o tarea recurrente. Formulario mínimo: valor + unidad (kg/lb) + fecha (hoy) + nota. Gráfico se actualiza al instante. Ante variación fuerte, aviso informativo, no diagnóstico: *"Cambio de peso notable desde el último registro. Puede ser útil comentarlo en la próxima visita."*

### Flujo 9 — Archivar mascota

Deliberadamente cuidadoso. Menú "..." → **"Archivar mascota"** (nunca "Eliminar").
1. Confirmación sobria: se detienen recordatorios y se cancelan notificaciones; la mascota sale del dashboard y del conteo del plan; **historial y documentos se conservan íntegros**.
2. Motivo opcional (salteable): *Falleció · Cambió de hogar · Otro*. Sin explicación escrita.
3. Si es fallecimiento, mensaje breve y humano, sin ofrecer productos ni insistir.
4. Pasa a **Mascotas → Archivadas**, en modo lectura, con exportación de su historial en PDF.
5. **Desarchivar** siempre disponible; recalcula fechas y reprograma notificaciones.
6. Archivar **nunca** dispara paywall ni fuerza decisiones de negocio en un momento sensible.

**Eliminación definitiva** aparte, en Ajustes → Datos, con doble confirmación y sugerencia de respaldo previo.

### Flujo 10 — Exportar respaldo (gratuito, todos los planes)

Ajustes → Datos → "Crear respaldo" → genera `PetBienestar-respaldo-AAAA-MM-DD.zip` (JSON + adjuntos) → hoja de compartir del sistema. Confirmación: *"Respaldo creado. Guárdalo en un lugar seguro."* En Ajustes: *"Último respaldo: hace 34 días"* (ámbar si >60 días).

### Flujo 11 — Importar respaldo

Desde bienvenida ("Ya tengo un respaldo") o Ajustes → Datos → "Restaurar respaldo". Valida y muestra resumen antes de importar (*"3 mascotas · 148 registros · 27 documentos · 12 jul 2026"*). Si ya hay datos: **Reemplazar todo** (con advertencia) o **Combinar** (por defecto; duplicados por UUID). Barra de progreso. Al terminar reprograma notificaciones. Manejo de errores: archivo corrupto, versión más reciente que la app, espacio insuficiente.

### Flujo 12 — Migración a cuenta (Fase 2)

Cuando llega el backend, el usuario local puede **crear una cuenta** sin perder nada:
1. Ajustes → "Crear cuenta y activar la nube".
2. Registro (correo/Google/Apple).
3. La app **sube los datos locales** como primer estado de la cuenta (el JSON del respaldo ya se parece al contrato de la API — sección 8).
4. Confirmación: sus datos ahora respaldados y sincronizables.
5. Free y Pro pueden crear cuenta también (para no perder datos ante cambio de teléfono); las funciones de nube/hogar solo se activan con Premium.

---

## 5. Arquitectura de pantallas

### Menú principal (Bottom Navigation)

**Fase 1 — 4 ítems:** 🏠 Inicio · 🐾 Mascotas · 📅 Calendario · ⚙️ Ajustes.
**Fase 2 — 5 ítems:** se inserta 👥 Hogar entre Calendario y Ajustes (solo visible con Premium activo; en Free/Pro aparece como entrada que explica y ofrece Premium).

### 5.1 Inicio
Ver Flujo 2. Estados: con tareas / todo al día / sin mascotas / cargando.

### 5.2 Mascotas
**Lista:** tarjetas con foto, nombre, edad, mini-semáforo. "+ Agregar mascota" (paywall en Free con una ya creada). Acceso a **Archivadas**.
**Detalle — 4 tabs:**
| Tab | Contenido |
|---|---|
| Resumen | Datos básicos · semáforo (Pro/Premium) · condiciones activas · próximas 3 tareas · gráfico de peso |
| Cuidados | Tareas y frecuencias · editar/desactivar/crear |
| Historial | Timeline invertido · búsqueda · filtros |
| Documentos | Galería de adjuntos · búsqueda · filtros · cuadrícula/lista |

**Condiciones activas (Resumen):** diagnósticos activo/en tratamiento/crónico, con estado en color propio (distinto del semáforo). Toque → detalle y cambio de estado, que queda en el timeline. Vacío: *"Sin condiciones activas registradas."*
**Menú "..."**: Editar · Registrar peso · Compartir con veterinario · Archivar.

### 5.3 Calendario
Vista mensual con puntos de color; toque en día → panel con tareas. Toggle a agenda. Filtros por mascota y tipo.

### 5.4 Hogar (Fase 2, Premium)
Sin Premium: pantalla que explica el valor y ofrece suscribirse. Con Premium: miembros (foto, nombre, rol), "Invitar" (código + link), mascotas compartidas, feed de actividad. El administrador puede remover miembros.

### 5.5 Ajustes
- **A — Perfil local** (Fase 1) / **Cuenta** (Fase 2, con correo y cierre de sesión).
- **B — Suscripción:** etiqueta de plan visible; *"Desbloquear Pro"* / *"Gestionar"*; en Fase 2 también Premium con Mensual/Anual; **Restaurar compra**.
- **C — Notificaciones:** activar; anticipación por defecto (Pro); hora preferida; acceso a ajustes del sistema si el permiso está denegado.
- **D — Seguridad:** bloqueo biométrico; pedir desbloqueo al abrir.
- **E — Datos:** crear/restaurar respaldo; "Último respaldo"; espacio usado; eliminar todos los datos (doble confirmación). En Fase 2: sincronización en la nube (Premium) con "última sincronización".
- **F — Preferencias:** idioma; tema; unidades (kg/lb); formato de fecha.
- **G — Privacidad:** política; nota destacada en Fase 1: *"Toda la información se guarda solo en este dispositivo. No la enviamos a ningún servidor."*
- **H — Soporte** · **I — Acerca de** (versión, términos, 🐾 *"Hecho con cariño, en memoria de Pitufo."*).

### 5.6 Pantallas secundarias
Registrar cuidado · visita médica · vacuna · diagnóstico · peso · mascota · tarea personalizada · visor de documento · compartir con veterinario (PDF) · archivadas · crear/restaurar respaldo · **pantalla de planes (paywall)** · bandeja de recordatorios · onboarding (5 pantallas).
**Fase 2 añade:** login/registro, hogar, invitar, links de veterinario activos, migración a cuenta.

### 5.7 Búsqueda (Historial y Documentos)
Campo fijo + chips (`Todo·Visitas·Vacunas·Diagnósticos·Cuidados·Peso` / `Todos·Fotos·PDFs·Recetas·Laboratorio·Carnet`) + rango de fechas / toggle cuadrícula-lista. Instantánea (local-first).

---

## 6. Lineamientos visuales
*(Detallados en el entregable de Identidad Visual. Resumen operativo.)*

- **Color:** regla 60-30-10, base neutra cálida, teal petróleo de marca inclinado al azul; semánticos verde/ámbar/rojo (verde inclinado al amarillo para no chocar con la marca). Nunca solo color: siempre color + ícono + texto. Modo oscuro en carbón cálido.
- **Diagnóstico:** escala cromática distinta a la del semáforo.
- **Tipografía:** Nunito (títulos/acciones) + Nunito Sans (cuerpo/datos). Máx. 4 niveles. Cuerpo ≥14sp, botones ≥16sp.
- **Forma:** píldoras para acción/navegación, radios moderados para datos. Área táctil mínima 48×48.
- **Ilustración:** solo en periferia (onboarding, vacíos, paywall), nunca junto a datos clínicos.
- **Estados vacío/error/carga:** definidos con mensaje cálido + acción; el guardado es instantáneo (sin spinner); sin banner de sincronización en Fase 1.

**Paywall (nota de diseño visual):** las tarjetas de plan usan el color de acento cálido, no los semánticos, para no competir con los estados. Pro se distingue de Premium por el sello *"Pago único"* frente al selector de periodicidad.

---

## 7. Requerimientos no funcionales

- **Rendimiento:** arranque a dashboard <1,5 s; guardado y consulta <100 ms; cualquier dato en ≤3 toques.
- **Almacenamiento:** adjuntos en disco (no en BD); compresión <500 KB/foto; manejo de "sin espacio".
- **Confiabilidad:** transacciones atómicas; migraciones de esquema versionadas sin pérdida; respaldo compatible hacia adelante.
- **Seguridad/privacidad:** BD local cifrada; bloqueo biométrico opcional; Fase 1 sin envío de datos (argumento de venta); Ley 1581/2012 (exportación y eliminación ya cubiertas); declaración App Privacy / Data Safety favorable.
- **Compras:** Fase 1, validación local de la compra única (StoreKit/Play Billing) + Restaurar compra. Fase 2, validación de la suscripción del lado del servidor.
- **Notificaciones:** respetar límite iOS 64 por ventanas; reprogramar tras reinstalar/restaurar/cambio de zona horaria; restricciones Android.
- **Distribución:** App Store + Play Store; en Fase 1 el ciclo de actualización es el único canal de correcciones y de actualización del catálogo (versionado, sin sobrescribir personalizaciones).
- **Usabilidad medible:** primera mascota + primer cuidado en <90 s, sin ayuda.
- **ASO:** el nombre es el campo de mayor peso; aprovechar el ángulo de privacidad ("funciona sin conexión, tus datos no salen del teléfono") en descripción y capturas; ambas tiendas ponderan retención y calidad técnica (Android Vitals).

---

## 8. Arquitectura técnica

### Stack Fase 1 (MVP)
| Capa | Tecnología |
|---|---|
| Móvil | Flutter (Android + iOS) |
| Persistencia | SQLite / Drift, cifrada |
| Archivos | Directorio de documentos de la app |
| Notificaciones | flutter_local_notifications (sin FCM/APNs) |
| Compras | StoreKit 2 + Play Billing, validación local |
| PDF | Generación en el dispositivo |
| Respaldo | ZIP (JSON + adjuntos) |
| Backend | Ninguno |

### Stack Fase 2 (añadidos)
| Capa | Tecnología |
|---|---|
| Backend | Spring Boot 3 + REST API |
| Base de datos | PostgreSQL |
| Archivos en nube | Bucket S3-compatible |
| Push | Firebase Cloud Messaging (+ APNs) |
| Sincronización | Local-first, bidireccional al reconectar |
| Suscripciones | Validación de recibos del lado del servidor |

### Construir "listo para el backend" (desde Fase 1)
1. **UUID** en todas las entidades, generados en el cliente.
2. **`created_at` / `updated_at`** en cada registro.
3. **`created_by`** reservado con valor local por defecto.
4. **Borrado lógico (`deleted_at`)** en vez de físico.
5. **Patrón repositorio** (Clean Architecture): el dominio no sabe si los datos vienen de SQLite o de una API; agregar backend es cambiar la implementación del repositorio.
6. **El JSON del respaldo se parece al contrato de la futura API**, para servir de base a la migración a cuenta (Flujo 12).

### Camino a Fase 2
Perfil local → Usuario con cuenta; se introduce Hogar; las mascotas locales suben como primer estado; notificaciones locales conviven con push; la app conserva capacidad offline. El plan Pro (local, único) se respeta; Premium se cobra por las capas de servidor.

---

## 9. Notas para el prototipado (Stitch)
- Una pantalla por prompt, con propósito, elementos de arriba a abajo, estados (con datos/vacío/error) y paleta semántica.
- Generar explícitamente vacíos y errores.
- Prototipar primero: **Inicio, Detalle de mascota, Registrar cuidado** y **Pantalla de planes**.
- **Fase 1: no pedir login ni registro, ni Premium.** Solo Free y Pro.

---

## 10. Pendientes antes de desarrollo
- Precio final de Pro (único) y Premium (mensual/anual) por mercado.
- Catálogo de cuidados por especie con frecuencias, validado con criterio veterinario.
- Identidad visual definitiva (paleta, tipografía, íconos, mascota de marca, logo a 48px).
- Verificación de dominio y registro de marca "PetBienestar" (SIC).
- Textos de política de privacidad y términos.
- Esquema JSON versionado del respaldo (y su alineación con el contrato de la API de Fase 2).
- Métrica que dispara la inversión en Fase 2 (uso/conversión).

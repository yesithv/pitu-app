# PetBienestar — Identidad Visual y Design Tokens

**Versión:** 1.1
**Complementa:** sección 6 del Documento de Diseño UX/UI v3.0
**Dirección elegida:** cálido sereno (teal petróleo sobre neutros arena), personalidad ilustrada y amigable.

> **Nota de planes (v1.1):** el producto maneja tres planes — Free, **Pro** (pago único, de por vida) y **Premium** (suscripción, solo Fase 2). Donde este documento dice "destacar Pro", aplica a ambos planes de pago. La distinción visual clave está en la sección 9.1: Pro se marca con sello *"Pago único"*, Premium con selector de periodicidad. El color de acento cálido (`brand/accent`) es el que viste el paywall, nunca los semánticos.

---

## 0. Principio rector

**Calidez en la periferia, seriedad en el dato.**

La personalidad amigable e ilustrada vive en: onboarding, estados vacíos, logo, ilustraciones y microcopys. La sobriedad manda en: historial clínico, formularios médicos, tablas de datos y el reporte PDF para el veterinario.

Un usuario que está registrando el diagnóstico de una mascota enferma no necesita una ilustración simpática al lado. Un usuario que abre la app por primera vez, sí.

---

## 1. Restricciones cromáticas de partida

Tres colores están comprometidos como **semánticos** y no pueden usarse como color de marca ni decorativo:

| Estado | Significado |
|---|---|
| Verde | Al día |
| Ámbar | Próximo a vencer |
| Rojo | Atrasado |

**Consecuencia crítica:** como la marca es teal (vecino del verde), se resuelve separándolos por temperatura:

- El **teal de marca se inclina hacia el azul** (petróleo, frío).
- El **verde semántico se inclina hacia el amarillo** (fresco, cálido).

Nunca deben poder confundirse en una misma pantalla. Esta separación es obligatoria, no estética.

---

## 2. Paleta — Modo claro

### Marca

| Token | Hex | Uso |
|---|---|---|
| `brand/primary` | `#14595F` | Color principal: barra activa, botones primarios, enlaces, elementos de marca |
| `brand/primary-hover` | `#0E4247` | Estado presionado |
| `brand/primary-soft` | `#D8EAEB` | Fondos suaves, chips seleccionados, contenedores de acento |
| `brand/accent` | `#E8B04B` | Acento cálido puntual: destacar Pro, ilustraciones. **Uso restringido** (ver nota) |

> **Nota sobre `brand/accent`:** es visualmente cercano al ámbar semántico. Usar **solo** en superficies donde no haya estados de cumplimiento presentes (paywall, ilustraciones, ícono Pro). Nunca en tarjetas de tareas.

### Neutros cálidos (base arena/crema)

| Token | Hex | Uso |
|---|---|---|
| `surface/background` | `#FAF7F2` | Fondo general de la app |
| `surface/card` | `#FFFFFF` | Tarjetas y superficies elevadas |
| `surface/alt` | `#F3EEE6` | Secciones alternas, campos de formulario, fondos de agrupación |
| `border/default` | `#E4DCD0` | Bordes, divisores |
| `border/strong` | `#CFC4B4` | Bordes de campos activos |

### Texto

| Token | Hex | Contraste sobre fondo | Uso |
|---|---|---|---|
| `text/primary` | `#2A2724` | 13.8:1 | Títulos, contenido principal |
| `text/secondary` | `#6B645C` | 5.4:1 | Texto de apoyo, descripciones |
| `text/tertiary` | `#948C82` | 3.3:1 | Metadata, timestamps. **Solo ≥14sp** |
| `text/on-brand` | `#FFFFFF` | 8.1:1 sobre primary | Texto sobre botones y superficies de marca |

### Semánticos de cumplimiento

| Estado | Token | Hex | Fondo suave |
|---|---|---|---|
| 🟢 Al día | `status/ok` | `#47935B` | `#E3F1E6` |
| 🟡 Próximo | `status/due` | `#C98518` | `#FBEEDA` |
| 🔴 Atrasado | `status/overdue` | `#C2473D` | `#FAE3E1` |

**Regla obligatoria:** todo estado se acompaña de **ícono + texto**, nunca solo color.

### Semánticos de diagnóstico

Escala deliberadamente **distinta** a la de cumplimiento, para que el usuario no confunda "condición activa" con "tarea atrasada".

| Estado | Token | Hex | Forma visual |
|---|---|---|---|
| Activo | `dx/active` | `#7B5EA7` | Etiqueta rellena |
| En tratamiento | `dx/treatment` | `#4A7BC8` | Etiqueta rellena |
| Crónico | `dx/chronic` | `#6B645C` | Etiqueta con borde |
| Resuelto | `dx/resolved` | `#948C82` | Etiqueta con borde, texto tenue |

---

## 3. Paleta — Modo oscuro

Base de carbón **cálido**, nunca negro puro.

| Token | Hex |
|---|---|
| `surface/background` | `#1A1917` |
| `surface/card` | `#232120` |
| `surface/alt` | `#2C2927` |
| `border/default` | `#3A3633` |
| `text/primary` | `#F0EBE4` |
| `text/secondary` | `#B0A89E` |
| `text/tertiary` | `#847C73` |
| `brand/primary` | `#4FA8AD` |
| `brand/primary-soft` | `#1C3D40` |
| `status/ok` | `#63B377` |
| `status/due` | `#E0A548` |
| `status/overdue` | `#E07A6E` |

Los colores de marca y semánticos se **aclaran y desaturan** en oscuro: los tonos profundos del modo claro no alcanzan contraste suficiente sobre fondos oscuros.

---

## 4. Tipografía

**Familia:** Nunito (superfamilia), disponible gratis en Google Fonts, con soporte completo de español y buen rango de pesos.

- **Nunito** — títulos, botones, números destacados. Terminaciones redondeadas, cálida y amigable.
- **Nunito Sans** — cuerpo, datos, formularios, tablas. Más neutra y legible en tamaños pequeños y textos largos.

Usar la misma superfamilia mantiene coherencia sin que los datos clínicos se vean caricaturescos.

### Escala tipográfica

| Nivel | Tamaño | Peso | Interlineado | Uso |
|---|---|---|---|---|
| Display | 28sp | 700 | 1.2 | Título de pantalla principal |
| Título 1 | 22sp | 700 | 1.25 | Títulos de pantalla |
| Título 2 | 18sp | 600 | 1.3 | Encabezados de sección |
| Card title | 17sp | 600 | 1.3 | Título de tarjeta de tarea |
| Cuerpo | 15sp | 400 | 1.45 | Texto general |
| Cuerpo fuerte | 15sp | 600 | 1.45 | Énfasis dentro de texto |
| Botón | 16sp | 600 | 1.2 | Etiquetas de botón |
| Metadata | 13sp | 400 | 1.4 | Fechas, contadores, notas al pie |
| Etiqueta | 11sp | 700 | 1.2 | Chips de estado, mayúsculas, con `letter-spacing: 0.5` |

**Mínimos innegociables:** cuerpo ≥14sp, botones ≥16sp. Máximo 4 niveles jerárquicos visibles por pantalla.

---

## 5. Forma y espaciado

### Radios de esquina

| Elemento | Radio |
|---|---|
| Tarjetas | 16 |
| Campos de formulario | 12 |
| Botón primario (CTA) | 999 (píldora) |
| Botón secundario | 12 |
| Chips de mascota y filtros | 999 (píldora) |
| Bottom sheet | 24 (solo esquinas superiores) |
| Avatares y fotos de mascota | 999 (círculo) |
| Miniaturas de documentos | 8 |
| FAB | Círculo |

**Criterio:** píldoras para elementos de acción y navegación (transmiten calidez); radios moderados para contenedores de datos (mantienen orden visual).

### Escala de espaciado

Base **4**. Valores permitidos: `4 · 8 · 12 · 16 · 24 · 32 · 48`.

| Contexto | Valor |
|---|---|
| Padding horizontal de pantalla | 16 |
| Padding interno de tarjeta | 16 |
| Separación entre tarjetas | 12 |
| Separación entre secciones | 24 |
| Separación etiqueta–campo | 8 |

**Área táctil mínima:** 48 × 48, sin excepciones (incluye íconos pequeños y checkboxes).

### Elevación

Sombras muy suaves y cálidas, no grises neutras.

- Tarjeta en reposo: `0 1px 3px rgba(42,39,36,0.06)`
- Tarjeta elevada / bottom sheet: `0 4px 16px rgba(42,39,36,0.10)`
- FAB: `0 6px 20px rgba(20,89,95,0.24)`

En modo oscuro, la elevación se comunica con **cambio de superficie**, no con sombra.

---

## 6. Iconografía

**Set recomendado:** [Phosphor Icons](https://phosphoricons.com) — terminaciones redondeadas, coherente con la personalidad amigable, múltiples pesos, licencia libre, disponible para Flutter.

**Alternativa más sobria:** Lucide, si al prototipar el conjunto se percibe demasiado blando.

| Regla | Especificación |
|---|---|
| Grilla | 24 × 24 |
| Peso | `Regular` en navegación y contenido; `Fill` solo para el ítem activo del bottom nav |
| Grosor de trazo | 2px (uniforme, sin mezclar) |
| Color por defecto | `text/secondary` |
| Color activo | `brand/primary` |
| Formato | SVG |

**Prohibido:** mezclar íconos de línea con íconos rellenos en la misma jerarquía, o combinar dos familias de íconos distintas.

### Íconos por tipo de cuidado

Cada tipo de cuidado del catálogo lleva un ícono propio y constante en toda la app (desparasitación, vacuna, dental, baño, uñas, peso, consulta veterinaria, medicación). Deben ser distinguibles entre sí a 20px, que es el tamaño en las tarjetas de tarea.

---

## 7. Ilustración

**Dónde sí:** onboarding, estados vacíos, pantalla de paywall, confirmación de respaldo creado.

**Dónde no:** historial clínico, formularios médicos, detalle de diagnóstico, reporte PDF, pantalla de archivar mascota.

**Estilo:** trazo continuo con relleno plano, paleta limitada a `brand/primary` + `brand/primary-soft` + `surface/alt` + un acento. Sin degradados, sin sombras, sin volumen 3D.

**Restricción anti-infantil:** una ilustración por pantalla como máximo, y nunca acompañando datos numéricos o clínicos. Animales estilizados, no caricaturas con expresiones exageradas.

---

## 8. Logo

### Concepto

Marca compuesta por un **símbolo** + **wordmark**.

**Símbolo:** una almohadilla de pata cuyo contorno inferior se resuelve como un **check**. Une los dos conceptos centrales del producto: la mascota y el cumplimiento del cuidado — que es justamente el diferenciador del MVP.

**Wordmark:** "PetBienestar" en Nunito 700, con "Pet" en `brand/primary` y "Bienestar" en `text/primary`. La separación cromática ayuda a la lectura del nombre compuesto.

### El homenaje a Pitufo

Vive en el símbolo, sin anunciarse:

- Las proporciones de la almohadilla se basan en la huella real de Pitufo.
- La mascota de ejemplo del onboarding se llama **Pitufo**.
- En Ajustes → Acerca de: *"Hecho con cariño, en memoria de Pitufo."* 🐾

Nadie más necesita entenderlo para que la marca funcione. Esa es la idea.

### Requisitos técnicos

| Variante | Uso |
|---|---|
| Completa (símbolo + wordmark) | Bienvenida, materiales de marketing, encabezado del PDF |
| Solo símbolo | Ícono de app, avatar, favicon |
| Monocromática (una tinta) | Impresión, marca de agua del PDF |
| Sobre fondo oscuro | Modo oscuro, capturas de tienda |

**Prueba obligatoria:** el ícono de la app debe ser legible y reconocible a **48 × 48 px**. Si a ese tamaño el check no se distingue de la almohadilla, el símbolo debe simplificarse. Es la prueba que decide si el logo sirve.

---

## 9. Aplicación a componentes clave

### Tarjeta de tarea (el componente más visto de la app)

- Superficie `surface/card`, radio 16, padding 16, sombra en reposo.
- **Franja o punto de estado** de 4px en el borde izquierdo, con el color semántico correspondiente.
- Ícono del tipo de cuidado a 20px, en `text/secondary`.
- Nombre de la tarea en Card title; nombre de la mascota en Metadata.
- Etiqueta de estado: chip píldora con fondo suave del estado, ícono y texto ("Venció hace 5 días").
- Botón "Marcar como hecha": secundario, radio 12, ancho completo en la parte inferior de la tarjeta.

### Chip de mascota

Píldora con avatar circular de 28px + nombre en Cuerpo fuerte. Seleccionado: fondo `brand/primary-soft`, texto `brand/primary`, sin borde. No seleccionado: fondo transparente, borde `border/default`.

### Bottom navigation

Fondo `surface/card`, borde superior `border/default`. Ítem activo: ícono `Fill` en `brand/primary` + etiqueta 11sp peso 700. Ítem inactivo: ícono `Regular` en `text/tertiary` + etiqueta peso 400. Con 4 ítems, cada destino ocupa 25% del ancho — cómodo para el pulgar.

### Tarjetas de plan (paywall)

Las tres tarjetas usan `brand/accent` (cálido) para acentos y precios, **nunca los colores semánticos**, para que el paywall no se lea como un estado de cumplimiento.

- **Free:** tarjeta plana, borde `border/default`, sin sello. Botón ausente o "Plan actual".
- **Pro:** borde `brand/primary`, sello superior *"PAGO ÚNICO · PARA SIEMPRE"* en etiqueta 11/700 sobre `brand/primary-soft`. Precio grande en Nunito 700. Botón primario *"Desbloquear Pro"*. Sin periodicidad.
- **Premium (Fase 2):** borde `brand/primary`, selector segmentado Mensual/Anual en la cabecera, etiqueta *"2 MESES GRATIS"* en `brand/accent` sobre el anual. Botón primario *"Suscribirme"*. Opcional: cinta *"RECOMENDADO"*.

La diferencia entre *"Desbloquear"* (único) y *"Suscribirme"* (recurrente) en los botones es intencional y debe mantenerse en todos los idiomas.

### Reporte PDF para veterinario

**Excepción deliberada al sistema:** sin ilustraciones, sin colores decorativos, sin píldoras. Tipografía Nunito Sans, jerarquía tipográfica pura, marca solo en el encabezado en monocromo. Debe verse como un documento clínico, porque va a ser leído por un profesional.

---

## 10. Accesibilidad

- Contraste mínimo **AA (4.5:1)** para todo texto; **3:1** para íconos y elementos gráficos portadores de información.
- `text/tertiary` no se usa por debajo de 14sp.
- Ningún estado se comunica solo con color: siempre color + ícono + texto.
- Soporte de tamaño de fuente del sistema hasta 200%, sin que se rompan las tarjetas ni se corten etiquetas.
- Etiquetas de accesibilidad en todos los íconos accionables.
- Respeto a "reducir movimiento" del sistema: si está activo, se desactivan las transiciones animadas.

---

## 11. Pendientes

- Diseño final del símbolo del logo y prueba de legibilidad a 48px.
- Set completo de íconos por tipo de cuidado del catálogo.
- Ilustraciones de estados vacíos (7 escenas, según la tabla del documento de diseño).
- Validación de contraste de la paleta oscura con herramienta automatizada.
- Definición de la captura principal para las tiendas, aprovechando el ángulo de privacidad.

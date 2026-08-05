# Ficha de producto para la web de IronCoding — PituApp

> **Documento listo para copiar/pegar.** Contiene el listado de producto (nombre,
> descripción, características) y los **enlaces que exige Google Play** para poblar
> la página de IronCoding. Cada dato es un **valor final** o un marcador
> `[PENDIENTE: …]` explícito; no hace falta abrir el código.
>
> Fuentes: `design/PetBienestar-Diseno-UX-UI.md`, `design/PetBienestar-Identidad-Visual.md`,
> `docs/PRIVACIDAD.md`, `docs/ESTADO_MVP.md`. Última actualización: 2026-08-05.

---

## 1. Identidad del producto

| Campo | Valor |
|---|---|
| **Nombre público** | PituApp |
| **Tagline** | El cuidado de tu mascota, siempre al día. |
| **Categoría (Google Play)** | Estilo de vida *(alternativa: Salud y bienestar)* — `[PENDIENTE: confirmar en Play]` |
| **Plataformas** | Android *(iOS previsto)* |
| **Idioma** | Español |
| **Desarrollador** | IronCoding |
| **Clasificación por edad** | Para todos *(sin contenido sensible)* — `[PENDIENTE: completar cuestionario IARC en Play]` |
| **Modelo** | Gratis con compra única opcional (Pro) |

---

## 2. Descripción corta (≤ 80 caracteres, ficha de Play)

```
Cuida la salud de tus mascotas: recordatorios, historial clínico y respaldos.
```

## 3. Descripción larga (web y ficha de Play)

```
PituApp te ayuda a llevar el cuidado y la salud de tus mascotas siempre al día,
directamente desde tu teléfono y sin complicaciones.

Organiza los cuidados periódicos (vacunas, desparasitación, baños y más) con un
catálogo por especie y recordatorios locales que te avisan a tiempo. Registra el
historial clínico completo —visitas, vacunas, diagnósticos y peso— y consúltalo en
una línea de tiempo con búsqueda y filtros.

Su panel "recomendado vs. realizado" te muestra de un vistazo, con un semáforo de
cumplimiento, qué cuidados están al día, próximos o atrasados. Y cuando visitas al
veterinario, genera un reporte PDF del historial en segundos.

PituApp es local-first: funciona sin conexión, no necesita cuenta ni registro, y
tus datos nunca salen de tu teléfono. Puedes exportar e importar un respaldo cuando
quieras, y proteger la app con tu huella o Face ID.

Gratis para siempre para tu primera mascota. Mejora a Pro (pago único) para
mascotas ilimitadas, el panel de cumplimiento, el reporte PDF para el veterinario y
los recordatorios anticipados.
```

---

## 4. Características (bullets para la web / ficha)

**Incluidas en el plan gratuito**
- Catálogo de cuidados por especie con **recordatorios locales**.
- **Historial clínico** completo: visitas, vacunas, diagnósticos y peso.
- Línea de tiempo con **búsqueda y filtros**.
- **Documentos adjuntos** (fotos y PDF) por mascota, con compresión automática.
- **Exportar e importar respaldo** manual — gratis en todos los planes.
- **Funciona sin conexión**, sin cuenta ni login; tus datos no salen del teléfono.
- **Bloqueo biométrico** opcional (huella / Face ID).
- Tema claro/oscuro e interfaz en español.

**Plan Pro (pago único, para siempre)**
- Mascotas, adjuntos y cuidados personalizados **ilimitados**.
- **Panel de cumplimiento** (recomendado vs. realizado, con semáforo).
- **Reporte PDF** del historial para el veterinario.
- **Recordatorios anticipados** configurables (1 / 3 / 7 días antes).

---

## 5. Argumentos de privacidad (diferenciador, para destacar)

- **Funciona sin conexión** y sin cuenta de usuario.
- **Tus datos se guardan únicamente en tu dispositivo**; no tenemos servidores.
- **No vendemos ni compartimos** tus datos con terceros.
- **Tú controlas tus datos**: puedes exportarlos y borrarlos cuando quieras.
- Base de datos **cifrada en el dispositivo**.

---

## 6. Planes y precios

| Plan | Precio | Incluye |
|---|---|---|
| **Free** | Gratis | 1 mascota, adjuntos y cuidados personalizados limitados, recordatorios del día y de vencidos, respaldo manual. |
| **Pro** | **Pago único, para siempre** — `[PENDIENTE: precio Pro]` | Todo lo de Free + mascotas/adjuntos/cuidados ilimitados, panel de cumplimiento, reporte PDF, recordatorios anticipados. |

> El plan **Premium** (suscripción con nube y hogar compartido) llegará en una
> versión posterior — ver `docs/ROADMAP_V2.md`.

---

## 7. Enlaces requeridos por Google Play (y para la web)

> Google Play exige, como mínimo, una **URL de política de privacidad** y un
> **correo de soporte**. Completar los `[PENDIENTE]` antes de publicar.

| Enlace / dato | Valor |
|---|---|
| **Política de privacidad (URL)** | `[PENDIENTE: alojar docs/PRIVACIDAD.md en una URL pública]` |
| **Correo de soporte/contacto** | yesithvalencia@gmail.com |
| **Ficha en Google Play (URL)** | `[PENDIENTE: se genera al publicar la app]` |
| **Sitio web** | `[PENDIENTE: URL de la página de IronCoding]` |
| **Nombre del paquete (applicationId)** | `[PENDIENTE: definir, p. ej. com.ironcoding.pituapp]` |

---

## 8. Recursos gráficos requeridos (estado)

Ninguno existe todavía en el repositorio; hay que producirlos según la identidad
visual (`design/PetBienestar-Identidad-Visual.md`).

| Asset | Especificación | Estado |
|---|---|---|
| **Icono de la app** | 512×512 PNG (32-bit) | ❌ `[PENDIENTE]` |
| **Feature graphic** | 1024×500 PNG/JPG | ❌ `[PENDIENTE]` |
| **Capturas de teléfono** | ≥ 2, 16:9 o 9:16 | ❌ `[PENDIENTE]` |
| **Logo / símbolo** | Diseño final (huella que resuelve en check) | ❌ `[PENDIENTE]` |

**Guía de marca para los assets:**
- Color primario (teal): **#14595F** · hover **#0E4247** · suave **#D8EAEB**
- Acento (gold, uso restringido Pro/ilustración): **#E8B04B**
- Fondo cálido: **#FAF7F2** · texto principal **#2A2724**
- Semáforo de cumplimiento: al día **#47935B** · próximo **#C98518** · atrasado **#C2473D**
- Tipografía: **Nunito** (títulos) + **Nunito Sans** (cuerpo) — Google Fonts.
- Personalidad: "calidez en la periferia, seriedad en el dato" (teal sobre arena).

---

## 9. Resumen de pendientes para publicar (lista corta)

1. Alojar la política de privacidad en una **URL pública**.
2. Definir el **applicationId** y generar el **proyecto Android + AAB firmado**.
3. Producir **icono, feature graphic y capturas**.
4. Completar en Play Console: **Data Safety**, **clasificación por edad** y el
   producto de compra **`pituapp_pro_lifetime`**.
5. Fijar el **precio de Pro** y reemplazar el placeholder.

> Estado funcional del producto: ver `docs/ESTADO_MVP.md`. Roadmap posterior:
> `docs/ROADMAP_V2.md`.

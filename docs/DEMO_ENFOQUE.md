# Enfoque del demo — mostrar funcionalidades, no solo datos

> **Estado: parcialmente implementado.** Este documento describe el foco y el
> objetivo del demo de exhibición. Recoge la recomendación de la revisión de
> arquitectura.
>
> - ✅ **§3.1 Hoja de bienvenida** y ✅ **§3.3 conmutador Free↔Pro visible** están
>   implementadas (ver `lib/features/demo/presentation/`).
> - ⏳ §3.2 (CTAs a lo enterrado), §3.4 (multi-mascota, más allá de la línea en la
>   bienvenida) y §3.5 (capturas en el README) quedan para una iteración posterior.

## 1. El problema hoy

El demo **ya tiene datos ricos** (Pitufo y Luna con ~4 años de historial, Firulais
archivado, curva de peso, semáforo con estados variados, arranque en **Pro**). El
contenido es bueno. Lo que falta **no es más data**, sino **contexto y narrativa**:
un visitante nuevo cae directo en el dashboard sin ninguna explicación y ve "las
tareas de hoy y poco más". Las joyas del producto —historial clínico completo,
reporte PDF veterinario, respaldo/portabilidad, recordatorios inteligentes— quedan
enterradas y **no se perciben**.

**Objetivo:** que en los primeros 30 segundos el usuario entienda *qué hace la app*
y *por qué le importa*, y que perciba con claridad la diferencia entre **Free** y
**Pro**.

## 2. Principio rector

> **No aumentar los datos; aumentar la orientación.** El demo es una casa amueblada
> sin recepcionista que muestre las habitaciones. Hay que añadir el recorrido, no
> más muebles.

## 3. Propuestas de enfoque (orden de impacto)

### 3.1 Hoja de bienvenida al entrar al demo (una sola vez) — ✅ implementada
Al pulsar **"Ver demo"**, mostrar una hoja/overlay con 3–4 funciones estrella y un
botón "Explorar". Foco en **funcionalidades**, no en registros:

- 🩺 **Historial clínico completo** — visitas, vacunas, diagnósticos y peso.
- 📄 **Reporte PDF para tu veterinario** — con un toque (Pro).
- 🔔 **Recordatorios inteligentes** — próxima dosis, vencidos, anticipados.
- ☁️ **Respaldo y portabilidad** — exporta y combina por UUID.

### 3.2 Pistas hacia lo que no se ve en el dashboard
El dashboard solo muestra "hoy" y "próximos". Añadir *call-to-actions* visibles que
lleven a las funciones enterradas: "Mira el historial de Pitufo", "Genera un reporte
PDF", "Revisa la curva de peso".

### 3.3 Hacer visible el contraste Free vs. Pro dentro del recorrido — ✅ implementada
Ver §4. El conmutador "ver como Free" ya no está escondido en Ajustes: es un pill
**visible en la barra del demo** (`DemoPlanPill`), parte del tour, para que se
entienda qué desbloquea el Pro. Al pasar a Free, el dashboard muestra el teaser con
candado y las acciones Pro abren el paywall existente.

### 3.4 Transmitir el soporte multi-mascota
El demo entra enfocado en la primera mascota. El overview debería mencionar "2
mascotas activas + 1 archivada" para comunicar que soporta un hogar con varias
mascotas.

### 3.5 Capturas en el README
El enlace del demo es texto plano; añadir 2–3 capturas para que quien no abra la web
igual capte el producto de un vistazo.

## 4. Diferenciación Pro vs. Free (fuente: `lib/features/plan/domain/plan.dart`)

El demo debe **hacer palpable** esta tabla, no solo aplicarla en silencio. La forma
recomendada: permitir alternar el plan en vivo (conmutador ya existente en Ajustes,
"Demo: ver como plan Free") y mostrar el candado honesto + el paywall cuando se topa
un límite.

| Función | Free | Pro |
|---|---|---|
| Mascotas activas | **1** | **Ilimitadas** |
| Adjuntos por mascota | **2** | Ilimitados |
| Cuidados personalizados por mascota | **3** | Ilimitados |
| Panel/indicador de cumplimiento (dashboard) | ❌ | ✅ |
| Reporte PDF veterinario | ❌ | ✅ |
| Recordatorios anticipados configurables (1/3/7 días) | ❌ | ✅ |

> Nota: estos valores son la **fuente de verdad de negocio** (`PlanLimits.free` /
> `PlanLimits.pro`, RN-01/RN-02) y están cubiertos por `test/plan_limits_test.dart`.
> Cualquier cambio de límites debe reflejarse aquí y en esas pruebas.

**Momentos donde el demo debería evidenciar el Pro:**
1. Al intentar **añadir una 2.ª mascota** en modo Free → paywall con el beneficio claro.
2. Al abrir el **panel de cumplimiento** en Free → teaser con candado (ya existe
   `_ComplianceTeaser` en el dashboard; el tour debería dirigir la atención a él).
3. Al pulsar **"Generar PDF"** en Free → invitación a Pro.
4. Al configurar **recordatorios anticipados** en Free → bloqueado con explicación.

## 5. Qué NO hacer

- No inflar el demo con más mascotas/registros: el volumen actual ya basta.
- No ocultar los límites de Free: mostrarlos **es** el argumento de venta del Pro.
- No usar solo color para el estado (accesibilidad, identidad §10): siempre
  ícono + texto, como ya hace `StatusPill`.

## 6. Alcance

La hoja de bienvenida (§3.1) y el conmutador Free↔Pro visible (§3.3) ya están
implementados en `lib/features/demo/presentation/` (`demo_welcome_sheet.dart`,
`demo_plan_pill.dart`), cableados desde `_DemoScaffold` en `lib/app.dart` y cubiertos
por `test/demo_pro_highlight_test.dart`. Las piezas restantes (§3.2 CTAs a lo
enterrado, §3.5 capturas en el README) se planificarán aparte.

# Estado del MVP — PituApp (Fase 1)

> **Fuente única de verdad** del estado funcional de la app frente a la
> especificación (`PetBienestar-Especificacion-Requisitos.md`). Sustituye a la
> matriz del `README.md` como referencia de estado.
>
> Última auditoría: **2026-08-05** (contraste spec ↔ código real).
> Documentos relacionados: `docs/ROADMAP_V2.md` (Fase 2),
> `docs/WEB_IRONCODING.md` (ficha para la web/tienda),
> `docs/PRODUCCION_PENDIENTES.md` (guía técnica de publicación).

Leyenda: ✅ hecho y verificado en código · 🟠 parcial / interino · ❌ pendiente ·
📱 real solo en móvil (no-op/limitado en web).

---

## 1. Veredicto

El **núcleo funcional del MVP está completo en código**. Los dos huecos de
recordatorios fiables (RF-33 y RF-35) ya están **implementados** y el **proyecto
nativo `android/`** ya existe (compila en CI). **Aún no está listo para publicar**:
falta (a) **validar en dispositivo** los recordatorios y demás funciones 📱,
(b) la **firma de release + AAB** (keystore del usuario), y (c) el paquete de
**assets y cumplimiento** de la tienda. Detalle abajo, en `PRODUCCION_PENDIENTES.md`
y en `RELEASE_ANDROID.md`.

---

## 2. Requisitos funcionales (RF) — Fase 1

### Gestión de mascotas
| Req | Función | Estado | Nota |
|---|---|---|---|
| RF-01 | Crear mascota (foto incl.) | ✅ | `features/pets/` |
| RF-02 | Editar mascota | ✅ | |
| RF-03 | Archivar (detiene recordatorios, sale del conteo) | ✅ | |
| RF-04 | Motivo de archivado opcional | ✅ | |
| RF-05 | Desarchivar (recalcula fechas) | ✅ | |
| RF-06 | Eliminar definitivamente (doble confirmación) | ✅ | `pet_repository_impl.dart` |
| RF-07 | Lista de activas + archivadas | ✅ | |

### Catálogo, programación y ejecución de cuidados
| Req | Función | Estado | Nota |
|---|---|---|---|
| RF-08 | Catálogo precargado por especie | ✅ | `care/data/care_catalog.dart` |
| RF-09 | Editar frecuencia | ✅ | |
| RF-10 | Desactivar un cuidado | ✅ | |
| RF-11 | Cuidados personalizados (con límite de plan) | ✅ | |
| RF-12 | Cálculo automático de la próxima fecha | ✅ | |
| RF-13 | Catálogo versionado sin sobrescribir personalizaciones | ✅ | `care/application/catalog_updater.dart` (RN-09) |
| RF-14 | Marcar como hecho (1 toque) + recálculo | ✅ | |
| RF-15 | Registro con detalle (fecha no futura, notas, adjuntos) | ✅ | `care_register_screen.dart` |
| RF-16 | Deshacer un registro reciente | ✅ | |
| RF-17 | Ejecución guardada en el historial | ✅ | |

### Historial clínico
| Req | Función | Estado | Nota |
|---|---|---|---|
| RF-18 | Visita médica (editar/eliminar) | ✅ | |
| RF-19 | Vacuna con próxima dosis autosugerida | ✅ | |
| RF-20 | Diagnóstico con estado | ✅ | |
| RF-21 | Cambio de estado registrado como entrada del historial | ✅ | `clinical_repository_impl.dart` (esquema v4) |
| RF-22 | Registro de peso | ✅ | |
| RF-23 | Aviso de variación de peso (>10%) | ✅ | No diagnóstico |
| RF-24 | Línea de tiempo integrada | ✅ | |
| RF-25 | Buscar/filtrar por tipo y fecha | ✅ | |

### Documentos adjuntos
| Req | Función | Estado | Nota |
|---|---|---|---|
| RF-26 | Adjuntar a mascota, visitas, vacunas y cuidados | ✅ | |
| RF-27 | Galería con filtro por tipo | ✅ | |
| RF-28 | Compresión de imágenes | ✅ | tope 2 MB por archivo |
| RF-29 | Archivos en filesystem; BD guarda referencia | ❌ | **Pendiente**: hoy embebidos en base64 en la BD (ver §4 y RNF-04) |

### Recordatorios y notificaciones (📱)
| Req | Función | Estado | Nota |
|---|---|---|---|
| RF-30 | Notificaciones locales por próxima fecha | ✅ 📱 | `reminders/data/reminder_scheduler_io.dart` |
| RF-31 | Del día / vencido persistente / anticipados (Pro) | ✅ 📱 | |
| RF-32 | Tocar la notificación abre el cuidado/mascota | ✅ 📱 | |
| RF-33 | Reprogramar tras reinstalar/restaurar/**zona horaria** | ✅ (en código) 📱 | Se fija la zona local del dispositivo (`flutter_timezone` + `setLocalLocation`) y se reprograma al reanudar si cambió (observer en `main.dart`). **Falta validar en dispositivo** |
| RF-34 | Respetar el límite de 64 de iOS (por ventanas) | ✅ 📱 | tope 60 en `reminders_coordinator.dart` |
| RF-35 | Alarmas exactas Android + avisar permiso | ✅ (en código) 📱 | Pide `SCHEDULE_EXACT_ALARM` y usa `exactAllowWhileIdle` si está concedido (degrada a inexacto si no); permiso declarado en el manifiesto. **Falta validar en dispositivo** |

### Cumplimiento, reporte, respaldo, planes
| Req | Función | Estado | Nota |
|---|---|---|---|
| RF-36 | Indicador de cumplimiento por mascota | ✅ | |
| RF-37 | Resumen de cumplimiento (Pro) | ✅ | |
| RF-38 | Reporte PDF con selección (Pro) | ✅ | `reports/` |
| RF-39 | PDF con encabezado + hoja de compartir | ✅ | |
| RF-41 | Exportar respaldo (gratis) | ✅ | |
| RF-42 | Resumen antes de importar | ✅ | |
| RF-43 | Reemplazar vs. combinar por UUID | ✅ | |
| RF-44 | Reprogramar notificaciones tras importar | ✅ | |
| RF-45 | Errores de importación (corrupto/versión/espacio) | ✅ | |
| RF-46 | Recordatorio de respaldo + "último respaldo hace X" | ✅ | |
| RF-47 | Planes Free y Pro | ✅ | |
| RF-48 | Compra con StoreKit/Play + entitlement persistido | ✅ 📱 | producto `pituapp_pro_lifetime` (crear en consola) |
| RF-49 | Restaurar compra | ✅ 📱 | |
| RF-50 | Estado del plan + comparativa + candado honesto | ✅ | |

**RF Fase 1: 48 de 49 completos** (RF-33 y RF-35 hechos en código, pendientes de
validar en dispositivo). Único pendiente de implementación: **RF-29**.

---

## 3. Requisitos no funcionales (RNF) — Fase 1

| Req | Requisito | Estado | Nota |
|---|---|---|---|
| RNF-01 | Arranque < 1,5 s | ✅ | app ligera, local-first |
| RNF-02 | Guardado/consulta < 100 ms | ✅ | modelo en memoria reactivo |
| RNF-03 | Cualquier dato en ≤ 3 toques | ✅ | |
| RNF-04 | Adjuntos en filesystem, no en BD | ❌ | Incumplido: base64 en la BD (= RF-29) |
| RNF-05 | Compresión + manejo "sin espacio" | ✅ | |
| RNF-06 | Visibilidad del espacio ocupado por documentos | ❌ | **Pendiente**: solo se ve el tamaño por archivo, no el total |
| RNF-07 | Escrituras atómicas (transacciones) | ✅ | Drift (móvil) usa transacción replace-all |
| RNF-08 | Migraciones versionadas sin pérdida | ✅ | `db_codec` v4 + migración de snapshot |
| RNF-09 | Respaldo compatible hacia adelante | ✅ | |
| RNF-10 | BD local cifrada en reposo | ✅ (en código) 📱 | SQLite+SQLCipher; **falta validar en dispositivo** |
| RNF-11 | Bloqueo biométrico opcional | ✅ 📱 | `security/` |
| RNF-12 | No envía datos; declararlo en Data Safety | 🟠 | La app no envía datos; **falta el formulario Data Safety** en Play |
| RNF-13 | Ley 1581: política + exportar + **eliminar todo** | 🟠 | Política (borrador) + exportar ✅; **falta "borrar todos mis datos"** (solo borrado por mascota) |
| RNF-15 | Validación de compras local + restauración | ✅ 📱 | server-side es Fase 2 |
| RNF-16 | Soporte Android e iOS | 🟠 | Código listo; **faltan los proyectos nativos** |
| RNF-17 | Publicación cumpliendo permisos/privacidad | ❌ | Ver `PRODUCCION_PENDIENTES.md` |
| RNF-18 | Actualización solo por ciclo de app (F1) | ✅ | catálogo versionado (RN-09) |
| RNF-19 | Primera mascota+cuidado en < 90 s | ✅ | onboarding guiado |
| RNF-20 | Calidad Android Vitals | ⏳ | medible solo tras publicar |
| RNF-21 | Accesibilidad (fuentes del sistema, etiquetas) | ✅ | |
| RNF-22 | Interfaz en español; preparada para i18n | ✅ | |

---

## 4. Faltantes del MVP (qué nos hace falta)

**Recordatorios fiables (RF-33 y RF-35): ✅ implementados** — se fija la zona
horaria local del dispositivo y se reprograma ante cambios (RF-33), y se piden
alarmas exactas usando `exactAllowWhileIdle` cuando el permiso está concedido
(RF-35). Quedan **pendientes de validación en dispositivo** (#4).

Pendientes de implementación:

1. **RF-29 / RNF-04 — Adjuntos al filesystem (🟠).** Hoy viajan en base64 dentro
   del snapshot cifrado (tope 2 MB por archivo). Funciona, pero incumple la spec y
   no escala. Mover el binario al directorio de la app y guardar solo la ruta.
2. **RNF-06 — Espacio ocupado por documentos (🟡).** Añadir en Ajustes → Datos el
   total de almacenamiento usado por adjuntos.
3. **RNF-13 — Eliminación total de datos (🟡, cumplimiento).** Añadir una acción
   "borrar todos mis datos" (con confirmación) además del borrado por mascota.

---

## 5. Bloqueantes de publicación (no funcionales)

Resumen; el detalle y el "cómo continuar" están en `docs/PRODUCCION_PENDIENTES.md`.

- 🟠 **Proyecto nativo `android/`** — ✅ creado y compila en CI (`android.yml`).
  Falta la **firma de release** (keystore del usuario) y generar el **AAB**
  (`docs/RELEASE_ANDROID.md`). El proyecto **iOS** sigue pendiente.
- ❌ **Assets de tienda**: icono 512×512, feature graphic 1024×500, ≥2 capturas —
  **ninguno existe** en el repo.
- 🟠 **Política de privacidad**: borrador en `docs/PRIVACIDAD.md`; falta **alojarla
  en URL pública** y completar el correo (será **yesithvalencia@gmail.com**).
- ❌ **Formulario Data Safety** y **clasificación por edad** en Play Console.
- ❌ **Producto IAP** `pituapp_pro_lifetime` en Play Console.
- ⏳ **Validación en dispositivo** de las funciones 📱 (guía en
  `docs/PRUEBAS_EN_DISPOSITIVO.md`).

---

## 6. Criterios de aceptación del MVP (ERS §9)

| # | Criterio | Estado |
|---|---|---|
| 1 | Onboarding: primera mascota con cuidados en < 90 s (RNF-19) | ✅ |
| 2 | Registrar cuidados/visitas/vacunas/diagnósticos/peso y verlos con filtros (RF-14–25) | ✅ |
| 3 | Recalcular fechas y **recordatorios locales fiables** respetando límites (RF-12, RF-30–35) | ✅ (en código) — RF-33/RF-35 hechos; **validar en dispositivo** |
| 4 | Panel y PDF bajo plan de pago; límites Free correctos (RF-36–39, RN-01–07) | ✅ |
| 5 | Compra y restauración de Pro en la tienda (RF-48, RF-49) | ⏳ Código listo; **validar en dispositivo** |
| 6 | Exportar/importar respaldo, combinar por UUID, manejo de errores (RF-41–46) | ✅ |
| 7 | Todas las entidades cumplen RD-18 (UUID, timestamps, borrado lógico) | ✅ |
| 8 | Cifra datos locales y declara ausencia de recolección (RNF-10, RNF-12) | 🟠 Cifrado en código; **falta Data Safety** |

**Para dar el MVP por listo:** validar en dispositivo los recordatorios (criterio 3)
y las compras (criterio 5), completar la firma/AAB y el Data Safety (criterio 8),
más los assets y la ficha de tienda.

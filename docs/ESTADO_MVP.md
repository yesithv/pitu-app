# Estado del MVP — PituApp (Fase 1)

> **Fuente única de verdad** del estado funcional de la app frente a la
> especificación (`PetBienestar-Especificacion-Requisitos.md`). Sustituye a la
> matriz del `README.md` como referencia de estado.
>
> Última auditoría: **2026-08-08** (contraste spec ↔ código real + cobertura de
> pruebas unitarias, §6).
> Documentos relacionados: `docs/ROADMAP_V2.md` (Fase 2),
> `docs/WEB_IRONCODING.md` (ficha para la web/tienda),
> `docs/PRODUCCION_PENDIENTES.md` (guía técnica de publicación).

Leyenda: ✅ hecho y verificado en código · 🟠 parcial / interino · ❌ pendiente ·
📱 real solo en móvil (no-op/limitado en web).

---

## 1. Veredicto

**Todos los requisitos funcionales de Fase 1 (RF-01–50) están implementados en
código**, incluidos RF-29 (adjuntos al filesystem), RF-33/RF-35 (recordatorios) y
RNF-06/RNF-13. El **proyecto nativo `android/`** ya existe (compila en CI). **Aún
no está listo para publicar**: falta (a) **validar en dispositivo** las funciones
📱, (b) la **firma de release + AAB** (keystore del usuario), y (c) el paquete de
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
| RF-29 | Archivos en filesystem; BD guarda referencia | ✅ (en código) 📱 | Los bytes van a `<appDocs>/attachments/` (`AttachmentFileStore`) y la fila Drift guarda la ruta; en web siguen en el snapshot. Falta validar en dispositivo |

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

**RF Fase 1: 49 de 49 completos** (en código). Los ítems 📱 (RF-29, RF-33, RF-35,
recordatorios, biometría, compras) quedan pendientes de **validar en dispositivo**.

---

## 3. Requisitos no funcionales (RNF) — Fase 1

| Req | Requisito | Estado | Nota |
|---|---|---|---|
| RNF-01 | Arranque < 1,5 s | ✅ | app ligera, local-first |
| RNF-02 | Guardado/consulta < 100 ms | ✅ | modelo en memoria reactivo |
| RNF-03 | Cualquier dato en ≤ 3 toques | ✅ | |
| RNF-04 | Adjuntos en filesystem, no en BD | ✅ (en código) 📱 | Cumplido vía `AttachmentFileStore` (= RF-29); en web quedan en el snapshot |
| RNF-05 | Compresión + manejo "sin espacio" | ✅ | |
| RNF-06 | Visibilidad del espacio ocupado por documentos | ✅ | Fila "Documentos: X · N archivos" en Ajustes → Datos |
| RNF-07 | Escrituras atómicas (transacciones) | ✅ | Drift (móvil) usa transacción replace-all |
| RNF-08 | Migraciones versionadas sin pérdida | ✅ | `db_codec` v4 + migración de snapshot |
| RNF-09 | Respaldo compatible hacia adelante | ✅ | |
| RNF-10 | BD local cifrada en reposo | ✅ (en código) 📱 | SQLite+SQLCipher; **falta validar en dispositivo** |
| RNF-11 | Bloqueo biométrico opcional | ✅ 📱 | `security/` |
| RNF-12 | No envía datos; declararlo en Data Safety | 🟠 | La app no envía datos; **falta el formulario Data Safety** en Play |
| RNF-13 | Ley 1581: política + exportar + **eliminar todo** | ✅ | Política (borrador) + exportar + **"Borrar todos mis datos"** en Ajustes (con doble confirmación) |
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

**No quedan huecos funcionales de implementación.** Todo lo funcional de Fase 1
está en código, incluidos los últimos pendientes:

- **RF-29 / RNF-04** ✅ — adjuntos en el filesystem (`AttachmentFileStore`); la BD
  guarda la ruta. En móvil el tope por archivo sube a 15 MB (2 MB en web).
- **RNF-06** ✅ — espacio ocupado por documentos en Ajustes → Datos.
- **RNF-13** ✅ — "Borrar todos mis datos" con doble confirmación (conserva el plan).
- **RF-33 / RF-35** ✅ — zona horaria local + alarmas exactas.

Lo único que resta es **verificación y publicación** (no features): validar en
dispositivo (#4), firma/AAB y assets/cumplimiento de tienda (§5). Follow-up técnico
opcional: carga **perezosa** de los bytes de adjuntos (hoy se hidratan en memoria
al cargar).

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

## 6. Cobertura de pruebas unitarias

La lógica de negocio de Fase 1 está cubierta por **pruebas unitarias** que se
ejecutan en CI (`flutter test`) — hoy **132 pruebas en verde** y `flutter analyze`
sin issues. La estrategia es probar el **dominio y la capa de aplicación** (puros,
sin UI): repositorios sobre la base en memoria, servicios y utilidades. Los
plugins nativos (notificaciones, biometría, compras, archivos) se validan en
dispositivo, no por unidad.

| Área / Requisito | Archivo de prueba |
|---|---|
| Programación y cumplimiento (RF-12, RF-36/37) | `scheduling_service_test.dart`, `widget_test.dart` |
| Frecuencias y cálculo de fechas (RF-12) | `care_frequency_test.dart` |
| Ciclo de vida de mascota: archivar/desarchivar/eliminar (RF-03–07) | `pet_repository_test.dart` |
| Ejecución de cuidados: marcar hecho, deshacer, personalizados, cumpleaños (RF-11/14/16/17) | `care_repository_test.dart` |
| Onboarding + catálogo por especie (RF-08, RF-13) | `pet_onboarding_service_test.dart` |
| Línea de tiempo integrada + orden de pesos (RF-22, RF-24) | `clinical_timeline_test.dart` |
| Cambio de estado de diagnóstico (RF-21) | `clinical_status_change_test.dart` |
| Autosugerencia de próxima dosis (RF-19) | `vaccine_scheduling_test.dart` |
| Aviso de variación de peso >10% (RF-23) | `weight_analysis_test.dart` |
| Selección de contenido del reporte (RF-38) | `report_options_test.dart` |
| Respaldo: exportar/importar/combinar por UUID/errores (RF-41–45) | `backup_service_test.dart` |
| Catálogo versionado sin sobrescribir (RF-13, RN-09) | `catalog_updater_test.dart` |
| Límites y entitlement de plan (RN-01–07) | `plan_limits_test.dart`, `entitlement_seed_test.dart` |
| Adjuntos y espacio de documentos (RF-28/29, RNF-06) | `attachment_file_store_test.dart`, `byte_format_test.dart` |
| Persistencia cifrada y códec (RNF-08/10) | `drift_persistence_test.dart`, `db_codec_test.dart`, `snapshot_migration_test.dart` |
| Metadatos de sincronización: UUID, timestamps, borrado lógico (RD-18) | `sync_metadata_test.dart` |
| Cuenta local (RF-53 base) | `local_auth_repository_test.dart` |
| Borrar todos mis datos (RNF-13) | `wipe_service_test.dart` |
| Observabilidad | `crash_reporter_test.dart` |

**Nota de diseño:** para poder validar RF-19 y RF-23 por unidad, su lógica se
extrajo de la UI a `clinical/domain/services/` (`vaccine_scheduling.dart` y
`weight_analysis.dart`); las pantallas solo arman el texto localizado.

**Pendiente de pruebas (no bloqueante):** las pantallas (widgets) no tienen
*widget tests*; los filtros del historial (RF-25) y el gating visual de límites de
plan se validan hoy de forma manual en la web. Es la siguiente ampliación natural
de la suite.

---

## 7. Criterios de aceptación del MVP (ERS §9)

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

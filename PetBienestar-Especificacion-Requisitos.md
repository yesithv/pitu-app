# PetBienestar — Especificación de Requisitos de Software (ERS)

**Versión:** 1.0
**Propósito:** documento de traspaso para iniciar el desarrollo. Contiene requisitos funcionales, reglas de negocio, modelo de datos, requisitos no funcionales y arquitectura técnica. **No incluye especificación visual ni de interfaz** (los prototipos ya existen aparte).
**Producto:** aplicación móvil (Android e iOS) para gestión del cuidado y la salud de mascotas.

---

## 1. Resumen y alcance

PetBienestar permite a una persona llevar el control de los cuidados periódicos y el historial clínico de sus mascotas, con recordatorios automáticos y un panel que compara lo recomendado contra lo efectivamente realizado.

El desarrollo se divide en dos fases:

- **Fase 1 (MVP, este documento como prioridad):** aplicación **local-first, sin backend**. Todos los datos residen en el dispositivo. Sin cuenta de usuario, sin login, sin servidor. Planes Free y Pro (pago único).
- **Fase 2 (posterior):** se incorpora backend, cuenta de usuario, sincronización en la nube, hogar compartido y plan Premium (suscripción). El diseño de la Fase 1 debe construirse **preparado para esta evolución** (ver sección 8).

Este documento especifica **la Fase 1 en detalle** y **la Fase 2 a nivel de requisitos**, marcando cada requisito con su fase.

**Convención de identificadores:** `RF-` requisito funcional, `RN-` regla de negocio, `RNF-` requisito no funcional, `RD-` requisito de datos. La fase se indica como `[F1]`, `[F2]` o `[F1/F2]`.

---

## 2. Actores

| Actor | Descripción | Fase |
|---|---|---|
| **Dueño (usuario local)** | Persona que instala la app y gestiona sus mascotas en el dispositivo. Único actor en Fase 1. | F1 |
| **Cuidador miembro** | Persona invitada a un hogar que comparte el cuidado de las mascotas. | F2 |
| **Administrador de hogar** | Cuidador que creó el hogar; puede invitar y remover miembros. | F2 |
| **Veterinario (lector)** | Accede a un reporte de solo lectura. En F1 recibe un PDF; en F2 puede abrir un link temporal. | F1/F2 |
| **Sistema de notificaciones del SO** | Dispara recordatorios locales programados. | F1 |
| **Pasarela de compras (StoreKit / Play Billing)** | Procesa y valida las compras. | F1/F2 |

---

## 3. Requisitos funcionales

### 3.1 Gestión de mascotas

- **RF-01 [F1]** El usuario puede crear una mascota con: nombre, especie (perro / gato / otro), fecha de nacimiento o edad aproximada, peso inicial (opcional), raza (opcional), foto (opcional).
- **RF-02 [F1]** El usuario puede editar los datos de una mascota.
- **RF-03 [F1]** El usuario puede archivar una mascota. Archivar detiene todos sus recordatorios y cancela sus notificaciones locales, la retira del dashboard y del conteo del plan, y **conserva íntegro** su historial y documentos.
- **RF-04 [F1]** Al archivar, el usuario puede indicar un motivo opcional (falleció / cambió de hogar / otro), sin texto obligatorio.
- **RF-05 [F1]** El usuario puede desarchivar una mascota; al hacerlo se recalculan las próximas fechas de sus cuidados y se reprograman sus notificaciones.
- **RF-06 [F1]** El usuario puede eliminar definitivamente una mascota y todos sus datos, mediante doble confirmación, en una acción separada del archivado.
- **RF-07 [F1]** El usuario puede consultar la lista de mascotas activas y, por separado, la lista de mascotas archivadas (estas en modo lectura).

### 3.2 Catálogo de cuidados y programación

- **RF-08 [F1]** Al crear una mascota, el sistema precarga un **catálogo de cuidados predefinido según la especie**, con frecuencias sugeridas por tarea (ej. desparasitación, vacunas, limpieza dental, baño, corte de uñas, control de peso).
- **RF-09 [F1]** El usuario puede editar la frecuencia de cualquier cuidado.
- **RF-10 [F1]** El usuario puede desactivar un cuidado que no aplica a su mascota.
- **RF-11 [F1]** El usuario puede crear cuidados personalizados (nombre, frecuencia, ícono/tipo), sujeto a los límites del plan (RN-05).
- **RF-12 [F1]** El sistema calcula automáticamente la **próxima fecha** de cada cuidado a partir de su frecuencia y de la última ejecución registrada.
- **RF-13 [F1]** El catálogo predefinido debe estar **versionado**; sus actualizaciones (vía actualización de la app) no deben sobrescribir las personalizaciones del usuario (RN-09).

### 3.3 Registro de ejecución de cuidados

- **RF-14 [F1]** El usuario puede marcar un cuidado como realizado con un solo toque; el sistema lo registra con la fecha actual, recalcula la próxima fecha y reprograma la notificación.
- **RF-15 [F1]** El usuario puede registrar un cuidado con detalle: fecha (por defecto hoy, editable, no futura), notas y adjuntos.
- **RF-16 [F1]** El usuario puede deshacer un registro recién creado.
- **RF-17 [F1]** Cada ejecución queda almacenada en el historial de la mascota.

### 3.4 Historial clínico

- **RF-18 [F1]** El usuario puede registrar una **visita médica**: fecha, veterinario/clínica, motivo, diagnóstico, tratamiento, notas y adjuntos.
- **RF-19 [F1]** El usuario puede registrar una **vacuna**: tipo, fecha de aplicación, próxima dosis (autosugerida y editable), veterinario, adjunto.
- **RF-20 [F1]** El usuario puede registrar un **diagnóstico** con estado (activo / en tratamiento / resuelto / crónico), fecha, notas y visita asociada opcional.
- **RF-21 [F1]** El usuario puede cambiar el estado de un diagnóstico; cada cambio de estado queda registrado en el historial.
- **RF-22 [F1]** El usuario puede registrar el **peso** de la mascota (valor, unidad kg/lb, fecha, nota opcional).
- **RF-23 [F1]** Ante una variación de peso significativa respecto al registro anterior, el sistema muestra un aviso **informativo, no diagnóstico** (no debe interpretarse como consejo médico).
- **RF-24 [F1]** El historial se presenta como una línea de tiempo cronológica inversa que integra visitas, vacunas, diagnósticos, ejecuciones de cuidados y registros de peso.
- **RF-25 [F1]** El usuario puede buscar y filtrar el historial por tipo (visitas, vacunas, diagnósticos, cuidados, peso) y por rango de fechas.

### 3.5 Documentos adjuntos

- **RF-26 [F1]** El usuario puede adjuntar fotos y archivos PDF a visitas, vacunas, registros de cuidado y a la mascota, sujeto a los límites del plan (RN-04).
- **RF-27 [F1]** El usuario puede consultar todos los documentos de una mascota en una galería, con búsqueda y filtro por tipo.
- **RF-28 [F1]** El sistema comprime las imágenes antes de almacenarlas (objetivo orientativo <500 KB por foto).
- **RF-29 [F1]** Los archivos se almacenan en el sistema de archivos de la app; la base de datos guarda únicamente la referencia/ruta.

### 3.6 Recordatorios y notificaciones (locales en F1)

- **RF-30 [F1]** El sistema programa notificaciones locales para cada cuidado según su próxima fecha.
- **RF-31 [F1]** Existen recordatorios: del día, de tarea vencida (persistente hasta marcarla) y anticipados (1/3/7 días antes, esta anticipación configurable es función de plan de pago — RN-06).
- **RF-32 [F1]** Al tocar una notificación, la app abre directamente el cuidado asociado.
- **RF-33 [F1]** El sistema reprograma todas las notificaciones tras: reinstalación, restauración de respaldo, cambio de zona horaria y cambio de fecha del sistema.
- **RF-34 [F1]** El sistema respeta el límite de notificaciones pendientes de iOS (64) mediante programación por ventanas: programa solo las próximas N y reprograma al abrir la app o completar una tarea.
- **RF-35 [F1]** El sistema maneja las restricciones de alarmas exactas y de ahorro de batería de Android según versión y fabricante, e informa al usuario si el permiso de notificaciones está denegado.

### 3.7 Panel recomendado vs. realizado

- **RF-36 [F1]** El sistema calcula, por mascota, un indicador de cumplimiento que compara los cuidados recomendados (catálogo + frecuencia) contra lo efectivamente registrado, clasificando cada cuidado como al día, próximo o atrasado.
- **RF-37 [F1]** El sistema presenta un resumen de cumplimiento por mascota y un estado consolidado. *(Función de plan de pago — RN-07.)*

### 3.8 Reporte para el veterinario

- **RF-38 [F1]** El usuario puede generar en el dispositivo un reporte PDF del historial de una mascota, con selección de contenido: historial completo / solo vacunas / rango de fechas. *(Función de plan de pago — RN-07.)*
- **RF-39 [F1]** El PDF incluye en el encabezado datos identificatorios de la mascota (nombre, especie, raza, edad, peso actual) y la fecha de generación, y se entrega a la hoja de compartir del sistema.
- **RF-40 [F2]** El usuario puede generar un **link de solo lectura** temporal (vencimiento configurable, por defecto 7 días) para que un veterinario consulte el historial sin cuenta; el usuario puede ver los links activos, su contador de accesos y revocarlos. *(Función Premium.)*

### 3.9 Respaldo y portabilidad de datos

- **RF-41 [F1]** El usuario puede exportar un respaldo completo (todos los registros + adjuntos) en un archivo único. **Función gratuita en todos los planes** (RN-08).
- **RF-42 [F1]** El usuario puede importar un respaldo; antes de importar, el sistema muestra un resumen del contenido (número de mascotas, registros, documentos, fecha).
- **RF-43 [F1]** Si al importar ya existen datos, el usuario elige entre **reemplazar todo** (con advertencia) o **combinar** (por defecto); en la combinación, los registros duplicados se detectan por identificador único y no se duplican.
- **RF-44 [F1]** Tras importar, el sistema reprograma todas las notificaciones locales.
- **RF-45 [F1]** El sistema maneja los errores de importación: archivo corrupto, versión de respaldo más reciente que la app instalada, y espacio insuficiente.
- **RF-46 [F1]** El sistema recuerda al usuario, de forma no intrusiva, crear un respaldo (ej. a los 7 días de uso o al registrar la segunda mascota, y mostrando en ajustes el tiempo transcurrido desde el último respaldo).

### 3.10 Planes y compras

- **RF-47 [F1]** El sistema ofrece el plan **Free** (limitado, RN-01) y el plan **Pro** (pago único que desbloquea todas las funciones locales, RN-02).
- **RF-48 [F1]** El sistema procesa la compra de Pro mediante StoreKit (iOS) y Play Billing (Android) y persiste el entitlement localmente.
- **RF-49 [F1]** El usuario puede **restaurar la compra** de Pro (imprescindible para recuperar el entitlement tras reinstalar sin backend).
- **RF-50 [F1]** El sistema muestra el estado del plan actual y una pantalla comparativa de planes; al topar un límite de Free, indica a qué plan pertenece la función bloqueada.
- **RF-51 [F2]** El sistema ofrece el plan **Premium** (suscripción mensual/anual) que habilita las funciones de backend (RN-03).
- **RF-52 [F2]** El sistema valida las suscripciones Premium del lado del servidor.

### 3.11 Cuenta, hogar y sincronización (Fase 2)

- **RF-53 [F2]** El usuario puede crear una cuenta (correo / Google / Apple) e iniciar sesión, con recuperación de contraseña.
- **RF-54 [F2]** Al crear cuenta, el sistema **migra los datos locales existentes** a la cuenta sin pérdida.
- **RF-55 [F2]** Un usuario Premium puede crear un **hogar** y **invitar** a otras personas mediante código o link.
- **RF-56 [F2]** Todos los miembros de un hogar acceden a las mismas mascotas, historial y cuidados, y pueden registrar acciones.
- **RF-57 [F2]** Las acciones y recordatorios generan **notificaciones a todos los miembros** del hogar y un feed de actividad.
- **RF-58 [F2]** El administrador del hogar puede remover miembros y eliminar el hogar.
- **RF-59 [F2]** El sistema sincroniza los datos entre dispositivos y la nube, conservando capacidad de uso offline (local-first).

---

## 4. Reglas de negocio

- **RN-01 [F1] Límites del plan Free:** 1 mascota; máximo 2 adjuntos por mascota; máximo 3 cuidados personalizados por mascota; sin panel de cumplimiento; sin reporte PDF; sin recordatorios anticipados configurables.
- **RN-02 [F1] Plan Pro:** pago **único, de por vida** (no recurrente). Desbloquea: mascotas ilimitadas, adjuntos ilimitados, cuidados personalizados ilimitados, panel de cumplimiento, reporte PDF, recordatorios anticipados configurables.
- **RN-03 [F2] Plan Premium:** suscripción **recurrente** (mensual o anual). Incluye todo lo de Pro más: hogar compartido, respaldo y sincronización en la nube, uso multi-dispositivo y link de solo lectura para veterinario.
- **RN-04 [F1]** El límite de adjuntos se evalúa por mascota y por plan; al alcanzarlo, se ofrece la mejora de plan.
- **RN-05 [F1]** El límite de cuidados personalizados se evalúa por mascota y por plan.
- **RN-06 [F1]** Los recordatorios anticipados configurables son función de plan de pago; en Free existe únicamente el recordatorio del día y el de vencido.
- **RN-07 [F1]** El panel de cumplimiento y el reporte PDF requieren plan de pago (Pro o Premium).
- **RN-08 [F1/F2]** La exportación e importación de respaldo manual es **gratuita en todos los planes**.
- **RN-09 [F1]** Las actualizaciones del catálogo predefinido (por versión de app) no sobrescriben frecuencias, desactivaciones ni cuidados personalizados definidos por el usuario.
- **RN-10 [F1/F2]** El plan Pro se **respeta de por vida**: un usuario Pro que además tome Premium conserva las funciones locales aunque cancele Premium; al cancelar Premium solo pierde las funciones de nube y hogar.
- **RN-11 [F1]** Ninguna acción sensible (archivar mascota, especialmente por fallecimiento) debe disparar un paywall ni una oferta comercial.
- **RN-12 [F1]** Ninguna fecha de ejecución de cuidado o registro clínico puede ser futura.
- **RN-13 [F2]** La eliminación de datos se propaga por borrado lógico para permitir sincronización correcta entre dispositivos.

---

## 5. Modelo de datos

Entidades principales. En Fase 1 residen en la base local del dispositivo.

- **RD-01 [F1] PerfilLocal:** datos del dueño (nombre, foto, preferencias). Sin credenciales.
- **RD-02 [F1] Mascota:** id, nombre, especie, fechaNacimiento, peso, raza, foto, estado (activa/archivada), motivoArchivo, timestamps.
- **RD-03 [F1] TipoCuidado:** id, nombre, ícono/tipo, especieAplicable, frecuenciaSugerida, esPersonalizado, esActivo.
- **RD-04 [F1] Programacion:** id, mascotaId, tipoCuidadoId, frecuencia, proximaFecha.
- **RD-05 [F1] RegistroEjecucion:** id, programacionId, fecha, notas, adjuntos[].
- **RD-06 [F1] VisitaMedica:** id, mascotaId, fecha, veterinario, motivo, diagnostico, tratamiento, notas, adjuntos[].
- **RD-07 [F1] Vacuna:** id, mascotaId, tipo, fechaAplicacion, proximaDosis, veterinario, adjunto.
- **RD-08 [F1] Diagnostico:** id, mascotaId, visitaId (opcional), condicion, fecha, estado (activo/enTratamiento/resuelto/cronico), notas.
- **RD-09 [F1] RegistroPeso:** id, mascotaId, valor, unidad, fecha, nota.
- **RD-10 [F1] DocumentoAdjunto:** id, tipo (foto/pdf), categoria (receta/laboratorio/carnet/otro), ruta, registroAsociadoId, mascotaId.
- **RD-11 [F1] NotificacionLocal:** id, programacionId, fechaProgramada, tipo.
- **RD-12 [F1] EntitlementPlan:** plan (free/pro), origenCompra, fechaCompra.
- **RD-13 [F2] Usuario:** id, credenciales, correo.
- **RD-14 [F2] Hogar:** id, nombre, administradorId.
- **RD-15 [F2] MembresiaHogar:** usuarioId, hogarId, rol.
- **RD-16 [F2] SuscripcionPremium:** usuarioId, estado, periodicidad, fechaRenovacion.
- **RD-17 [F2] LinkVeterinario:** id, mascotaId, url, contenido, vencimiento, contadorAccesos, revocado.

**RD-18 [F1/F2] — Requisitos transversales de todas las entidades (obligatorios desde F1):**
- Identificador **UUID** generado en el cliente (no autoincremental).
- Campos `created_at` y `updated_at`.
- Campo `created_by` reservado (valor local por defecto en F1).
- Borrado **lógico** (`deleted_at`), no físico.

---

## 6. Requisitos no funcionales

### 6.1 Rendimiento
- **RNF-01 [F1]** Arranque en frío hasta dashboard usable en menos de 1,5 s.
- **RNF-02 [F1]** Operaciones de guardado y consulta con respuesta perceptualmente instantánea (<100 ms).
- **RNF-03 [F1]** Cualquier dato accesible en un máximo de 3 toques desde cualquier pantalla.

### 6.2 Almacenamiento
- **RNF-04 [F1]** Adjuntos en el sistema de archivos, no en la base de datos.
- **RNF-05 [F1]** Compresión de imágenes al adjuntar; manejo explícito del caso "sin espacio en el dispositivo".
- **RNF-06 [F1]** Visibilidad del espacio total ocupado por documentos.

### 6.3 Confiabilidad e integridad
- **RNF-07 [F1]** Escrituras en base de datos mediante transacciones atómicas.
- **RNF-08 [F1]** Migraciones de esquema versionadas, sin pérdida de datos entre versiones de la app.
- **RNF-09 [F1]** Formato de respaldo **compatible hacia adelante** (importable en versiones posteriores de la app).

### 6.4 Seguridad y privacidad
- **RNF-10 [F1]** Base de datos local cifrada en reposo.
- **RNF-11 [F1]** Bloqueo biométrico opcional de la app (huella / Face ID).
- **RNF-12 [F1]** En Fase 1 la app **no envía datos a servidores**; debe declararlo correctamente en App Privacy (Apple) y Data Safety (Google).
- **RNF-13 [F1/F2]** Cumplimiento de la Ley 1581 de 2012 (Colombia): política de privacidad, y derecho de exportación y eliminación total de datos.
- **RNF-14 [F2]** Cifrado en tránsito (TLS 1.3) y en reposo (AES-256) en el backend; autenticación y autorización robustas; control de acceso por rol dentro del hogar.
- **RNF-15 [F1/F2]** Validación de compras: local en F1 (con restauración), del lado del servidor en F2.

### 6.5 Compatibilidad y distribución
- **RNF-16 [F1]** Soporte Android e iOS.
- **RNF-17 [F1]** Publicación en App Store y Google Play cumpliendo sus lineamientos de permisos y privacidad.
- **RNF-18 [F1]** En Fase 1, el ciclo de actualización de la app es el único canal de corrección de errores y de actualización del catálogo; el catálogo debe versionarse con cuidado (RN-09).

### 6.6 Usabilidad y calidad
- **RNF-19 [F1]** Un usuario nuevo debe registrar su primera mascota y su primer cuidado en menos de 90 segundos, sin ayuda externa.
- **RNF-20 [F1]** Calidad técnica acorde a Android Vitals (tasa de fallos y ANR bajas, tiempos de carga y consumo de batería controlados).
- **RNF-21 [F1]** Soporte de accesibilidad: tamaños de fuente del sistema y etiquetas de accesibilidad (el detalle visual está en los prototipos).

### 6.7 Localización
- **RNF-22 [F1]** Interfaz en español; arquitectura preparada para internacionalización.

---

## 7. Restricciones técnicas conocidas

- **RT-01** iOS limita a 64 las notificaciones locales pendientes por app (obliga a programación por ventanas — RF-34).
- **RT-02** Android restringe alarmas exactas y aplica optimizaciones de batería que pueden retrasar notificaciones según versión y fabricante (RF-35).
- **RT-03** Sin backend en F1, no existe recuperación de datos ante pérdida del dispositivo salvo por respaldo manual (RF-41 a RF-46).
- **RT-04** Sin backend en F1, el entitlement Pro depende de la restauración de compra de la tienda (RF-49).

---

## 8. Arquitectura técnica

### 8.1 Stack Fase 1 (MVP)
- **Móvil:** Flutter (Android + iOS).
- **Persistencia local:** SQLite / Drift, cifrada.
- **Archivos:** directorio de documentos de la app.
- **Notificaciones:** flutter_local_notifications (sin FCM/APNs).
- **Compras:** StoreKit 2 + Play Billing, validación local.
- **PDF:** generación en el dispositivo.
- **Respaldo:** archivo ZIP con un JSON de registros + carpeta de adjuntos.
- **Backend:** ninguno.

### 8.2 Stack Fase 2 (añadidos)
- **Backend:** Spring Boot 3 + API REST.
- **Base de datos:** PostgreSQL.
- **Archivos en nube:** bucket S3-compatible.
- **Push:** Firebase Cloud Messaging (+ APNs).
- **Sincronización:** local-first, bidireccional al reconectar.
- **Suscripciones:** validación de recibos del lado del servidor.

### 8.3 Principios de arquitectura (obligatorios desde F1)
- **Clean Architecture con patrón repositorio:** la capa de dominio no conoce el origen de los datos (SQLite o API). Incorporar el backend en F2 debe consistir en cambiar la implementación del repositorio, no la lógica de negocio.
- **Preparación para sincronización (RD-18):** UUID de cliente, `created_at`/`updated_at`, `created_by` reservado y borrado lógico en todas las entidades desde el primer día.
- **Formato de respaldo alineado con el contrato de la futura API:** el JSON del respaldo (RF-41) debe diseñarse de modo que sirva de base para la migración a cuenta de la Fase 2 (RF-54).
- **Gestión de estado y capas** según las convenciones del equipo (BLoC u otra), manteniendo la lógica de negocio independiente de la UI.

### 8.4 Camino de migración a Fase 2
El PerfilLocal se convierte en Usuario con cuenta; se introduce Hogar y Membresía; las mascotas locales se suben como primer estado sincronizado; las notificaciones locales conviven con las push; y la app conserva su funcionamiento offline. El entitlement Pro (local) se preserva; Premium se cobra por las capas de servidor.

---

## 9. Criterios de aceptación del MVP (Fase 1)

El MVP se considera completo cuando:

1. Un usuario puede completar el onboarding y tener una mascota con su plan de cuidados precargado en menos de 90 s (RNF-19).
2. Un usuario puede registrar cuidados, visitas, vacunas, diagnósticos y peso, y verlos en el historial con búsqueda y filtros (RF-14 a RF-25).
3. El sistema recalcula próximas fechas y dispara recordatorios locales fiables, respetando los límites de plataforma (RF-12, RF-30 a RF-35).
4. El panel de cumplimiento y el reporte PDF funcionan bajo plan de pago; los límites de Free se aplican correctamente y ofrecen la mejora (RF-36 a RF-39, RN-01 a RN-07).
5. La compra de Pro y su restauración funcionan en ambas tiendas (RF-48, RF-49).
6. La exportación e importación de respaldo funcionan, incluida la combinación por UUID y el manejo de errores (RF-41 a RF-46).
7. Todas las entidades cumplen los requisitos transversales de datos que habilitan la Fase 2 (RD-18).
8. La app cifra los datos locales y declara correctamente la ausencia de recolección de datos (RNF-10, RNF-12).

---

## 10. Fuera del alcance de la Fase 1

Login y cuenta de usuario, hogar compartido, notificaciones entre miembros y feed de actividad, sincronización y respaldo en la nube, uso multi-dispositivo, link de solo lectura para veterinario, plan Premium, rol de veterinario e integración con clínicas. Todo ello corresponde a la Fase 2.

---

## 11. Dependencias y pendientes previos al desarrollo

- Contenido definitivo del **catálogo de cuidados por especie** con frecuencias, validado con criterio veterinario.
- Definición del **esquema JSON versionado** del respaldo y su alineación con el contrato de API de la Fase 2.
- **Precios** de Pro (único) y Premium (mensual/anual) por mercado.
- Textos legales: **política de privacidad** y **términos y condiciones**.
- Verificación de **dominio y marca** "PetBienestar".
- Prototipos de interfaz (ya existentes, fuera de este documento).

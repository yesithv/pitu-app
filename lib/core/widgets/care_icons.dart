import 'package:flutter/material.dart';

import '../../features/care/domain/entities/care_kind.dart';
import '../../features/clinical/domain/entities/timeline_entry.dart';

/// Mapeo constante de cada tipo de cuidado a su ícono (identidad §6): un ícono
/// propio y estable en toda la app, distinguible a 20px.
IconData iconForCareKind(CareKind kind) {
  return switch (kind) {
    CareKind.vaccine => Icons.vaccines_outlined,
    CareKind.deworming => Icons.pest_control_outlined,
    CareKind.dental => Icons.cleaning_services_outlined,
    CareKind.bath => Icons.bathtub_outlined,
    CareKind.nails => Icons.content_cut,
    CareKind.weight => Icons.monitor_weight_outlined,
    CareKind.vetVisit => Icons.medical_services_outlined,
    CareKind.medication => Icons.medication_outlined,
    CareKind.birthday => Icons.cake_outlined,
    CareKind.custom => Icons.pets_outlined,
  };
}

IconData iconForTimelineKind(TimelineKind kind) {
  return switch (kind) {
    TimelineKind.visit => Icons.description_outlined,
    TimelineKind.vaccine => Icons.vaccines_outlined,
    TimelineKind.care => Icons.check_circle_outline,
    TimelineKind.diagnosis => Icons.coronavirus_outlined,
    TimelineKind.weight => Icons.trending_up,
  };
}

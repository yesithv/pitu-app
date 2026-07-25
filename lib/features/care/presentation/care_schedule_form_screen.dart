import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/modal_form_scaffold.dart';
import '../domain/entities/care_frequency.dart';
import '../domain/entities/care_schedule.dart';

/// Editar la frecuencia de un cuidado (RF-09) / crear uno personalizado (RF-11)
/// / desactivar uno que no aplica (RF-10).
class CareScheduleFormScreen extends ConsumerStatefulWidget {
  const CareScheduleFormScreen({super.key, required this.petId, this.scheduleId});

  final String petId;

  /// null = crear cuidado personalizado.
  final String? scheduleId;

  static Future<void> openEdit(
      BuildContext context, String petId, String scheduleId) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          CareScheduleFormScreen(petId: petId, scheduleId: scheduleId),
    ));
  }

  static Future<void> openCreate(BuildContext context, String petId) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CareScheduleFormScreen(petId: petId),
    ));
  }

  @override
  ConsumerState<CareScheduleFormScreen> createState() =>
      _CareScheduleFormScreenState();
}

class _CareScheduleFormScreenState
    extends ConsumerState<CareScheduleFormScreen> {
  final _name = TextEditingController();
  int _every = 1;
  FrequencyUnit _unit = FrequencyUnit.months;
  bool _reminder = true;
  CareSchedule? _existing;

  bool get _isEdit => widget.scheduleId != null;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId != null) {
      final s = ref
          .read(careRepositoryProvider)
          .schedulesForPet(widget.petId)
          .firstWhereOrNull((s) => s.id == widget.scheduleId);
      if (s != null) {
        _existing = s;
        _name.text = s.name;
        _every = s.frequency.every;
        _unit = s.frequency.unit;
        _reminder = s.reminderEnabled;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty && _every > 0;

  CareFrequency get _frequency => CareFrequency(_every, _unit);

  void _save() {
    final repo = ref.read(careRepositoryProvider);
    if (_isEdit && _existing != null) {
      final scheduling = ref.read(schedulingServiceProvider);
      final base = _existing!.lastDoneDate ?? ref.read(clockProvider).now();
      repo.updateSchedule(_existing!.copyWith(
        name: _name.text.trim(),
        frequency: _frequency,
        nextDate: scheduling.nextDateFrom(base, _frequency),
        reminderEnabled: _reminder,
      ));
    } else {
      repo.createCustomCare(
        petId: widget.petId,
        name: _name.text.trim(),
        frequency: _frequency,
      );
    }
    Navigator.of(context).pop();
  }

  void _deactivate() {
    if (_existing != null) {
      ref
          .read(careRepositoryProvider)
          .updateSchedule(_existing!.copyWith(isActive: false));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ModalFormScaffold(
      title: _isEdit ? 'Editar cuidado' : 'Nuevo cuidado',
      saveLabel: _isEdit ? 'Guardar cambios' : 'Crear cuidado',
      onSave: _valid ? _save : null,
      children: [
        const FieldLabel('Nombre del cuidado'),
        AppTextField(
          controller: _name,
          hint: 'Ej. Corte de uñas',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        const FieldLabel('Repetir cada'),
        _FrequencyEditor(
          every: _every,
          unit: _unit,
          onEvery: (v) => setState(() => _every = v),
          onUnit: (u) => setState(() => _unit = u),
        ),
        const SizedBox(height: 18),
        _ReminderRow(
          value: _reminder,
          onChanged: (v) => setState(() => _reminder = v),
        ),
        const SizedBox(height: 18),
        InfoNote('Frecuencia elegida: ${_frequency.label.toLowerCase()}.'),
        if (_isEdit) ...[
          const SizedBox(height: 24),
          _DeactivateButton(onTap: _deactivate),
        ],
      ],
    );
  }
}

class _FrequencyEditor extends StatelessWidget {
  const _FrequencyEditor({
    required this.every,
    required this.unit,
    required this.onEvery,
    required this.onUnit,
  });
  final int every;
  final FrequencyUnit unit;
  final ValueChanged<int> onEvery;
  final ValueChanged<FrequencyUnit> onUnit;

  static const _units = [
    FrequencyUnit.weeks,
    FrequencyUnit.months,
    FrequencyUnit.years,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: c.alt,
                borderRadius: Radii.fieldAll,
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  _StepBtn(
                      icon: Icons.remove,
                      onTap: () => onEvery(every > 1 ? every - 1 : 1)),
                  SizedBox(
                    width: 44,
                    child: Text('$every',
                        textAlign: TextAlign.center,
                        style: AppText.title2(c.text)),
                  ),
                  _StepBtn(icon: Icons.add, onTap: () => onEvery(every + 1)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  for (final u in _units) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onUnit(u),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: u == unit ? c.brand : Colors.transparent,
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            border: Border.all(
                                color: u == unit ? c.brand : c.border),
                          ),
                          child: Text(
                            _label(u),
                            style: AppText.button(
                                    u == unit ? c.onBrand : c.text2)
                                .copyWith(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    if (u != _units.last) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _label(FrequencyUnit u) => switch (u) {
        FrequencyUnit.days => 'Días',
        FrequencyUnit.weeks => 'Semanas',
        FrequencyUnit.months => 'Meses',
        FrequencyUnit.years => 'Años',
      };
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 48,
        child: Icon(icon, color: c.brand, size: 22),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: Radii.cardAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Recordatorio activado', style: AppText.body(c.text))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: c.brand,
          ),
        ],
      ),
    );
  }
}

class _DeactivateButton extends StatelessWidget {
  const _DeactivateButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.visibility_off_outlined, size: 18, color: c.over),
        label: Text('Desactivar este cuidado',
            style: AppText.button(c.over).copyWith(fontSize: 15)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text.dart';
import '../utils/app_dates.dart';
import '../../features/pets/domain/entities/pet.dart';

/// Campo de texto de una línea con el estilo del sistema.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.onChanged,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: AppText.body(c.text),
      decoration: _decoration(context, hint),
    );
  }
}

/// Campo de texto multilínea (notas, tratamiento).
class AppMultilineField extends StatelessWidget {
  const AppMultilineField({
    super.key,
    required this.controller,
    this.hint,
    this.minLines = 3,
  });

  final TextEditingController controller;
  final String? hint;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines + 4,
      textCapitalization: TextCapitalization.sentences,
      style: AppText.body(c.text),
      decoration: _decoration(context, hint),
    );
  }
}

/// Campo de fecha: muestra la fecha seleccionada y abre el selector nativo.
/// Por defecto no admite fechas futuras (RN-12).
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowFuture = false,
    this.todayLabel = true,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool allowFuture;
  final bool todayLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final isToday = value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    final label = (todayLabel && isToday)
        ? 'Hoy, ${AppDates.longDate(value)}'
        : AppDates.longDate(value);

    return InkWell(
      borderRadius: Radii.fieldAll,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: allowFuture ? DateTime(2100) : now,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.alt,
          borderRadius: Radii.fieldAll,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.body(c.text))),
            Icon(Icons.calendar_today_outlined, size: 18, color: c.text3),
          ],
        ),
      ),
    );
  }
}

/// Selector segmentado de unidad de peso (kg / lb).
class WeightUnitToggle extends StatelessWidget {
  const WeightUnitToggle({
    super.key,
    required this.unit,
    required this.onChanged,
  });

  final WeightUnit unit;
  final ValueChanged<WeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget seg(WeightUnit u) {
      final on = u == unit;
      return GestureDetector(
        onTap: () => onChanged(u),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: on ? c.brand : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(9)),
          ),
          child: Text(u.label,
              style: AppText.button(on ? c.onBrand : c.text2).copyWith(fontSize: 15)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.alt,
        borderRadius: Radii.fieldAll,
        border: Border.all(color: c.border),
      ),
      child: Row(children: [seg(WeightUnit.kg), seg(WeightUnit.lb)]),
    );
  }
}

InputDecoration _decoration(BuildContext context, String? hint) {
  final c = context.colors;
  return InputDecoration(
    hintText: hint,
    hintStyle: AppText.body(c.text3),
    filled: true,
    fillColor: c.alt,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: Radii.fieldAll,
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: Radii.fieldAll,
      borderSide: BorderSide(color: c.brand, width: 2),
    ),
  );
}

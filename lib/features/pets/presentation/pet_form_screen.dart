import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/common.dart';
import '../application/pet_onboarding_service.dart';
import '../domain/entities/pet.dart';
import '../domain/entities/species.dart';

/// Alta y edición de mascota (RF-01, RF-02). Un solo paso: nombre, especie,
/// edad, peso y raza. Al crear, precarga el plan de cuidados según la especie.
class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.petId});

  /// Si es no nulo, la pantalla edita esa mascota en vez de crear una nueva.
  final String? petId;

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PetFormScreen()),
    );
  }

  static Future<void> openEdit(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PetFormScreen(petId: petId)),
    );
  }

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _breed = TextEditingController();
  Species _species = Species.dog;
  WeightUnit _unit = WeightUnit.kg;
  Pet? _existing;

  bool get _isEdit => widget.petId != null;

  @override
  void initState() {
    super.initState();
    if (widget.petId != null) {
      final pet = ref.read(petRepositoryProvider).findById(widget.petId!);
      if (pet != null) {
        _existing = pet;
        _name.text = pet.name;
        _species = pet.species;
        _age.text = pet.ageText ?? '';
        _breed.text = pet.breed ?? '';
        _unit = pet.weightUnit;
        if (pet.weight != null) {
          _weight.text = pet.weight == pet.weight!.roundToDouble()
              ? pet.weight!.toInt().toString()
              : pet.weight.toString();
        }
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _breed.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  void _save() {
    final String message;
    if (_isEdit && _existing != null) {
      final updated = _existing!.copyWith(
        name: _name.text.trim(),
        species: _species,
        ageText: _age.text.trim(),
        breed: _breed.text.trim(),
        weight: double.tryParse(_weight.text.replaceAll(',', '.')),
        weightUnit: _unit,
      );
      ref.read(petRepositoryProvider).update(updated);
      message = 'Datos de ${updated.name} actualizados';
    } else {
      final pet = ref.read(petOnboardingServiceProvider).createPet(
            name: _name.text,
            species: _species,
            breed: _breed.text,
            ageText: _age.text,
            weight: double.tryParse(_weight.text.replaceAll(',', '.')),
            weightUnit: _unit,
          );
      message = 'Preparamos el plan de cuidados de ${pet.name} 🐾';
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar mascota' : 'Nueva mascota'),
        leading: const CloseButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const FieldLabel('Nombre'),
                  _TextField(controller: _name, hint: 'Ej. Pitufo', onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  const FieldLabel('Especie'),
                  Row(
                    children: [
                      for (final s in Species.values) ...[
                        Expanded(
                          child: _SpeciesCard(
                            species: s,
                            selected: _species == s,
                            onTap: () => setState(() => _species = s),
                          ),
                        ),
                        if (s != Species.values.last) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Fecha de nacimiento o edad'),
                  _TextField(controller: _age, hint: 'Ej. 4 años'),
                  const SizedBox(height: 16),
                  const FieldLabel('Peso'),
                  Row(
                    children: [
                      Expanded(
                        child: _TextField(
                          controller: _weight,
                          hint: 'valor',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _UnitToggle(
                        unit: _unit,
                        onChanged: (u) => setState(() => _unit = u),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Raza (opcional)'),
                  _TextField(controller: _breed, hint: 'Ej. Labrador'),
                  const SizedBox(height: 18),
                  const InfoNote(
                      'Prepararemos un plan de cuidados según la especie.'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: PrimaryButton(
                label: _isEdit ? 'Guardar' : 'Finalizar',
                onPressed: _valid ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    this.hint,
    this.keyboardType,
    this.onChanged,
  });
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: AppText.body(c.text),
      decoration: InputDecoration(
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
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({
    required this.species,
    required this.selected,
    required this.onTap,
  });
  final Species species;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.brandSoft : Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(
              color: selected ? c.brand : c.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(species.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(species.label,
                  style: AppText.button(selected ? c.brand : c.text2)
                      .copyWith(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unit, required this.onChanged});
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
              style: AppText.button(on ? c.onBrand : c.text2).copyWith(fontSize: 14)),
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

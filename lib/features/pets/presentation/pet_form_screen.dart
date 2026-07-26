import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/form_limits.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/common.dart';
import '../../backup/application/backup_providers.dart';
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
  DateTime? _birthDate;
  String? _photoBase64;
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
        _birthDate = pet.birthDate;
        _photoBase64 = pet.photoBase64;
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

  double? get _parsedWeight =>
      double.tryParse(_weight.text.replaceAll(',', '.'));
  bool get _valid {
    if (_name.text.trim().isEmpty) return false;
    final w = _parsedWeight;
    if (_weight.text.trim().isNotEmpty &&
        (w == null || w <= 0 || w > FormLimits.maxWeight)) {
      return false;
    }
    return true;
  }

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
        birthDate: _birthDate,
        clearBirthDate: _birthDate == null,
        photoBase64: _photoBase64,
        clearPhoto: _photoBase64 == null,
      );
      ref.read(petRepositoryProvider).update(updated);
      ref.read(careRepositoryProvider).syncBirthday(updated.id, _birthDate);
      message = 'Datos de ${updated.name} actualizados';
    } else {
      final pet = ref.read(petOnboardingServiceProvider).createPet(
            name: _name.text,
            species: _species,
            breed: _breed.text,
            ageText: _age.text,
            birthDate: _birthDate,
            weight: double.tryParse(_weight.text.replaceAll(',', '.')),
            weightUnit: _unit,
            photoBase64: _photoBase64,
          );
      ref.read(careRepositoryProvider).syncBirthday(pet.id, _birthDate);
      message = 'Preparamos el plan de cuidados de ${pet.name} 🐾';
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhoto() async {
    final files = ref.read(fileTransferProvider);
    if (!files.canPickFile) {
      _snack('Agregar foto está disponible en la versión web por ahora.');
      return;
    }
    final picked = await files.pickBinaryFile(accept: 'image/*');
    if (picked == null) return;
    if (!picked.mimeType.startsWith('image/')) {
      _snack('Elige una imagen (JPG o PNG).');
      return;
    }
    // Comprime la foto (RF-28); la foto de perfil se reduce más aún.
    final compressed =
        compressImage(picked.bytes, mimeType: picked.mimeType, maxDim: 720);
    const maxBytes = 1536 * 1024; // 1.5 MB
    if (compressed.bytes.length > maxBytes) {
      _snack('La imagen es demasiado grande incluso tras comprimir.');
      return;
    }
    setState(() => _photoBase64 = base64Encode(compressed.bytes));
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 40),
      lastDate: now,
      helpText: 'Cumpleaños de la mascota',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _snack(String message) {
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
                  Center(child: _PhotoPicker(
                    emoji: _species.emoji,
                    photoBase64: _photoBase64,
                    onPick: _pickPhoto,
                    onRemove: _photoBase64 == null
                        ? null
                        : () => setState(() => _photoBase64 = null),
                  )),
                  const SizedBox(height: 20),
                  const FieldLabel('Nombre'),
                  _TextField(
                      controller: _name,
                      hint: 'Ej. Pitufo',
                      maxLength: FormLimits.name,
                      onChanged: (_) => setState(() {})),
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
                  const FieldLabel('Edad aproximada (opcional)'),
                  _TextField(
                      controller: _age,
                      hint: 'Ej. 4 años',
                      maxLength: FormLimits.ageText),
                  const SizedBox(height: 16),
                  const FieldLabel('Cumpleaños (opcional)'),
                  _BirthdayField(
                    value: _birthDate,
                    onPick: _pickBirthday,
                    onClear: () => setState(() => _birthDate = null),
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Peso'),
                  Row(
                    children: [
                      Expanded(
                        child: _TextField(
                          controller: _weight,
                          hint: 'valor',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: FormLimits.weight,
                          onChanged: (_) => setState(() {}),
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
                  _TextField(
                      controller: _breed,
                      hint: 'Ej. Labrador',
                      maxLength: FormLimits.breed),
                  const SizedBox(height: 18),
                  const InfoNote(
                      'Prepararemos un plan de cuidados según la especie. Si '
                      'agregas el cumpleaños, te lo recordaremos cada año 🎂'),
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
    this.maxLength,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      buildCounter: (context,
              {required currentLength, required isFocused, maxLength}) =>
          null,
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

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.emoji,
    required this.photoBase64,
    required this.onPick,
    this.onRemove,
  });
  final String emoji;
  final String? photoBase64;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final has = photoBase64 != null && photoBase64!.isNotEmpty;
    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Stack(
            children: [
              PetAvatar(
                  emoji: emoji, photoBase64: photoBase64, size: 96, dashed: !has),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.bg, width: 2),
                  ),
                  child:
                      Icon(Icons.photo_camera_outlined, size: 16, color: c.onBrand),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onPick,
              child: Text(has ? 'Cambiar foto' : 'Agregar foto',
                  style: AppText.metaStrong(c.brand)),
            ),
            if (onRemove != null)
              TextButton(
                onPressed: onRemove,
                child: Text('Quitar', style: AppText.metaStrong(c.text3)),
              ),
          ],
        ),
      ],
    );
  }
}

class _BirthdayField extends StatelessWidget {
  const _BirthdayField({
    required this.value,
    required this.onPick,
    required this.onClear,
  });
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onPick,
      borderRadius: Radii.fieldAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.alt,
          borderRadius: Radii.fieldAll,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 20, color: c.text3),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value == null ? 'Agregar fecha' : AppDates.longDate(value!),
                style: value == null
                    ? AppText.body(c.text3)
                    : AppText.body(c.text),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 18, color: c.text3),
              )
            else
              Icon(Icons.chevron_right, color: c.text3),
          ],
        ),
      ),
    );
  }
}

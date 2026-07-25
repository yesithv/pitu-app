import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_buttons.dart';
import '../domain/entities/pet.dart';
import 'pets_providers.dart';

/// Archivar mascota (RF-03/04, flujo 9). Deliberadamente sobrio: detiene
/// recordatorios y saca del conteo del plan, pero conserva el historial.
/// Nunca dispara paywall (RN-11).
class ArchivePetScreen extends ConsumerStatefulWidget {
  const ArchivePetScreen({super.key, required this.petId});
  final String petId;

  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArchivePetScreen(petId: petId)),
    );
  }

  @override
  ConsumerState<ArchivePetScreen> createState() => _ArchivePetScreenState();
}

class _ArchivePetScreenState extends ConsumerState<ArchivePetScreen> {
  ArchiveReason? _reason;

  void _archive() {
    ref.read(petRepositoryProvider).archive(widget.petId, reason: _reason);
    // Vuelve a la raíz (sale del detalle de la mascota archivada).
    Navigator.of(context).popUntil((r) => r.isFirst);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Mascota archivada')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pet = ref.watch(petByIdProvider(widget.petId));
    if (pet == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final isDeceased = _reason == ArchiveReason.deceased;

    return Scaffold(
      appBar: AppBar(title: Text('Archivar a ${pet.name}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration:
                              BoxDecoration(color: c.alt, shape: BoxShape.circle),
                          child: Text(pet.species.emoji,
                              style: const TextStyle(fontSize: 34)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Al archivar, se detienen los recordatorios y ${pet.name} sale del panel y del conteo de tu plan.',
                          textAlign: TextAlign.center,
                          style: AppText.body(c.text2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Su historial y documentos se conservan íntegros.',
                          textAlign: TextAlign.center,
                          style: AppText.bodyStrong(c.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Motivo (opcional)', style: AppText.metaStrong(c.text2)),
                  const SizedBox(height: 8),
                  for (final r in ArchiveReason.values) ...[
                    _ReasonOption(
                      reason: r,
                      selected: _reason == r,
                      onTap: () => setState(() => _reason = r),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (isDeceased) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.brandSoft,
                        borderRadius: Radii.cardAll,
                      ),
                      child: Text(
                        'Lamentamos tu pérdida. Guardaremos con cuidado los recuerdos de ${pet.name} por si algún día quieres volver a verlos. 🐾',
                        textAlign: TextAlign.center,
                        style: AppText.body(c.brand),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Column(
                children: [
                  PrimaryButton(
                      label: 'Archivar a ${pet.name}', onPressed: _archive),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Cancelar',
                          style: AppText.button(c.text2).copyWith(fontSize: 15)),
                    ),
                  ),
                  Text('Podrás desarchivarlo cuando quieras.',
                      style: AppText.meta(c.text3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.reason,
    required this.selected,
    required this.onTap,
  });
  final ArchiveReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: Radii.fieldAll,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? c.brandSoft : Colors.transparent,
          borderRadius: Radii.fieldAll,
          border: Border.all(
            color: selected ? c.brand : c.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _Radio(selected: selected),
            const SizedBox(width: 12),
            Text(reason.label,
                style: AppText.button(selected ? c.brand : c.text)
                    .copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: selected ? c.brand : c.borderStrong, width: 2),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

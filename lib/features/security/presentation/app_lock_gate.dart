import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_buttons.dart';
import '../application/security_providers.dart';

/// Compuerta de bloqueo biométrico (RNF-11). Si el bloqueo está activado y la
/// plataforma lo soporta, exige autenticación antes de mostrar la app. En web
/// nunca bloquea (el mecanismo es no-op).
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  bool _locked = false;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final enabled = ref.read(databaseProvider).biometricLockEnabled;
    final lock = ref.read(appLockProvider);
    if (!enabled || !lock.isSupported) {
      setState(() {
        _locked = false;
        _resolved = true;
      });
      return;
    }
    setState(() {
      _locked = true;
      _resolved = true;
    });
    await _authenticate();
  }

  Future<void> _authenticate() async {
    final ok =
        await ref.read(appLockProvider).authenticate('Desbloquea PituApp');
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved || !_locked) return widget.child;

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                child: Icon(Icons.lock_outline, size: 40, color: c.brand),
              ),
              const SizedBox(height: 20),
              Text('PituApp está bloqueada', style: AppText.title2(c.text)),
              const SizedBox(height: 6),
              Text('Desbloquea con tu huella o Face ID.',
                  textAlign: TextAlign.center, style: AppText.body(c.text2)),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Desbloquear', onPressed: _authenticate),
            ],
          ),
        ),
      ),
    );
  }
}

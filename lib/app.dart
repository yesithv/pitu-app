import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/security/presentation/app_lock_gate.dart';
import 'features/shell/home_shell.dart';

/// Navegador raíz, usado para abrir una mascota al tocar una notificación (RF-32).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Raíz de la aplicación PituApp (PetBienestar). Tema claro/oscuro con la
/// identidad "cálido sereno"; sigue el tema del sistema.
class PituApp extends StatelessWidget {
  const PituApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PituApp',
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppLockGate(child: HomeShell()),
    );
  }
}

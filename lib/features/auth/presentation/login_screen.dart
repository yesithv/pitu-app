import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../application/auth_providers.dart';
import '../domain/auth_repository.dart';

/// Pantalla de acceso (Fase 1, cuenta **local**). Permite iniciar sesión o
/// crear una cuenta, y entrar a una demostración con datos de ejemplo.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _Mode { login, register }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _Mode _mode = _Mode.login;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _submitting = false;
  AuthError? _errorCode;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _isRegister => _mode == _Mode.register;

  bool get _valid {
    final emailOk = _isValidEmail(_email.text.trim());
    final passOk = _password.text.length >= 6;
    if (!emailOk || !passOk) return false;
    if (_isRegister) {
      return _name.text.trim().isNotEmpty && _confirm.text == _password.text;
    }
    return _password.text.isNotEmpty;
  }

  void _switchMode(_Mode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _errorCode = null;
    });
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorCode = null;
    });

    final controller = ref.read(sessionControllerProvider.notifier);
    final result = _isRegister
        ? await controller.register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          )
        : await controller.login(
            email: _email.text,
            password: _password.text,
          );

    // En caso de éxito, la sesión cambia y `app.dart` reemplaza esta pantalla.
    if (!result.ok && mounted) {
      setState(() {
        _submitting = false;
        _errorCode = result.errorCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              shrinkWrap: true,
              children: [
                _brandHeader(c),
                const SizedBox(height: 28),
                _modeToggle(c),
                const SizedBox(height: 22),
                if (_isRegister) ...[
                  FieldLabel(l10n.loginFieldName),
                  AppTextField(
                    controller: _name,
                    hint: l10n.loginHintName,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 40,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                ],
                FieldLabel(l10n.loginFieldEmail),
                AppTextField(
                  controller: _email,
                  hint: l10n.loginHintEmail,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  maxLength: 80,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                FieldLabel(l10n.loginFieldPassword),
                AppPasswordField(
                  controller: _password,
                  hint: l10n.loginHintPassword,
                  textInputAction:
                      _isRegister ? TextInputAction.next : TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (!_isRegister) _submit();
                  },
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 16),
                  FieldLabel(l10n.loginFieldConfirmPassword),
                  AppPasswordField(
                    controller: _confirm,
                    hint: l10n.loginHintConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      _submit();
                    },
                  ),
                ],
                if (_errorCode != null) ...[
                  const SizedBox(height: 16),
                  InfoNote(_authErrorText(l10n, _errorCode!),
                      icon: Icons.error_outline, accent: c.over),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isRegister ? l10n.loginCreateAccount : l10n.loginSignIn,
                  onPressed: (_valid && !_submitting) ? _submit : null,
                ),
                const SizedBox(height: 20),
                _demoSection(c),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandHeader(AppColors c) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
          child: Icon(Icons.pets, size: 40, color: c.brand),
        ),
        const SizedBox(height: 18),
        Text(AppLocalizations.of(context)!.appTitle, style: AppText.display(c.text)),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.appTagline,
          textAlign: TextAlign.center,
          style: AppText.body(c.text2),
        ),
      ],
    );
  }

  Widget _modeToggle(AppColors c) {
    Widget seg(String label, _Mode mode) {
      final on = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switchMode(mode),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: on ? c.brand : Colors.transparent,
              borderRadius: Radii.fieldAll,
            ),
            child: Text(
              label,
              style: AppText.button(on ? c.onBrand : c.text2)
                  .copyWith(fontSize: 15),
            ),
          ),
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
      child: Row(
        children: [
          seg(AppLocalizations.of(context)!.loginTabLogin, _Mode.login),
          seg(AppLocalizations.of(context)!.loginTabRegister, _Mode.register),
        ],
      ),
    );
  }

  Widget _demoSection(AppColors c) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: c.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(AppLocalizations.of(context)!.loginOr, style: AppText.meta(c.text3)),
            ),
            Expanded(child: Divider(color: c.border)),
          ],
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: AppLocalizations.of(context)!.loginSeeDemo,
          icon: Icons.play_circle_outline,
          onPressed: _submitting
              ? null
              : () => ref.read(sessionControllerProvider.notifier).enterDemo(),
        ),
        const SizedBox(height: 10),
        InfoNote(AppLocalizations.of(context)!.loginDemoNote),
      ],
    );
  }
}

bool _isValidEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

/// Traduce el motivo del fallo de autenticación al idioma activo.
String _authErrorText(AppLocalizations l10n, AuthError code) => switch (code) {
      AuthError.emptyName => l10n.authEmptyName,
      AuthError.invalidEmail => l10n.authInvalidEmail,
      AuthError.weakPassword => l10n.authWeakPassword,
      AuthError.accountExists => l10n.authAccountExists,
      AuthError.noAccount => l10n.authNoAccount,
      AuthError.invalidCredentials => l10n.authInvalidCredentials,
    };

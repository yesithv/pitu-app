import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/widgets/app_buttons.dart';
import 'package:pitu_app/features/auth/presentation/login_screen.dart';

import 'support/pump_app.dart';

/// Pruebas de widget de la validación del formulario de acceso (RF-53 / Fase 1).
/// No dispara el envío (que tocaría el repositorio de auth): solo verifica que la
/// habilitación del botón refleje las reglas de validación de entrada.
void main() {
  /// El botón principal (único en la pantalla) queda deshabilitado cuando
  /// `onPressed == null`.
  bool submitEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed != null;

  testWidgets('Ingresar: deshabilitado sin datos, habilitado con email y contraseña válidos',
      (tester) async {
    await pumpApp(tester, const LoginScreen());

    // Sin datos, el botón está deshabilitado.
    expect(submitEnabled(tester), isFalse);

    // En modo login hay dos campos: email y contraseña (en ese orden).
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));

    // Email inválido no habilita.
    await tester.enterText(fields.at(0), 'no-es-un-correo');
    await tester.enterText(fields.at(1), '123456');
    await tester.pump();
    expect(submitEnabled(tester), isFalse);

    // Contraseña demasiado corta (<6) no habilita.
    await tester.enterText(fields.at(0), 'ana@correo.com');
    await tester.enterText(fields.at(1), '123');
    await tester.pump();
    expect(submitEnabled(tester), isFalse);

    // Email válido + contraseña de 6+ caracteres habilita el botón.
    await tester.enterText(fields.at(1), '123456');
    await tester.pump();
    expect(submitEnabled(tester), isTrue);
  });

  testWidgets('Crear cuenta: revela nombre y confirmación; el botón exige que las contraseñas coincidan',
      (tester) async {
    await pumpApp(tester, const LoginScreen());

    // Cambiar a la pestaña de registro (única aparición del texto en modo login).
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    // Ahora hay cuatro campos: nombre, email, contraseña y confirmación.
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), 'ana@correo.com');
    await tester.enterText(fields.at(2), '123456');
    await tester.enterText(fields.at(3), '999999'); // no coincide
    await tester.pump();
    expect(submitEnabled(tester), isFalse);

    // Al coincidir la confirmación, el botón se habilita.
    await tester.enterText(fields.at(3), '123456');
    await tester.pump();
    expect(submitEnabled(tester), isTrue);
  });
}

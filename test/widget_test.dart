import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitu_app/main.dart';

void main() {
  testWidgets('Muestra el mensaje Hola Mundo', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('¡Hola Mundo!'), findsOneWidget);
  });
}

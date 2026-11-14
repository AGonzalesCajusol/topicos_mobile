import 'package:flutter_test/flutter_test.dart';
import 'package:doctor/main.dart';

void main() {
  testWidgets('La aplicación inicia correctamente', (tester) async {
    await tester.pumpWidget(const DriverApp());

    expect(find.text('Bienvenido, conductor'), findsOneWidget);
    expect(find.text('Entrar a la demostración'), findsOneWidget);
  });
}

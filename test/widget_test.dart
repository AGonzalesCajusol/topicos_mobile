import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor/main.dart';

void main() {
  testWidgets('RsuApp renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const RsuApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

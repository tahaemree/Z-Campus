import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_online/main.dart';

void main() {
  testWidgets('StartupErrorApp renders title and message',
      (WidgetTester tester) async {
    const title = 'Başlatma Hatası';
    const message = 'Supabase başlatılamadı.';

    await tester.pumpWidget(const StartupErrorApp(
      title: title,
      message: message,
    ));

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text(title), findsOneWidget);
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('StartupErrorApp has visible error affordance',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StartupErrorApp(
      title: 'Konfigürasyon Hatası',
      message: 'SUPABASE_URL tanımlanmamış.',
    ));

    await tester.pump();

    expect(find.byType(Icon), findsWidgets);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

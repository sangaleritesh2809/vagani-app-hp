import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vargani_app/main.dart';
import 'package:vargani_app/providers/auth_provider.dart';
import 'package:vargani_app/providers/language_theme_provider.dart';
import 'package:vargani_app/providers/vargani_data_provider.dart';

void main() {
  testWidgets('VarganiApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => VarganiDataProvider()),
        ],
        child: const VarganiApp(),
      ),
    );

    expect(find.byType(VarganiApp), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sentino/app.dart';
import 'package:sentino/providers/auth_provider.dart';
import 'package:sentino/providers/locale_provider.dart';
import 'package:sentino/providers/theme_provider.dart';
import 'package:sentino/repositories/mock/mock_auth_repository.dart';
import 'package:sentino/routes/app_router.dart';
import 'package:sentino/services/auth_service.dart';
import 'package:sentino/utils/storage.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageUtil(prefs);
    final appRouter = AppRouter(storage: storage);
    final authService = AuthService(
      repository: MockAuthRepository(),
      storage: storage,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService: authService),
          ),
        ],
        child: AgPlayApp(appRouter: appRouter),
      ),
    );

    await tester.pump();
    expect(find.byType(AgPlayApp), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}

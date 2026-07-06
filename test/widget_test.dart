import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_final/main.dart';
import 'package:project_final/presentation/providers/theme_provider.dart';
import 'package:project_final/presentation/providers/auth_provider.dart';
import 'package:project_final/domain/repositories/auth_repository.dart';
import 'package:project_final/domain/repositories/user_repository.dart';
import 'package:project_final/data/repositories_impl/dynamic_repositories.dart';

void main() {
  testWidgets('Splash screen shows brand title', (WidgetTester tester) async {
    final authRepository = DynamicAuthRepository();
    final userRepository = DynamicUserRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<AuthRepository>.value(value: authRepository),
          Provider<UserRepository>.value(value: userRepository),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              authRepository: authRepository,
              userRepository: userRepository,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Initial frame loading
    await tester.pump();

    // Verify that Splash screen components are loaded
    expect(find.text('VIPER PLATFORM'), findsOneWidget);
    expect(find.text('Khởi tạo tương lai của bạn'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/main.dart';
import 'package:stackfit/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home screen shows StackFit and create action', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const StackFitApp(),
      ),
    );

    expect(find.text('StackFit'), findsOneWidget);
    expect(find.text('No workouts yet'), findsOneWidget);
    expect(find.text('Create Workout'), findsWidgets);
    expect(find.byTooltip('History'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/main.dart';
import 'package:stackfit/providers/app_providers.dart';
import 'package:stackfit/screens/plans/plan_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home screen shows StackFit and create action', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StackFitApp(),
      ),
    );

    expect(find.text('StackFit'), findsOneWidget);
    expect(find.text('No workouts yet'), findsOneWidget);
    expect(find.text('Create Workout'), findsWidgets);
    expect(find.byTooltip('History'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('Plans open from Home and Start is Pro-gated', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StackFitApp(),
      ),
    );

    expect(find.text('Browse plans'), findsOneWidget);
    await tester.tap(find.byTooltip('Plans'));
    await tester.pumpAndSettle();

    expect(find.text('Workout plans'), findsOneWidget);
    expect(find.text('Gym'), findsWidgets);
    expect(find.text('Bro Split'), findsOneWidget);

    await tester.tap(find.text('Bro Split'));
    await tester.pumpAndSettle();

    expect(find.text('Chest'), findsOneWidget);
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Chest'));
    await tester.pumpAndSettle();

    expect(find.text(PlanDetailScreen.proMessage), findsOneWidget);
  });

  testWidgets('Settings explains that an account is optional', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StackFitApp(),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      find.textContaining('everything stays on this device'),
      findsOneWidget,
    );
  });
}

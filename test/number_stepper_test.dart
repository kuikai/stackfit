import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/widgets/number_stepper.dart';

void main() {
  testWidgets('plus lands on 999 and will not go past it', (tester) async {
    final value = await _pump(tester, value: 998, max: 999);

    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    expect(value.value, 999);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    expect(value.value, 999);
  });

  testWidgets('a 2.5 kg step that would pass 999 lands on 999', (tester) async {
    final value = await _pump(
      tester,
      value: 997.5,
      step: 2.5,
      decimals: 1,
      max: 999,
    );

    await tester.tap(find.byTooltip('More'));
    await tester.pump();

    expect(value.value, 999);
  });

  testWidgets('minus lands on 0 and will not go below it', (tester) async {
    final value = await _pump(
      tester,
      value: 1,
      step: 2.5,
      decimals: 1,
      max: 999,
    );

    await tester.tap(find.byTooltip('Less'));
    await tester.pump();
    expect(value.value, 0);

    await tester.tap(find.byTooltip('Less'));
    await tester.pump();
    expect(value.value, 0);
  });

  testWidgets('a typed value is clamped into 0 to 999', (tester) async {
    final value = await _pump(tester, value: 12, max: 999);

    await _type(tester, '40');
    expect(value.value, 40);
    expect(find.byType(AlertDialog), findsNothing);

    await _type(tester, '1500');
    expect(value.value, 999);

    await _type(tester, '');
    expect(value.value, 999);

    await _type(tester, '-4');
    expect(value.value, 4);
  });
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

Future<ValueNotifier<double>> _pump(
  WidgetTester tester, {
  required double value,
  double step = 1,
  int decimals = 0,
  num min = 0,
  num? max,
}) async {
  final current = ValueNotifier<double>(value);
  addTearDown(current.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<double>(
          valueListenable: current,
          builder: (context, shown, _) {
            return NumberStepper(
              label: 'Reps',
              value: shown,
              step: step,
              decimals: decimals,
              min: min,
              max: max,
              onChanged: (next) => current.value = next,
            );
          },
        ),
      ),
    ),
  );
  return current;
}

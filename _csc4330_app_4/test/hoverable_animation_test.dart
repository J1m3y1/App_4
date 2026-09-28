import 'package:_csc4330_app_4/ui/animations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _onOpacity(WidgetTester tester) {
  final fade = find
      .ancestor(of: find.text('on'), matching: find.byType(FadeTransition))
      .evaluate()
      .single;
  return (fade.widget as FadeTransition).opacity.value;
}

Future<void> _hoverTo(WidgetTester tester, Offset position) async {
  final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(position);
  await tester.pump();
}

void main() {
  testWidgets('fades hoverOn in on enter, out on exit', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: HoverableAnimation(
          hoverOn: (const Text('on'), const BoxDecoration()),
          hoverOff: (const SizedBox(width: 64, height: 64), const BoxDecoration()),
          duration: const Duration(milliseconds: 50),
        ),
      ),
    ));

    expect(_onOpacity(tester), 0.0);

    await _hoverTo(tester, tester.getCenter(find.byType(HoverableAnimation)));
    await tester.pump(const Duration(milliseconds: 25));
    final midFade = _onOpacity(tester);
    expect(midFade, greaterThan(0.0));
    expect(midFade, lessThan(1.0));

    await tester.pumpAndSettle();
    expect(_onOpacity(tester), 1.0);

    await _hoverTo(tester, const Offset(-100, -100));
    await tester.pumpAndSettle();
    expect(_onOpacity(tester), 0.0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:visual_media/widgets/vm_logo.dart';

void main() {
  testWidgets('VMLogo renders', (WidgetTester tester) async {
    await tester.pumpWidget(const VMLogo(showLabel: true));
    expect(find.text('Visual Media'), findsOneWidget);
  });
}

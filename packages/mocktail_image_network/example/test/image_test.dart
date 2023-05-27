import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

void main() {
  testWidgets('Client will return with a valid image', (tester) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(FakeApp());
      var image = find.image(const NetworkImage(kImageUrl));
      expect(image, findsOneWidget);
      await tester.pump();
      expect(image, findsOneWidget);
    });
  });

  testWidgets(
    'Client will return with failure and error widget will be shown',
    (tester) async {
      await tester.pumpWidget(FakeApp());
      expect(find.image(const NetworkImage(kImageUrl)), findsOneWidget);
      await tester.pump();
      expect(find.text(kErrorText), findsOneWidget);
    },
  );
}

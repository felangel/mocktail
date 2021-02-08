# 🍹 mocktail_image_network

[![Pub](https://img.shields.io/pub/v/mocktail_image_network.svg)](https://pub.dev/packages/mocktail_image_network)
[![build](https://github.com/felangel/mocktail/workflows/build/badge.svg)](https://github.com/felangel/mocktail/actions)
[![coverage](https://raw.githubusercontent.com/felangel/mocktail/main/coverage_badge.svg)](https://github.com/felangel/mocktail/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Mock `Image.network` in your widget tests with confidence using [mocktail](https://pub.dev/packages/mocktail)

---

## How to use

If you want to test a widget with a similar structure to this one:

```dart
class FakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Image.network('https://test.com/logo.png'),
        ),
      ),
    );
  }
}
```

Simply wrap your tests with `mockNetworkImages` and see them turning green ✅
without a problem!

```dart
void main() {
  testWidgets('can use mocktail for network images', (tester) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(FakeApp());
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
```

### Why should you use mocktail_image_network

If your application uses [Image.network](https://api.flutter.dev/flutter/widgets/Image/Image.network.html)
to present images hosted in a URL, you will notice that your widget tests fail
with the following error:

```bash
══╡ EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE ╞════════════════════════════════════════════════════
The following NetworkImageLoadException was thrown resolving an image codec:
HTTP request failed, statusCode: 400,
https://test.com/logo.png

When the exception was thrown, this was the stack:
#0      NetworkImage._loadAsync (package:flutter/src/painting/_network_image_io.dart:99:9)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)
...

Image provider:
  NetworkImage("https://test.com/logo.png",
  scale: 1.0)
Image key:
  NetworkImage("https://test.com/logo.png",
  scale: 1.0)
════════════════════════════════════════════════════════════════════════════════════════════════════
Test failed. See exception logs above.
The test description was: can use mocktail for network images

Warning: At least one test in this suite creates an HttpClient. When
running a test suite that uses TestWidgetsFlutterBinding, all HTTP
requests will return status code 400, and no network request will
actually be made. Any test expecting a real network connection and
status code will fail.
To test code that needs an HttpClient, provide your own HttpClient
implementation to the code under test, so that your test can
consistently provide a testable response to the code under test.
```

This means that `Image.network` is attempting to make a network call during the
execution of your tests, which is not allowed.

When using `mocktail_image_network`, the internal HTTP client will be mocked,
providing a controlled behavior that does not require making a real network
call, allowing you to execute your tests with confidence.

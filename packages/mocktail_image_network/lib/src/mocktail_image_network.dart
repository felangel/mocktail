import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';

/// {@template mocktail_image_network}
/// Utility method that allows you to execute a widget test when you pump a
/// widget that contains an `Image.network` node in its tree.
///
/// For example, if you have the following app:
///
/// ```dart
/// class FakeApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         body: Center(
///           child: Image.network(
///             'https://uploads-ssl.webflow.com/5ee12d8d7f840543bde883de/5eec278f49a4916759d679aa_vgv-wordmark-black.svg',
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// You can test it like this:
///
/// ```dart
/// void main() {
///   testWidgets('can use mocktail for network images', (tester) async {
///     await mockNetworkImages(() async {
///       await tester.pumpWidget(FakeApp());
///       expect(find.byType(Image), findsOneWidget);
///     });
///   });
/// }
/// ```
/// {@endtemplate}
T mockNetworkImages<T>(T Function() body) {
  return HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => _createHttpClient(),
  );
}

class _MockHttpClient extends Mock implements HttpClient {
  _MockHttpClient() {
    registerFallbackValue((List<int> _) {});
    registerFallbackValue(Uri());
  }
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

HttpClient _createHttpClient() {
  final client = _MockHttpClient();
  final request = _MockHttpClientRequest();
  final response = _MockHttpClientResponse();
  final headers = _MockHttpHeaders();
  when(() => response.compressionState)
      .thenReturn(HttpClientResponseCompressionState.notCompressed);
  when(() => response.contentLength).thenReturn(_transparentPixelPng.length);
  when(() => response.statusCode).thenReturn(HttpStatus.ok);
  when(
    () => response.listen(
      any(),
      onDone: any(named: 'onDone'),
      onError: any(named: 'onError'),
      cancelOnError: any(named: 'cancelOnError'),
    ),
  ).thenAnswer((invocation) {
    final onData =
        invocation.positionalArguments[0] as void Function(List<int>);
    final onDone = invocation.namedArguments[#onDone] as void Function()?;
    return Stream<List<int>>.fromIterable(<List<int>>[_transparentPixelPng])
        .listen(onData, onDone: onDone);
  });
  when(() => request.headers).thenReturn(headers);
  when(request.close).thenAnswer((_) async => response);
  when(() => client.getUrl(any())).thenAnswer((_) async => request);
  return client;
}

final _transparentPixelPng = base64Decode(
  '''iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==''',
);

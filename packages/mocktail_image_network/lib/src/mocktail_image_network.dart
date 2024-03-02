import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';

/// Signature for a function that returns a [Uint8List] for a given [Uri].
typedef ImageMockProvider = Uint8List Function(Uri uri);

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
T mockNetworkImages<T>(T Function() body, {Uint8List? imageBytes}) {
  return mockNetworkImagesWith(
    body,
    provider: (uri) => imageBytes ?? _defaultMockProvider(uri),
  );
}

/// {@macro mocktail_image_network}
T mockNetworkImagesWith<T>(
  T Function() body, {
  ImageMockProvider provider = _defaultMockProvider,
}) {
  return HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => _createHttpClient(provider),
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

HttpClient _createHttpClient(ImageMockProvider mockProvider) {
  final client = _MockHttpClient();
  when(() => client.getUrl(any())).thenAnswer(
    (invokation) async => _createRequest(
      invokation.positionalArguments.first as Uri,
      mockProvider,
    ),
  );
  return client;
}

HttpClientRequest _createRequest(
  Uri uri,
  ImageMockProvider mockProvider,
) {
  final request = _MockHttpClientRequest();
  final headers = _MockHttpHeaders();
  when(() => request.headers).thenReturn(headers);
  when(request.close).thenAnswer(
    (invokation) async => _createResponseForUri(uri, mockProvider),
  );

  return request;
}

HttpClientResponse _createResponseForUri(
  Uri uri,
  ImageMockProvider mockProvider,
) {
  final response = _MockHttpClientResponse();
  final headers = _MockHttpHeaders();

  final data = mockProvider(uri);

  when(() => response.compressionState)
      .thenReturn(HttpClientResponseCompressionState.notCompressed);
  when(() => response.contentLength).thenReturn(data.length);
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
    return Stream<List<int>>.fromIterable(<List<int>>[data])
        .listen(onData, onDone: onDone);
  });
  when(() => response.headers).thenReturn(headers);

  return response;
}

Uint8List _defaultMockProvider(Uri uri) {
  final extension = uri.path.split('.').last;
  return _mockedResponses[extension] ?? _transparentPixelPng;
}

final _mockedResponses = <String, Uint8List>{
  'png': _transparentPixelPng,
  'svg': base64Decode(
    '''PHN2ZyB3aWR0aD0nMTAwJyBoZWlnaHQ9JzEwMCcgdmlld0JveD0nMCAwIDEgMCAxMDAnIC8+''',
  ),
};

final _transparentPixelPng = base64Decode(
  '''iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==''',
);

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';

/// Signature for a function that returns a `List<int>` for a given [Uri].
typedef ImageResolver = List<int> Function(Uri uri);

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
T mockNetworkImages<T>(
  T Function() body, {
  Uint8List? imageBytes,
  ImageResolver? imageResolver,
}) {
  assert(
    imageBytes == null || imageResolver == null,
    'One of imageBytes or imageResolver can be provided, but not both.',
  );
  return HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => _createHttpClient(
      imageResolver ??= _defaultImageResolver(imageBytes),
    ),
  );
}

class _MockHttpClient extends Mock implements HttpClient {
  _MockHttpClient() {
    registerFallbackValue((List<int> _) {});
    registerFallbackValue(Uri());
    registerFallbackValue(const Stream<List<int>>.empty());
  }
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

HttpClient _createHttpClient(ImageResolver imageResolver) {
  final client = _MockHttpClient();

  when(() => client.getUrl(any())).thenAnswer(
    (invokation) async => _createRequest(
      invokation.positionalArguments.first as Uri,
      imageResolver,
    ),
  );
  when(() => client.openUrl(any(), any())).thenAnswer(
    (invokation) async => _createRequest(
      invokation.positionalArguments.last as Uri,
      imageResolver,
    ),
  );

  return client;
}

HttpClientRequest _createRequest(Uri uri, ImageResolver imageResolver) {
  final request = _MockHttpClientRequest();
  final headers = _MockHttpHeaders();

  when(() => request.headers).thenReturn(headers);
  when(
    () => request.addStream(any()),
  ).thenAnswer((invocation) {
    final stream = invocation.positionalArguments.first as Stream<List<int>>;
    return stream.fold<List<int>>(
      <int>[],
      (previous, element) => previous..addAll(element),
    );
  });
  when(
    request.close,
  ).thenAnswer((_) async => _createResponse(uri, imageResolver));

  return request;
}

HttpClientResponse _createResponse(Uri uri, ImageResolver imageResolver) {
  final response = _MockHttpClientResponse();
  final headers = _MockHttpHeaders();
  final data = imageResolver(uri);

  when(() => response.headers).thenReturn(headers);
  when(() => response.contentLength).thenReturn(data.length);
  when(() => response.statusCode).thenReturn(HttpStatus.ok);
  when(() => response.isRedirect).thenReturn(false);
  when(() => response.redirects).thenReturn([]);
  when(() => response.persistentConnection).thenReturn(false);
  when(() => response.reasonPhrase).thenReturn('OK');
  when(
    () => response.compressionState,
  ).thenReturn(HttpClientResponseCompressionState.notCompressed);
  when(
    () => response.handleError(any(), test: any(named: 'test')),
  ).thenAnswer((_) => Stream<List<int>>.value(data));
  when(
    () => response.listen(
      any(),
      onDone: any(named: 'onDone'),
      onError: any(named: 'onError'),
      cancelOnError: any(named: 'cancelOnError'),
    ),
  ).thenAnswer((invocation) {
    final onData =
        invocation.positionalArguments.first as void Function(List<int>);
    final onDone = invocation.namedArguments[#onDone] as void Function()?;
    return Stream<List<int>>.fromIterable(
      <List<int>>[data],
    ).listen(onData, onDone: onDone);
  });
  return response;
}

ImageResolver _defaultImageResolver(Uint8List? imageBytes) {
  if (imageBytes != null) return (_) => imageBytes;

  return (uri) {
    final extension = uri.path.split('.').last;
    return _mockedResponses[extension] ?? _transparentPixelPng;
  };
}

final _mockedResponses = <String, List<int>>{
  'png': _transparentPixelPng,
  'svg': _emptySvg,
};

final _emptySvg = '<svg viewBox="0 0 10 10" />'.codeUnits;
final _transparentPixelPng = base64Decode(
  '''iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==''',
);

import 'dart:convert';
import 'dart:io';

import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:test/test.dart';

void main() {
  group('mockNetworkImages', () {
    test(
      'should properly mock getUrl and complete without exceptions',
      () async {
        await mockNetworkImages(() async {
          final expectedData = base64Decode(
            '''iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==''',
          );
          final client = HttpClient()..autoUncompress = false;
          final request = await client.getUrl(Uri.https(''));
          final response = await request.close();
          final data = <int>[];

          response.listen(data.addAll);

          // Wait for all microtasks to run
          await Future<void>.delayed(Duration.zero);

          expect(data, equals(expectedData));
        });
      },
    );

    test('should properly pass through onDone', () async {
      await mockNetworkImages(() async {
        final client = HttpClient()..autoUncompress = false;
        final request = await client.getUrl(Uri.https(''));
        final response = await request.close();
        var onDoneCalled = false;
        void onDone() => onDoneCalled = true;

        response.listen((_) {}, onDone: onDone);

        // Wait for all microtasks to run
        await Future<void>.delayed(Duration.zero);

        expect(onDoneCalled, isTrue);
      });
    });

    test('should properly use custom imageBytes', () async {
      final greenPixel = base64Decode(
        '''iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M/wHwAEBgIApD5fRAAAAABJRU5ErkJggg==''',
      );
      await mockNetworkImages(
        () async {
          final client = HttpClient()..autoUncompress = false;
          final request = await client.getUrl(Uri.https(''));
          final response = await request.close();
          final data = <int>[];

          response.listen(data.addAll);

          // Wait for all microtasks to run
          await Future<void>.delayed(Duration.zero);

          expect(data, equals(greenPixel));
        },
        imageBytes: greenPixel,
      );
    });

    test(
      'should properly mock svg response and complete without exceptions',
      () async {
        await mockNetworkImages(() async {
          final expectedData = '<svg viewBox="0 0 100 100" />'.codeUnits;
          final client = HttpClient()..autoUncompress = false;
          final request =
              await client.openUrl('GET', Uri.https('', '/image.svg'));
          await request.addStream(Stream.value(<int>[]));
          final response = await request.close();
          final data = <int>[];

          response.listen(data.addAll);

          // Wait for all microtasks to run
          await Future<void>.delayed(Duration.zero);

          expect(data, equals(expectedData));
        });
      },
    );

    test('should properly use custom imageMockProvider', () async {
      final bluePixel = base64Decode(
        '''iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIW2NgYPj/HwADAgH/eL9GtQAAAABJRU5ErkJggg==''',
      );

      await mockNetworkImages(
        () async {
          final client = HttpClient()..autoUncompress = false;
          final request = await client.getUrl(Uri.https(''));
          final response = await request.close();
          final data = <int>[];

          response.listen(data.addAll);

          // Wait for all microtasks to run
          await Future<void>.delayed(Duration.zero);

          expect(data, equals(bluePixel));
        },
        imageMockProvider: (uri) => bluePixel,
      );
    });
  });
}

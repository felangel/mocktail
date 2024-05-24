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
          final expectedData = base64Decode(
            '''PHN2ZyB3aWR0aD0nMTAwJyBoZWlnaHQ9JzEwMCcgdmlld0JveD0nMCAwIDEgMCAxMDAnIC8+''',
          );
          final client = HttpClient()..autoUncompress = false;
          final request = await client.getUrl(Uri.https('', '/image.svg'));
          final response = await request.close();
          final data = <int>[];

          response.listen(data.addAll);

          // Wait for all microtasks to run
          await Future<void>.delayed(Duration.zero);

          expect(data, equals(expectedData));
        });
      },
    );
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

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

    test('should properly mock svg response', () async {
      await mockNetworkImages(() async {
        final expectedData = '<svg viewBox="0 0 10 10" />'.codeUnits;
        final client = HttpClient()..autoUncompress = false;
        final request = await client.openUrl(
          'GET',
          Uri.https('', '/image.svg'),
        );
        await request.addStream(Stream.value(<int>[]));
        final response = await request.close();
        final data = <int>[];

        response.listen(data.addAll);

        // Wait for all microtasks to run
        await Future<void>.delayed(Duration.zero);

        expect(response.redirects, isEmpty);
        expect(data, equals(expectedData));
      });
    });

    test('should properly use custom imageResolver', () async {
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
        imageResolver: (_) => bluePixel,
      );
    });

    test(
        'should throw assertion error '
        'when both imageBytes and imageResolver are used.', () async {
      final bluePixel = base64Decode(
        '''iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIW2NgYPj/HwADAgH/eL9GtQAAAABJRU5ErkJggg==''',
      );
      expect(
        () => mockNetworkImages(
          () {},
          imageBytes: bluePixel,
          imageResolver: (_) => bluePixel,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            'One of imageBytes or imageResolver can be provided, but not both.',
          ),
        ),
      );
    });

    testWidgets('can use mocktail for network images', (tester) async {
      await mockNetworkImages(() async => tester.pumpWidget(const _App()));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('network image renders correctly (red)', (tester) async {
      final redSquare = base64Decode(
        '''iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8AARIQB46hC+ioEAGX8E/cKr6qsAAAAAElFTkSuQmCC''',
      );
      await mockNetworkImages(
        () async {
          await tester.runAsync(() async {
            await tester.pumpWidget(const _App());
            await _waitForPaint();
          });
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(Image),
            matchesGoldenFile('mock_red_network_image.png'),
          );
        },
        imageBytes: redSquare,
      );
    });

    testWidgets('network image renders correctly (green)', (tester) async {
      final greenSquare = base64Decode(
        '''iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFElEQVR42mNk+A+ERADGUYX0VQgAXAYT9xTSUocAAAAASUVORK5CYII=''',
      );
      await mockNetworkImages(
        () async {
          await tester.runAsync(() async {
            await tester.pumpWidget(const _App());
            await _waitForPaint();
          });
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(Image),
            matchesGoldenFile('mock_green_network_image.png'),
          );
        },
        imageBytes: greenSquare,
      );
    });

    testWidgets('network image renders correctly (blue)', (tester) async {
      final blueSquare = base64Decode(
        '''iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNkYPj/n4EIwDiqkL4KAVIQE/f1/NxEAAAAAElFTkSuQmCC''',
      );
      await mockNetworkImages(
        () async {
          await tester.runAsync(() async {
            await tester.pumpWidget(const _App());
            await _waitForPaint();
          });
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(Image),
            matchesGoldenFile('mock_blue_network_image.png'),
          );
        },
        imageBytes: blueSquare,
      );
    });
  });
}

Future<void> _waitForPaint() {
  return Future<void>.delayed(const Duration(milliseconds: 50));
}

class _App extends StatelessWidget {
  const _App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Image.network(
            // URL to the png Flutter logo from https://flutter.dev/brand
            'https://storage.googleapis.com/cms-storage-bucket/c823e53b3a1a7b0d36a9.png',
          ),
        ),
      ),
    );
  }
}

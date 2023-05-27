import 'dart:convert';

import 'package:flutter/material.dart';
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
          final client = debugNetworkImageHttpClientProvider!()
            ..autoUncompress = false;
          final request = await client.getUrl(Uri.https('', ''));
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
        final client = debugNetworkImageHttpClientProvider!()
          ..autoUncompress = false;
        final request = await client.getUrl(Uri.https('', ''));
        final response = await request.close();
        var onDoneCalled = false;
        final onDone = () {
          onDoneCalled = true;
        };

        response.listen((_) {}, onDone: onDone);

        // Wait for all microtasks to run
        await Future<void>.delayed(Duration.zero);

        expect(onDoneCalled, isTrue);
      });
    });
  });
}

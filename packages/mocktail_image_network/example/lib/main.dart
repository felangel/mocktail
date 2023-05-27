import 'package:flutter/material.dart';

/// Sample app used to showcase `mocktail_image_network`
class FakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Image.network(
            kImageUrl,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return const Text(kErrorText);
            },
          ),
        ),
      ),
    );
  }
}

/// public image url for testing
const kImageUrl = 'https://randmom-uri.com';

/// public error text for testing
const kErrorText = 'You are Doomed!';

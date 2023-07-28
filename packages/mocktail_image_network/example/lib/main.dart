import 'package:flutter/material.dart';

/// {@template fake_app}
/// Sample app used to showcase `mocktail_image_network`
/// {@endtemplate}
class FakeApp extends StatelessWidget {
  /// {@macro fake_app}
  const FakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Image.network(
            // URL to the Flutter logo from https://flutter.dev/brand
            'https://storage.googleapis.com/cms-storage-bucket/c823e53b3a1a7b0d36a9.png',
          ),
        ),
      ),
    );
  }
}

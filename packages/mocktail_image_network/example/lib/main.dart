import 'package:flutter/material.dart';

/// Sample app used to showcase `mocktail_image_network`
class FakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Image.network(
            'https://uploads-ssl.webflow.com/5ee12d8d7f840543bde883de/5eec278f49a4916759d679aa_vgv-wordmark-black.svg',
          ),
        ),
      ),
    );
  }
}

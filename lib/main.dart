import 'package:flutter/material.dart';
import 'package:playlist_app/playlistGenerator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DeviceInfoWidget(),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:ios_inspect/ios_inspect.dart';

void main() => runApp(const IpaMinApp());

class IpaMinApp extends StatelessWidget {
  const IpaMinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF070A16),
        body: SizedBox.expand(child: NativeInspectHost()),
      ),
    );
  }
}

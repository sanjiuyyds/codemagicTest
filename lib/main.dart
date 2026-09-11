import 'package:flutter/cupertino.dart';
import 'package:ios_inspect/ios_inspect.dart';

void main() => runApp(const IpaMinApp());

class IpaMinApp extends StatelessWidget {
  const IpaMinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: Color(0x00000000),
        child: SizedBox.expand(child: NativeInspectHost()),
      ),
    );
  }
}

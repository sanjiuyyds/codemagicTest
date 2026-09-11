import 'package:flutter/material.dart';

void main() => runApp(const IpaMinApp());

class IpaMinApp extends StatelessWidget {
  const IpaMinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SmokeTestPage(),
    );
  }
}

class SmokeTestPage extends StatefulWidget {
  const SmokeTestPage({super.key});

  @override
  State<SmokeTestPage> createState() => _SmokeTestPageState();
}

class _SmokeTestPageState extends State<SmokeTestPage> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'IPA 云编译测试',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'com.sanjiuyyds.ipa_min',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
                const SizedBox(height: 32),
                Text(
                  '$_taps',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => setState(() => _taps += 1),
                  child: const Text('点一下'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class IosInspect {
  static const viewType = 'ipa_min/root';
}

class NativeInspectHost extends StatelessWidget {
  const NativeInspectHost({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const ColoredBox(
        color: Color(0xFFF2F2F7),
        child: Center(
          child: Text('仅支持 iPhone'),
        ),
      );
    }

    return const UiKitView(
      viewType: IosInspect.viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: <String, dynamic>{},
      creationParamsCodec: StandardMessageCodec(),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
    );
  }
}

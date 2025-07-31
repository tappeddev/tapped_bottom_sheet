import 'package:flutter/cupertino.dart';

class ScrollableBottomSheetData extends InheritedWidget {
  final double animationValue;
  final double currentHeight;

  const ScrollableBottomSheetData({
    super.key,
    required this.animationValue,
    required this.currentHeight,
    required super.child,
  });

  static ScrollableBottomSheetData of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<ScrollableBottomSheetData>();
    assert(result != null, 'No BottomSheetAnimation found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ScrollableBottomSheetData oldWidget) {
    return animationValue != oldWidget.animationValue ||
        currentHeight != oldWidget.currentHeight;
  }
}

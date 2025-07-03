import 'package:flutter/cupertino.dart';

class ScrollableBottomSheetData extends InheritedWidget {
  final ScrollController scrollController;

  const ScrollableBottomSheetData({
    super.key,
    required super.child,
    required this.scrollController,
  });

  static ScrollableBottomSheetData of(BuildContext context) {
    final ScrollableBottomSheetData? result = context.dependOnInheritedWidgetOfExactType<ScrollableBottomSheetData>();
    assert(result != null, 'No ScrollableBottomSheetData found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ScrollableBottomSheetData old) {
    return scrollController != old.scrollController;
  }
}

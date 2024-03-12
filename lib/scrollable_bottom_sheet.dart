import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:non_uniform_border/non_uniform_border.dart';
import 'package:tapped_bottom_sheet/gesture_listener.dart';

typedef ScrollableBottomSheetBuilder = Widget Function(
  BuildContext context,
  ScrollController scrollController,
);

const double _kMinFlingVelocity = 600.0;
const double _kCompleteFlingVelocity = 4000.0;

class ScrollableBottomSheet extends StatefulWidget {
  final double maxHeight;
  final double minHeight;
  final List<double> snapPositions;
  final void Function(double animation, double height)? onSizeChanged;
  final ScrollableBottomSheetBuilder builder;
  final Duration animationDuration;
  final double? initialPosition;

  final double borderRadiusTop;

  final Color borderColor;

  final bool canDrag;

  final Color backgroundColor;
  final List<BoxShadow>? shadows;

  final double minFlingVelocity;

  final double completeFlingVelocity;

  const ScrollableBottomSheet({
    super.key,
    required this.maxHeight,
    required this.minHeight,
    required this.builder,
    this.snapPositions = const <double>[],
    this.canDrag = true,
    this.animationDuration = const Duration(milliseconds: 350),
    this.onSizeChanged,
    this.initialPosition,
    required this.borderRadiusTop,
    required this.borderColor,
    required this.backgroundColor,
    this.shadows,
    this.minFlingVelocity = _kMinFlingVelocity,
    this.completeFlingVelocity = _kCompleteFlingVelocity,
  });

  @override
  State<ScrollableBottomSheet> createState() => ScrollableBottomSheetState();

  static ScrollableBottomSheetState? of(BuildContext context) {
    return context.findAncestorStateOfType<ScrollableBottomSheetState>();
  }
}

class ScrollableBottomSheetState extends State<ScrollableBottomSheet>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  var _isScrollingEnabled = false;
  var _isScrollingBlocked = false;

  Drag? _drag;

  ScrollHoldController? _hold;

  Tween<double> get _sizeTween =>
      Tween(begin: widget.minHeight, end: widget.maxHeight);

  bool get _isPanelOpen => _animationController.value == 1.0;

  double _pixelToValue(double pixels) {
    return (pixels - widget.minHeight) / (widget.maxHeight - widget.minHeight);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: widget.initialPosition == null
          ? 0.0
          : _pixelToValue(widget.initialPosition!),
    )..addListener(_notifyScrollListeners);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        BorderRadius.vertical(top: Radius.circular(widget.borderRadiusTop));

    return GestureListener(
      canDrag: widget.canDrag,
      onVerticalDragUpdate: (details) => _onDragUpdate(details),
      onVerticalDragEnd: (details) => _onDragEnd(details),
      onVerticalDragCancel: () => _handleDragCancel(),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: widget.shadows,
            borderRadius: borderRadius,
            color: widget.backgroundColor,
          ),
          // Use a foreground decoration to make sure we don't allocate more height.
          foregroundDecoration: ShapeDecoration(
            shape: NonUniformBorder(
              topWidth: 2,
              color: widget.borderColor,
              borderRadius: borderRadius,
            ),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SizedBox(
                  height: _sizeTween.transform(_animationController.value),
                  child: child,
                );
              },
              child: Builder(
                builder: (context) =>
                    widget.builder(context, _scrollController),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // region drag updates

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = details.delta;
    final primaryDelta = delta.dy;

    if (_isScrollingEnabled && _isPanelOpen) {
      // _drag might be null if the drag activity ended and called _disposeDrag.
      assert(_hold == null || _drag == null);
      _drag?.update(details);
      if (_scrollController.hasClients &&
          _scrollController.position.pixels <= 0 &&
          details.primaryDelta! > 0) {
        setState(() => _isScrollingEnabled = false);
        _handleDragCancel();
        if (_scrollController.position.pixels != 0.0) {
          _scrollController.position.setPixels(0.0);
        }
      }
      return;
    }

    // only slide the panel if scrolling is not enabled
    if (!_isScrollingEnabled && !_isScrollingBlocked) {
      _animationController.value -=
          primaryDelta / (widget.maxHeight - widget.minHeight);
    }

    // if the panel is open and the user hasn't scrolled, we need to determine
    // whether to enable scrolling if the user swipes up, or disable closing and
    // begin to close the panel if the user swipes down
    if (_isPanelOpen &&
        _scrollController.hasClients &&
        _scrollController.offset <= 0) {
      final scrollingEnabled = primaryDelta < 0;

      setState(() => _isScrollingEnabled = scrollingEnabled);

      if (scrollingEnabled) {
        final startDetails = DragStartDetails(
          sourceTimeStamp: details.sourceTimeStamp,
          globalPosition: details.globalPosition,
        );
        _hold = _scrollController.position.hold(_disposeHold);
        _drag = _scrollController.position.drag(startDetails, _disposeDrag);
      }
    }
  }

  // endregion

  // region animation and scroll

  void _onScroll() {
    if (!_isScrollingEnabled || _isScrollingBlocked) {
      _scrollController.jumpTo(0);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isScrollingBlocked) return;

    // let the current animation finish before starting a new one
    if (_animationController.isAnimating) return;

    // if scrolling is allowed and the panel is open, we don't want to close
    // the panel if they swipe up on the scrollable
    if (_isPanelOpen && _isScrollingEnabled) {
      assert(_hold == null || _drag == null);
      _drag?.end(details);
      assert(_drag == null);

      return;
    }

    final scrollPixelPerSeconds = details.velocity.pixelsPerSecond.dy;
    final flingVelocity =
        -scrollPixelPerSeconds / (widget.maxHeight - widget.minHeight);

    final nearestSnapPoint =
        _findNearestRelativeSnapPoint(target: _animationController.value);

    if (scrollPixelPerSeconds > widget.completeFlingVelocity) {
      if (flingVelocity.isNegative) {
        _flingPanelToPosition(0.0, flingVelocity);
      } else {
        _flingPanelToPosition(1.0, flingVelocity);
      }
    } else {
      if (scrollPixelPerSeconds > widget.minFlingVelocity) {
        _flingPanelToPosition(nearestSnapPoint, flingVelocity);
      } else {
        final pixels = _sizeTween.transform(nearestSnapPoint);

        animateTo(pixels: pixels, duration: widget.animationDuration);
      }
    }
  }

  void _flingPanelToPosition(double targetPos, double velocity) {
    final simulation = SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 600,
        ratio: 1.2,
      ),
      _animationController.value,
      targetPos,
      velocity,
    );

    _animationController.animateWith(simulation);
  }

  double _findNearestRelativeSnapPoint({required double target}) {
    final snapValues = widget.snapPositions.map(_pixelToValue).toList();
    return _findClosestPosition(
      positions: [0, ...snapValues, 1],
      target: target,
    );
  }

  // region panel options

  Future<void> close() async {
    setState(() => _isScrollingEnabled = false);

    await _scrollController.animateTo(
      0.0,
      duration: widget.animationDuration,
      curve: Curves.linear,
    );

    return _animationController.fling(velocity: -1.0);
  }

  Future<void> open() {
    return _animationController.fling(velocity: 1.0);
  }

  Future<void> animateToNearestSnapPoint() {
    final newPosition =
        _findNearestRelativeSnapPoint(target: _animationController.value);
    return animateTo(
      pixels: _sizeTween.transform(newPosition),
      duration: widget.animationDuration,
    );
  }

  Future<void> animateTo({
    required double pixels,
    Duration? duration,
  }) async {
    await _animationController.animateTo(
      _pixelToValue(pixels),
      curve: Curves.easeOutCirc,
      duration: duration,
    );

    await Future<void>.delayed(Duration.zero);

    // Reset the initial state, since we had some issues in the full state of the booking summary
    setState(() {
      _isScrollingEnabled = false;
      _isScrollingBlocked = false;
    });
  }

  void disableScroll() {
    _isScrollingBlocked = true;
  }

  void enableScroll() {
    _isScrollingBlocked = false;
  }

  // endregion

  void _notifyScrollListeners() {
    if (widget.onSizeChanged == null) return;

    final size = _sizeTween.transform(_animationController.value);
    widget.onSizeChanged!.call(_animationController.value, size);
  }

  void _handleDragCancel() {
    // _hold might be null if the drag started.
    // _drag might be null if the drag activity ended and called _disposeDrag.
    assert(_hold == null || _drag == null);
    _hold?.cancel();
    _drag?.cancel();
    assert(_hold == null);
    assert(_drag == null);
  }

  void _disposeHold() {
    _hold = null;
  }

  void _disposeDrag() {
    _drag = null;
  }
}

double _findClosestPosition({
  required List<double> positions,
  required double target,
}) {
  if (positions.isEmpty) {
    throw ArgumentError("The list of positions cannot be empty");
  }

  var closestPosition = positions[0];
  var minDifference = (positions[0] - target).abs();

  for (int i = 1; i < positions.length; i++) {
    final difference = (positions[i] - target).abs();
    if (difference < minDifference) {
      closestPosition = positions[i];
      minDifference = difference;
    }
  }

  return closestPosition;
}

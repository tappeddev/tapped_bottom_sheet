import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class GestureListener extends StatefulWidget {
  final void Function(DragUpdateDetails) onVerticalDragUpdate;
  final void Function(DragEndDetails) onVerticalDragEnd;
  final void Function() onVerticalDragCancel;

  final bool canDrag;

  final Widget child;

  const GestureListener({
    super.key,
    required this.canDrag,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onVerticalDragCancel,
    required this.child,
  });

  @override
  State<GestureListener> createState() => _GestureListenerState();
}

class _GestureListenerState extends State<GestureListener> {
  final _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (!widget.canDrag) return;

        _velocityTracker.addPosition(event.timeStamp, event.position);
      },
      onPointerMove: (event) {
        if (!widget.canDrag) return;

        _velocityTracker.addPosition(event.timeStamp, event.position);

        final delta = event.delta;
        final primaryDelta = delta.dy;

        /// ⚠️ If not assign the dx to 0, an assertion
        /// in the constructor of [DragUpdateDetails] is thrown.
        final offset = Offset(0, primaryDelta);

        final details = DragUpdateDetails(
          globalPosition: event.position,
          delta: offset,
          localPosition: event.localPosition,
          sourceTimeStamp: event.timeStamp,
          primaryDelta: primaryDelta,
        );

        widget.onVerticalDragUpdate(details);
      },
      onPointerUp: (event) {
        if (!widget.canDrag) return;

        final velocity = _velocityTracker.getVelocity();

        final pixelsPerSecondY = velocity.pixelsPerSecond.dy;

        /// ⚠️ If not assign the dx to 0, an assertion
        /// in the constructor of [DragEndDetails] is thrown.
        final offset = Offset(0, pixelsPerSecondY);
        final details = DragEndDetails(
          velocity: Velocity(pixelsPerSecond: offset),
          primaryVelocity: pixelsPerSecondY,
        );

        widget.onVerticalDragEnd(details);
      },
      onPointerCancel: (event) {
        if (!widget.canDrag) return;

        widget.onVerticalDragCancel();
      },
      child: widget.child,
    );
  }
}

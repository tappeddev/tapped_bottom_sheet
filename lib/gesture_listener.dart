import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class GestureListener extends StatefulWidget {
  final void Function(DragUpdateDetails) onVerticalDragUpdate;
  final void Function(DragEndDetails) onVerticalDragEnd;
  final void Function() onVerticalDragCancel;

  final Widget child;

  const GestureListener({
    super.key,
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
        _velocityTracker.addPosition(event.timeStamp, event.position);
      },
      onPointerMove: (event) {
        _velocityTracker.addPosition(event.timeStamp, event.position);

        final delta = event.delta;
        final primaryDelta = delta.dy;

        /// ⚠️ If not assign the dx to 0, an assertion is not working.
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
        final velocity = _velocityTracker.getVelocity();

        final pixelsPerSecondY = velocity.pixelsPerSecond.dy;

        /// ⚠️ If not assign the dx to 0, an assertion is not working.
        final offset = Offset(0, pixelsPerSecondY);
        final details = DragEndDetails(
          velocity: Velocity(pixelsPerSecond: offset),
          primaryVelocity: pixelsPerSecondY,
        );

        widget.onVerticalDragEnd(details);
      },
      onPointerCancel: (event) => widget.onVerticalDragCancel(),
      child: widget.child,
    );
  }
}

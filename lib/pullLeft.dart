import 'package:flutter/material.dart';

class PullLeftWrapper extends StatefulWidget {
  final Widget leftContent;
  final Widget mainContent;

  late final Duration toggleDuration;
  late final double maxSlide;
  late final double minDragStartEdge;
  late final double maxDragStartEdge;

  late final bool keepOpenAtStart;

  PullLeftWrapper(
      {required this.leftContent,
      required this.mainContent,
      this.maxSlide = 90,
      this.minDragStartEdge = 300,
      this.maxDragStartEdge = 30,
      this.keepOpenAtStart = false,
      durationMilliSeconds = 250}) {
    this.toggleDuration = Duration(milliseconds: durationMilliSeconds);
  }

  static PullLeftWrapperState? of(BuildContext context) =>
      context.findAncestorStateOfType<PullLeftWrapperState>();

  @override
  PullLeftWrapperState createState() => PullLeftWrapperState();
}

class PullLeftWrapperState extends State<PullLeftWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _canBeDragged = false;
  bool inactive = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: widget.toggleDuration);
    if (widget.keepOpenAtStart) {
      keepopen();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void open() => inactive ? null : _animationController.forward();
  void close() => inactive ? null : _animationController.reverse();
  void toggle() =>
      inactive ? null : (_animationController.isCompleted ? close() : open());
  void keepopen() {
    if (!_animationController.isCompleted) open();
    inactive = true;
  }

  void makeactive() => inactive = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_animationController.isCompleted) {
          close();
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: AnimatedBuilder(
            animation: _animationController,
            child: widget.mainContent,
            builder: (context, child) {
              double animValue = _animationController.value;
              final slideAmount = widget.maxSlide * animValue;
              // final contentScale = 1.0;
              return Stack(
                children: <Widget>[
                  widget.leftContent,
                  Transform(
                    transform: Matrix4.identity()..translate(slideAmount),
                    // ..scale(contentScale, contentScale),
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _animationController.isCompleted ? close : null,
                      child: child,
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    if (inactive) return;
    bool isDragOpenFromLeft = _animationController.isDismissed &&
        details.globalPosition.dx < widget.minDragStartEdge;
    bool isDragCloseFromRight = _animationController.isCompleted &&
        details.globalPosition.dx > widget.maxDragStartEdge;

    _canBeDragged = isDragOpenFromLeft || isDragCloseFromRight;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (inactive) return;
    if (_canBeDragged) {
      double delta = details.primaryDelta! / widget.maxSlide;
      _animationController.value += delta;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (inactive) return;
    // Martin (fidev) has no idea what it means, he copied from Drawer and I copied from him :)
    double _kMinFlingVelocity = 365.0;

    if (_animationController.isDismissed || _animationController.isCompleted) {
      return;
    }
    if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity) {
      double visualVelocity = details.velocity.pixelsPerSecond.dx /
          MediaQuery.of(context).size.width;

      _animationController.fling(velocity: visualVelocity);
    } else if (_animationController.value < 0.5) {
      close();
    } else {
      open();
    }
  }
}

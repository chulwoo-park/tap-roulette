import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

double _kCircleSize = 50.0;

Color get _randomColor =>
    Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0);

void main() => runApp(Roulette());

class Roulette extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RouletteState();
}

class RouletteState extends State<Roulette> {
  List<Widget> _items;
  Timer _timer;
  Widget _picked;

  bool get hasPickedItem => _picked != null;

  @override
  initState() {
    super.initState();
    _items = [];
    _picked = null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: hasPickedItem ? _buildResult() : _buildGame()),
    );
  }

  Widget _buildGame() {
    return Container(
      color: Colors.black,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: _gestureRecognizer(),
        child: (_items.length > 0)
            ? Stack(children: _items)
            : Center(
                child: Text(
                  "Tap!!!",
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }

  _gestureRecognizer() {
    return {
      ImmediateMultiDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              ImmediateMultiDragGestureRecognizer>(
          () => ImmediateMultiDragGestureRecognizer(),
          (ImmediateMultiDragGestureRecognizer instance) =>
              instance..onStart = _onDragStart)
    };
  }

  Widget _buildResult() {
    return GestureDetector(
      onTap: () => setState(() => _picked = null),
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [_picked],
        ),
      ),
    );
  }

  Drag _onDragStart(Offset position) {
    _items.add(
      _DragItem(
        key: GlobalKey<_DragItemState>(),
        position: position,
        color: _randomColor,
      ),
    );
    setState(() {});
    _restartGame();
    return _DragHandler(_items.last, _dragUpdate, _dragEnd);
  }

  void _dragUpdate(Widget item, Offset position) {
    (item.key as GlobalKey<_DragItemState>).currentState?._update(position);
  }

  void _dragEnd(Widget item) {
    _items.remove(item);
    setState(() {});
    _restartGame();
  }

  void _restartGame() {
    _timer?.cancel();
    if (_items.length > 1)
      _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
        timer.cancel();
        _finishGame();
      });
  }

  void _finishGame() {
    _picked = _items[Random().nextInt(_items.length)];
    _items.clear();
    setState(() {});
  }
}

class _DragItem extends StatefulWidget {
  final Color color;
  final Offset position;

  _DragItem({Key key, @required this.position, @required this.color})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DragItemState();
}

class _DragItemState extends State<_DragItem>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Offset _position;

  void _update(Offset position) => setState(() => this._position = position);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _position = widget.position;
    WidgetsBinding.instance.addPostFrameCallback(
        (callback) => _controller.repeat(period: Duration(seconds: 1)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _position.dy - _kCircleSize,
      left: _position.dx - _kCircleSize,
      child: Center(
        child: _buildPointer(),
      ),
    );
  }

  Widget _buildPointer() {
    return Stack(children: [
      _buildOuterCircle(),
      _buildInnerCircle(),
    ]);
  }

  Widget _buildOuterCircle() {
    return Container(
      child: CircularProgressIndicator(
        strokeWidth: 8.0,
        valueColor: AlwaysStoppedAnimation(widget.color),
      ),
      width: _kCircleSize * 2,
      height: _kCircleSize * 2,
    );
  }

  Widget _buildInnerCircle() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          ScaleTransition(scale: _controller, child: child),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: widget.color, width: _kCircleSize),
            shape: BoxShape.circle),
      ),
    );
  }
}

typedef OnDragUpdate = Function(Widget item, Offset pos);
typedef OnDragEnd = Function(Widget item);

class _DragHandler extends Drag {
  _DragHandler(this.item, this.onDragUpdate, this.onDragEnd);

  final OnDragUpdate onDragUpdate;
  final OnDragEnd onDragEnd;
  final Widget item;

  @override
  void update(DragUpdateDetails details) =>
      onDragUpdate(item, details.globalPosition);

  @override
  void end(DragEndDetails details) => onDragEnd(item);
}

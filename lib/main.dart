import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

double kSize = 50.0;

main() => runApp(Roulette());

class Roulette extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RouletteState();
}

class RouletteState extends State<Roulette> {
  List<Widget> items;
  Timer timer;
  Widget picked;

  @override
  initState() {
    super.initState();
    items = [];
    picked = null;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(home: Scaffold(body: picked == null ? game() : result()));

  game() {
    return Container(
        color: Colors.black,
        child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: recognizer(),
            child: (items.length > 0)
                ? Stack(children: items)
                : Center(child: Text("Tap!!!", style: TextStyle(color: Colors.white)))));
  }

  recognizer() => {
    ImmediateMultiDragGestureRecognizer:
    GestureRecognizerFactoryWithHandlers<
        ImmediateMultiDragGestureRecognizer>(
            () => ImmediateMultiDragGestureRecognizer(),
            (ImmediateMultiDragGestureRecognizer instance) => instance..onStart = onDragStart)
  };

  result() => GestureDetector(
      onTap: () => setState(() => picked = null),
      child: Container(color: Colors.black, child: Stack(children: [picked])));

  Drag onDragStart(Offset position) {
    items.add(Item(
        key: GlobalKey<ItemState>(),
        pos: position,
        color: color()));
    setState(() {});
    run();
    return Handler(items.last, dragUpdate, dragEnd);
  }

  color() => Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0);

  dragUpdate(Widget item, Offset position) {
    (item.key as GlobalKey<ItemState>).currentState?.update(position);
  }

  dragEnd(Widget item) {
    items.remove(item);
    setState(() {});
    run();
  }

  run() {
    timer?.cancel();
    if (items.length > 1) timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      timer.cancel();
      finish();
    });
  }

  finish() {
    picked = items[Random().nextInt(items.length)];
    items.clear();
    setState(() {});
  }
}

class Item extends StatefulWidget {
  final Color color;
  final Offset pos;

  Item({Key key, @required this.pos, @required this.color}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ItemState();
}

class ItemState extends State<Item> with SingleTickerProviderStateMixin {
  AnimationController ctrl;
  Offset pos;

  @override
  initState() {
    super.initState();
    ctrl = AnimationController(vsync: this);
    pos = widget.pos;
    WidgetsBinding.instance.addPostFrameCallback((callback) => ctrl.repeat(period: Duration(seconds: 1)));
  }

  @override
  dispose() {
    ctrl.dispose();
    super.dispose();
  }

  update(Offset position) => setState(() => this.pos = position);

  @override
  Widget build(BuildContext context) => Positioned(
      top: pos.dy - kSize, left: pos.dx - kSize,
      child: Center(child: child()));

  child() => Stack(children: [
    Container(
        child: CircularProgressIndicator(
            strokeWidth: 8.0, valueColor: AlwaysStoppedAnimation(widget.color)),
        width: kSize * 2, height: kSize * 2),
    AnimatedBuilder(
        animation: ctrl, builder: (context, child) => ScaleTransition(scale: ctrl, child: child),
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: widget.color, width: kSize),
                shape: BoxShape.circle)))
  ]);
}

class Handler extends Drag {
  Handler(this.item, this.onUpdate, this.onEnd);

  final Function(Widget item, Offset pos) onUpdate;
  final Function(Widget item) onEnd;
  final Widget item;

  @override
  update(DragUpdateDetails details) => onUpdate(item, details.globalPosition);

  @override
  end(DragEndDetails details) => onEnd(item);
}

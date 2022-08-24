import 'dart:isolate';

import "package:flutter/material.dart";
import "dart:async";

class Popup extends StatefulWidget {
  const Popup(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  State<Popup> createState() => _PopupState();
}

class _PopupState extends State<Popup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: -256, end: 16).animate(_controller)
      ..addListener(() => setState(() {}));
    _controller.animateTo(16,
        curve: Curves.easeOutSine, duration: const Duration(seconds: 2));
    Timer(
        const Duration(seconds: 6),
        () => _controller.animateTo(-256,
            curve: Curves.easeInSine, duration: const Duration(seconds: 2)));
    Timer(const Duration(seconds: 10), () {
      popups.removeAt(0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: _animation.value,
      bottom: 16.0 + 48 * popups.indexOf(widget),
      child: TextButton(
        onPressed: () {
          _controller.animateTo(-256,
              curve: Curves.easeInSine, duration: const Duration(seconds: 2));
          Timer(const Duration(seconds: 2), () {
            popups.removeAt(0);
          });
        },
        child: Card(
          elevation: 4,
          color: Theme.of(context).highlightColor,
          child: SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(widget.text),
            ),
          ),
        ),
      ),
    );
  }
}

String token = "";
List<Popup> popups = [];

String apiUrl = "http://127.0.0.1:8000";
SendPort? networkSendPort;

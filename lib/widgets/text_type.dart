import 'dart:async';
import 'package:flutter/material.dart';

class TextType extends StatefulWidget {
  final String text;
  final Duration typingSpeed;
  final TextStyle? style;
  final bool showCursor;

  const TextType({
    super.key,
    required this.text,
    this.typingSpeed = const Duration(milliseconds: 60),
    this.style,
    this.showCursor = true,
  });

  @override
  State<TextType> createState() => _TextTypeState();
}

class _TextTypeState extends State<TextType> {
  String _displayedText = '';
  Timer? _timer;
  int _currentIndex = 0;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) return;

      if (_currentIndex < widget.text.length) {
        setState(() {
          _currentIndex++;
          _displayedText =
              widget.text.substring(0, _currentIndex);
        });
      } else {
        timer.cancel();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showCursor = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: widget.style,
        children: [
          TextSpan(text: _displayedText),
          if (widget.showCursor && _showCursor)
            const TextSpan(text: '|'),
        ],
      ),
    );
  }
}
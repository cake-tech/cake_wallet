import 'package:flutter/material.dart';

class AnimatedTypingText extends StatefulWidget {
  final List<String> words;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration pauseDuration;
  final Color cursorColor;
  final double cursorWidth;
  final double cursorHeight;
  final Duration cursorBlinkDuration;

  const AnimatedTypingText({
    Key? key,
    required this.words,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 100),
    this.pauseDuration = const Duration(milliseconds: 3000),
    this.cursorColor = Colors.black,
    this.cursorWidth = 2.0,
    this.cursorHeight = 20.0,
    this.cursorBlinkDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<AnimatedTypingText> createState() => _AnimatedTypingTextState();
}

class _AnimatedTypingTextState extends State<AnimatedTypingText> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;

  String _displayText = '';

  double _maxTextWidth = 0;
  int _currentWordIndex = 0;
  int _currentCharIndex = 0;
  
  bool _isTyping = true;
  bool _isPaused = false;
  bool _isWaitingForPause = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.typingSpeed,
    );

    _cursorController = AnimationController(
      vsync: this,
      duration: widget.cursorBlinkDuration,
    )..repeat(reverse: true);

    _cursorAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cursorController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateMaxTextWidth());

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _updateText();
        if (!_isWaitingForPause) {
          _controller.reset();
          _controller.forward();
        }
      }
    });

    _controller.forward();
  }

  void _calculateMaxTextWidth() {
    final textStyle = widget.style ?? DefaultTextStyle.of(context).style;
    double maxWidth = 0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final word in widget.words) {
      textPainter.text = TextSpan(text: word, style: textStyle);
      textPainter.layout();
      if (textPainter.width > maxWidth) {
        maxWidth = textPainter.width;
      }
    }
    setState(() {
      _maxTextWidth = maxWidth;
    });
  }

  void _updateText() {
    if (_isWaitingForPause) return;

    if (_isPaused) {
      if (_isTyping) {
        _isTyping = false;
        _isWaitingForPause = true;
        Future.delayed(widget.pauseDuration, () {
          if (mounted) {
            setState(() {
              _isPaused = false;
              _isWaitingForPause = false;
              _controller.reset();
              _controller.forward();
            });
          }
        });
      } else {
        _deletePrevChar();
      }
    } else {
      if (_isTyping) {
        _typeNextChar();
      } else {
        _deletePrevChar();
      }
    }

    setState(() {
      _displayText = widget.words[_currentWordIndex].substring(0, _currentCharIndex);
    });
  }

  void _typeNextChar() {
    if (_currentCharIndex < widget.words[_currentWordIndex].length) {
      _currentCharIndex++;
    } else {
      _isPaused = true;
    }
  }

  void _deletePrevChar() {
    if (_currentCharIndex > 0) {
      _currentCharIndex--;
    } else {
      _currentWordIndex = (_currentWordIndex + 1) % widget.words.length;
      _currentCharIndex = 0;
      _isTyping = true;
      _isPaused = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = _maxTextWidth + widget.cursorWidth + 8;
    return SizedBox(
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fixed cursor position
          Positioned(
            right: 0,
            child: AnimatedBuilder(
              animation: _cursorAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _cursorAnimation.value,
                  child: Container(
                    width: widget.cursorWidth,
                    height: widget.cursorHeight,
                    color: widget.cursorColor,
                  ),
                );
              },
            ),
          ),
          // Animated text
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _displayText + ' ',
              style: widget.style,
            ),
          ),
        ],
      ),
    );
  }
} 
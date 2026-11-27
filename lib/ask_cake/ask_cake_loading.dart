import 'dart:math';

import 'package:flutter/material.dart';

/// The Ask Cake waiting animation: capability tiles circling a softly glowing
/// centre on a tilted ring, each popping in with a spring. A ring around the
/// centre fills while the language pack downloads, and a burst of confetti
/// marks the moment everything is ready.
class AskCakeOrbit extends StatefulWidget {
  const AskCakeOrbit({super.key, this.progress, this.celebrate = false, this.size = 260});

  /// Download progress from 0 to 1; null shows no ring.
  final double? progress;

  /// Flipping this to true fires the confetti once.
  final bool celebrate;

  final double size;

  @override
  State<AskCakeOrbit> createState() => _AskCakeOrbitState();
}

class _AskCakeOrbitState extends State<AskCakeOrbit> with TickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);
  late final _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  final _pieces = <_Piece>[];

  static const _tiles = [
    (Icons.account_balance_wallet_rounded, Color(0xFFF7931A)),
    (Icons.swap_horiz_rounded, Color(0xFF7C8CF8)),
    (Icons.north_east_rounded, Color(0xFF34C77B)),
    (Icons.south_west_rounded, Color(0xFF29B6F6)),
    (Icons.person_add_alt_1_rounded, Color(0xFFEC5FA4)),
    (Icons.bar_chart_rounded, Color(0xFFFFC53D)),
    (Icons.tune_rounded, Color(0xFF9B6CF6)),
    (Icons.shield_rounded, Color(0xFFFF6B5E)),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.celebrate) _burst();
  }

  @override
  void didUpdateWidget(AskCakeOrbit old) {
    super.didUpdateWidget(old);
    if (widget.celebrate && !old.celebrate) _burst();
  }

  void _burst() {
    final random = Random();
    const colours = [
      Color(0xFF7C8CF8), Color(0xFFF7931A), Color(0xFF34C77B), Color(0xFFEC5FA4), //
      Color(0xFFFFC53D), Color(0xFF29B6F6), Color(0xFFFF6B5E),
    ];
    _pieces
      ..clear()
      ..addAll([
        for (var i = 0; i < 70; i++)
          _Piece(
            angle: -pi / 2 + (random.nextDouble() - 0.5) * pi * 1.5,
            speed: 0.55 + random.nextDouble() * 0.9,
            spin: (random.nextDouble() - 0.5) * 14,
            length: 5 + random.nextDouble() * 7,
            colour: colours[random.nextInt(colours.length)],
          ),
      ]);
    _confetti.forward(from: 0);
  }

  @override
  void dispose() {
    _spin.dispose();
    _intro.dispose();
    _pulse.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = widget.size;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: widget.progress == null
          ? 'Getting Ask Cake ready'
          : 'Downloading, ${(widget.progress! * 100).round()} percent',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_spin, _intro, _pulse, _confetti]),
            builder: (context, _) {
              final turn = reduceMotion ? 0.08 : _spin.value;
              final tiles = <(double depth, Widget widget)>[];
              for (var i = 0; i < _tiles.length; i++) {
                final angle = 2 * pi * (turn + i / _tiles.length);
                final depth = sin(angle); // +1 is nearest the viewer
                final appear = Curves.elasticOut
                    .transform(((_intro.value - i * 0.07) / 0.55).clamp(0.0, 1.0))
                    .clamp(0.0, 1.3);
                final scale = (0.62 + 0.26 * (depth + 1)) * appear;
                final tile = size * 0.17;
                tiles.add((
                  depth,
                  Positioned(
                    left: size / 2 + cos(angle) * size * 0.40 - tile / 2,
                    top: size / 2 + depth * size * 0.13 - tile / 2,
                    child: Opacity(
                      opacity: (0.55 + 0.45 * (depth + 1) / 2) * appear.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: tile,
                          height: tile,
                          decoration: BoxDecoration(
                            color: _tiles[i].$2,
                            borderRadius: BorderRadius.circular(tile * 0.3),
                            boxShadow: [
                              BoxShadow(color: _tiles[i].$2.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: 1),
                            ],
                          ),
                          child: Icon(_tiles[i].$1, color: Colors.white, size: tile * 0.58),
                        ),
                      ),
                    ),
                  ),
                ));
              }
              final behind = [for (final t in tiles) if (t.$1 < 0) t]..sort((a, b) => a.$1.compareTo(b.$1));
              final inFront = [for (final t in tiles) if (t.$1 >= 0) t]..sort((a, b) => a.$1.compareTo(b.$1));
              final centre = size * 0.30;
              final glow = 0.5 + 0.5 * _pulse.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final t in behind) t.$2,
                  Positioned(
                    left: size / 2 - centre / 2,
                    top: size / 2 - centre / 2,
                    child: Container(
                      width: centre,
                      height: centre,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color.lerp(colors.primary, Colors.white, 0.35)!, colors.primary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.30 + 0.25 * glow),
                            blurRadius: 28 + 22 * glow,
                            spreadRadius: 4 + 8 * glow,
                          ),
                        ],
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: colors.onPrimary, size: centre * 0.5),
                    ),
                  ),
                  if (widget.progress != null)
                    Positioned(
                      left: size / 2 - centre * 0.66,
                      top: size / 2 - centre * 0.66,
                      child: SizedBox(
                        width: centre * 1.32,
                        height: centre * 1.32,
                        child: CircularProgressIndicator(
                          value: widget.progress!.clamp(0.0, 1.0),
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          backgroundColor: colors.primary.withValues(alpha: 0.18),
                          color: colors.primary,
                        ),
                      ),
                    ),
                  for (final t in inFront) t.$2,
                  if (_confetti.isAnimating || _confetti.value > 0 && _confetti.value < 1)
                    Positioned.fill(
                      child: CustomPaint(painter: _ConfettiPainter(_pieces, _confetti.value)),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece(
      {required this.angle, required this.speed, required this.spin, required this.length, required this.colour});

  final double angle;
  final double speed;
  final double spin;
  final double length;
  final Color colour;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = size.center(Offset.zero);
    final reach = size.shortestSide * 0.95;
    for (final piece in pieces) {
      // Thrown outward, slowed by drag, then pulled down.
      final travelled = reach * piece.speed * (1 - pow(1 - t, 3));
      final position = origin +
          Offset(cos(piece.angle), sin(piece.angle)) * travelled.toDouble() +
          Offset(0, reach * 0.9 * t * t);
      final paint = Paint()
        ..color = piece.colour.withValues(alpha: (1 - t * t).clamp(0.0, 1.0))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final tilt = piece.angle + piece.spin * t;
      final half = Offset(cos(tilt), sin(tilt)) * (piece.length / 2);
      canvas.drawLine(position - half, position + half, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Short lines that rotate under the animation while Ask Cake gets ready.
class AskCakeLoadingCaption extends StatefulWidget {
  const AskCakeLoadingCaption({super.key, required this.lines});

  final List<String> lines;

  @override
  State<AskCakeLoadingCaption> createState() => _AskCakeLoadingCaptionState();
}

class _AskCakeLoadingCaptionState extends State<AskCakeLoadingCaption> {
  var _index = 0;
  var _alive = true;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (_alive) {
      await Future<void>.delayed(const Duration(milliseconds: 1900));
      if (!_alive || !mounted) return;
      setState(() => _index = (_index + 1) % widget.lines.length);
    }
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        widget.lines[_index % widget.lines.length],
        key: ValueKey(_index),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurface),
      ),
    );
  }
}

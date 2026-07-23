import "package:flutter/cupertino.dart";

class ConfettiBurst extends StatelessWidget {
  const ConfettiBurst();

  @override
  Widget build(BuildContext context) => const Stack(
    alignment: Alignment.center,
    children: [
      Positioned(
        left: 60,
        top: 8,
        child: _ConfettiPiece(
          color: Color.fromRGBO(251, 80, 3, 0.6),
          angle: -0.45,
        ),
      ),
      Positioned(
        right: 48,
        top: 6,
        child: _ConfettiPiece(
          color: Color.fromRGBO(0, 153, 255, 0.6),
          angle: 0.35,
        ),
      ),
      Positioned(
        left: 18,
        top: 62,
        child: _ConfettiPiece(
          color: Color.fromRGBO(255, 221, 0, 0.6),
          angle: 0.3,
        ),
      ),
      Positioned(
        right: 112,
        top: 76,
        child: _ConfettiPiece(
          color: Color.fromRGBO(255, 221, 0, 0.6),
          angle: -0.4,
        ),
      ),
      Positioned(
        left: 92,
        bottom: 18,
        child: _ConfettiPiece(
          color: Color.fromRGBO(0, 153, 255, 0.6),
          angle: 0.2,
        ),
      ),
      Positioned(
        right: 42,
        bottom: 12,
        child: _ConfettiPiece(
          color: Color.fromRGBO(251, 80, 3, 0.6),
          angle: -0.35,
        ),
      ),
    ],
  );
}

class _ConfettiPiece extends StatelessWidget {
  const _ConfettiPiece({
    required this.color,
    required this.angle,
  });

  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 5,
      height: 18,
      decoration: BoxDecoration(color: color),
    ),
  );
}
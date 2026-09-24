import "package:flutter/material.dart";

class CiBuildOverlay extends StatelessWidget {
  const CiBuildOverlay({required this.child, super.key});

  static const _commit = String.fromEnvironment("CI_COMMIT");
  static const _branch = String.fromEnvironment("CI_BRANCH");
  static const _isCiBuild = _commit != "" || _branch != "";

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!_isCiBuild) {
      return child;
    }

    final shortCommit = _commit.length > 7 ? _commit.substring(0, 7) : _commit;
    final label = [shortCommit, _branch].where((part) => part.isNotEmpty).join(" · ");

    return Stack(
      fit: StackFit.passthrough,
      textDirection: TextDirection.ltr,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: SafeArea(
                bottom: false,
                child: ColoredBox(
                  color: Colors.black54,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    textScaler: TextScaler.noScaling,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
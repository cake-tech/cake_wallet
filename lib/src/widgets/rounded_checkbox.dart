import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoundedCheckbox extends StatelessWidget {
  RoundedCheckbox({Key? key, required this.value, this.excludeFromSemantics = false})
      : super(key: key);

  final bool value;

  /// Set to `true` when an ancestor already exposes the selection state (for
  /// example a row wrapped in `Semantics(selected: ...)`), so the same state is
  /// not announced twice.
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    // Unchecked renders nothing at all, so without an explicit `checked` state
    // the selection is invisible to screen readers.
    final Widget indicator = value
        ? Container(
            height: 20.0,
            width: 20.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(50.0)),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: ExcludeSemantics(
              child: Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.surface,
                size: 14.0,
              ),
            ))
        : const Offstage();

    if (excludeFromSemantics) {
      return ExcludeSemantics(child: indicator);
    }

    // Deliberately not a semantics container: the state merges into the
    // enclosing row/option node instead of adding a second focus stop.
    return Semantics(checked: value, child: indicator);
  }
}

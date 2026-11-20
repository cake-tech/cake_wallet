import "package:flutter/widgets.dart";

abstract final class TestId {
  static final RegExp _testKeyPattern = RegExp(r"^[a-z0-9_]+_key$");

  static Widget merge(String? id, {required Widget child, String? label}) => id == null
      ? child
      : MergeSemantics(child: Semantics(identifier: id, label: label, child: child));

  static Widget container(String? id, {required Widget child, bool explicitChildNodes = false}) =>
      id == null
          ? child
          : Semantics(
              container: true,
              explicitChildNodes: explicitChildNodes,
              identifier: id,
              child: child,
            );

  static String? fromKey(Key? key) =>
      key is ValueKey<String> && _testKeyPattern.hasMatch(key.value) ? key.value : null;
}

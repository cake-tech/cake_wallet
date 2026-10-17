import "package:analyzer/dart/ast/ast.dart";

bool isFlutterClass(ConstructorName constructorName, Set<String> classNames) {
  final element = constructorName.type.element;
  if (element == null || !classNames.contains(element.name)) {
    return false;
  }

  final libraryUri = element.library?.uri;
  return libraryUri != null &&
      libraryUri.scheme == "package" &&
      libraryUri.pathSegments.isNotEmpty &&
      libraryUri.pathSegments.first == "flutter";
}

StringLiteral? testKeyLiteral(Expression? expression) {
  if (expression is! InstanceCreationExpression ||
      !isFlutterClass(expression.constructorName, const {"Key", "ValueKey"})) {
    return null;
  }

  final arguments = expression.argumentList.arguments;
  if (arguments.isEmpty) {
    return null;
  }

  final literal = arguments.first;
  final String? tail = switch (literal) {
    SimpleStringLiteral() => literal.value,
    StringInterpolation() => literal.lastString.value,
    _ => null,
  };

  return tail != null && tail.endsWith("_key") ? literal as StringLiteral : null;
}

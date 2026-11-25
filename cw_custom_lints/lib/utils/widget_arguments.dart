import "package:analyzer/dart/ast/ast.dart";

bool isCakeWalletWidget(ConstructorName constructorName, String className) {
  final element = constructorName.type.element;
  if (element == null || element.name != className) {
    return false;
  }

  final libraryUri = element.library?.uri;
  if (libraryUri == null || libraryUri.scheme != "package") {
    return false;
  }

  final segments = libraryUri.pathSegments;
  return segments.isNotEmpty && segments.first == "cake_wallet";
}

NamedArgument? namedArgument(ArgumentList argumentList, String name) {
  for (final argument in argumentList.arguments) {
    if (argument is NamedArgument && argument.name.lexeme == name) {
      return argument;
    }
  }

  return null;
}

Expression? namedArgumentExpression(ArgumentList argumentList, String name) =>
    namedArgument(argumentList, name)?.argumentExpression;

// passed null or ""
// does NOT work if a runtime expression evaluates to an empty string or null
bool isMissingOrEmptyText(Expression? expression) {
  if (expression == null || expression is NullLiteral) {
    return true;
  }

  return expression is StringLiteral && (expression.stringValue?.isEmpty ?? false);
}

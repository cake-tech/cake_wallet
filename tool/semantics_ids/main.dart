import "dart:io";

import "package:analyzer/dart/analysis/utilities.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";

const _testIdImport = "package:cake_wallet/utils/test_id.dart";

const _interactiveWidgets = {
  "GestureDetector",
  "InkWell",
  "TextButton",
  "IconButton",
  "ElevatedButton",
  "OutlinedButton",
  "FilledButton",
  "TextField",
  "TextFormField",
  "Switch",
  "Checkbox",
  "Radio",
  "ListTile",
  "CupertinoButton",
};

void main(List<String> args) {
  final apply = args.contains("--apply");
  final paths = args.where((arg) => arg != "--apply").toList();
  var total = 0;

  for (final path in (paths.isEmpty ? ["lib"] : paths).expand(_dartFiles)) {
    final source = File(path).readAsStringSync();
    final unit = parseString(content: source, path: path, throwIfDiagnostics: false).unit;
    final finder = _Finder();
    unit.accept(finder);

    for (final (widget, id) in finder.hits) {
      stdout.writeln("$path:${unit.lineInfo.getLocation(widget.offset).lineNumber} $id");
    }

    total += finder.hits.length;
    if (apply && finder.hits.isNotEmpty) {
      File(path).writeAsStringSync(_wrap(source, unit, finder.hits));
    }
  }

  stdout.writeln("$total hit(s)");
}

Iterable<String> _dartFiles(String path) => FileSystemEntity.isDirectorySync(path)
    ? Directory(path)
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => path.endsWith(".dart") && !path.endsWith(".g.dart"))
    : [path];

String _wrap(String source, CompilationUnit unit, List<(AstNode, String)> hits) {
  final edits = [
    for (final (widget, id) in hits) ...[
      (widget.offset, "TestId.merge($id, child: "),
      (widget.end, ")"),
    ],
  ];

  final imports = unit.directives.whereType<ImportDirective>();
  if (!imports.any((directive) => directive.uri.stringValue == _testIdImport)) {
    final quote = imports.isEmpty ? '"' : imports.last.uri.toSource()[0];
    final line = "import $quote$_testIdImport$quote;";
    edits.add(imports.isEmpty ? (0, "$line\n") : (imports.last.end, "\n$line"));
  }

  edits.sort((a, b) => b.$1.compareTo(a.$1));
  return edits.fold(source, (text, edit) => text.replaceRange(edit.$1, edit.$1, edit.$2));
}

String? _name(AstNode node) => switch (node) {
  InstanceCreationExpression(:final constructorName) => constructorName.type.name.lexeme,
  MethodInvocation(target: null, :final methodName) => methodName.name,
  MethodInvocation(target: SimpleIdentifier(:final name)) => name,
  _ => null,
};

NodeList<Expression>? _arguments(AstNode node) => switch (node) {
  InstanceCreationExpression(:final argumentList) => argumentList.arguments,
  MethodInvocation(:final argumentList) => argumentList.arguments,
  _ => null,
};

Expression? _named(AstNode node, String name) => _arguments(node)
    ?.whereType<NamedExpression>()
    .where((argument) => argument.name.label.name == name)
    .firstOrNull
    ?.expression;

class _Finder extends GeneralizingAstVisitor<void> {
  final hits = <(AstNode, String)>[];

  @override
  void visitNode(AstNode node) {
    final id = _interactiveWidgets.contains(_name(node)) ? _testKey(_named(node, "key")) : null;
    if (id != null && !_hasIdentifierAncestor(node)) {
      hits.add((node, id));
    }

    super.visitNode(node);
  }

  String? _testKey(Expression? key) {
    final literal = key != null && const {"Key", "ValueKey"}.contains(_name(key))
        ? _arguments(key)?.firstOrNull
        : null;
    final tail = switch (literal) {
      SimpleStringLiteral(:final value) => value,
      StringInterpolation(:final lastString) => lastString.value,
      _ => null,
    };

    return tail != null && tail.endsWith("_key") ? literal!.toSource() : null;
  }

  bool _hasIdentifierAncestor(AstNode node) {
    for (var current = node.parent; current != null; current = current.parent) {
      if (current is MethodDeclaration ||
          current is FunctionDeclaration ||
          current is ClassDeclaration ||
          current is CompilationUnit) {
        return false;
      }

      if ((_name(current) == "Semantics" && _named(current, "identifier") != null) ||
          (current is MethodInvocation &&
              _name(current) == "TestId" &&
              const {"merge", "container"}.contains(current.methodName.name))) {
        return true;
      }
    }

    return false;
  }
}

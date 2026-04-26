import "package:custom_lint_builder/custom_lint_builder.dart";
import "package:cw_custom_lints/http_force_proxy/http_force_proxy_rule.dart";
import "package:cw_custom_lints/print_verbose/print_verbose_rule.dart";
import "package:cw_custom_lints/restricted_imports/restricted_imports_rule.dart";

PluginBase createPlugin() => _CustomLintsPlugin();

class _CustomLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const PrintVerboseRule(),
    const RestrictedImportsRule(),
    const HttpForceProxyRule(),
  ];
}

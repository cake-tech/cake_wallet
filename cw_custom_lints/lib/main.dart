import "package:analysis_server_plugin/plugin.dart";
import "package:analysis_server_plugin/registry.dart";
import "package:cw_custom_lints/http_force_proxy/http_force_proxy_rule.dart";
import "package:cw_custom_lints/no_bare_catch/no_bare_catch_rule.dart";
import "package:cw_custom_lints/print_verbose/print_verbose_fix.dart";
import "package:cw_custom_lints/print_verbose/print_verbose_rule.dart";
import "package:cw_custom_lints/restricted_imports/restricted_imports_rule.dart";
import "package:cw_custom_lints/use_cake_exception/use_cake_exception_rule.dart";

final plugin = CwCustomLintsPlugin();

class CwCustomLintsPlugin extends Plugin {
  @override
  String get name => "cw_custom_lints";

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(PrintVerboseRule());
    registry.registerWarningRule(RestrictedImportsRule());
    registry.registerWarningRule(HttpForceProxyRule());
    registry.registerWarningRule(UseCakeExceptionRule());
    // registry.registerWarningRule(NoBareCatchRule());

    registry.registerFixForRule(PrintVerboseRule.code, ReplaceWithPrintV.new);
  }
}

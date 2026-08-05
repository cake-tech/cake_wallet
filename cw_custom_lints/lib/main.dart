import "package:analysis_server_plugin/plugin.dart";
import "package:analysis_server_plugin/registry.dart";
import "package:cw_custom_lints/http_force_proxy/http_force_proxy_rule.dart";
import "package:cw_custom_lints/modal_top_bar_semantics/modal_top_bar_semantics_rule.dart";
import "package:cw_custom_lints/modern_button_semantics/modern_button_semantics_rule.dart";
import "package:cw_custom_lints/print_verbose/print_verbose_fix.dart";
import "package:cw_custom_lints/print_verbose/print_verbose_rule.dart";
import "package:cw_custom_lints/restricted_imports/restricted_imports_rule.dart";

final plugin = CwCustomLintsPlugin();

class CwCustomLintsPlugin extends Plugin {
  @override
  String get name => "cw_custom_lints";

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(PrintVerboseRule());
    registry.registerWarningRule(RestrictedImportsRule());
    registry.registerWarningRule(HttpForceProxyRule());
    registry.registerWarningRule(ModernButtonSemanticsRule());
    registry.registerWarningRule(ModalTopBarSemanticsRule());

    registry.registerFixForRule(PrintVerboseRule.code, ReplaceWithPrintV.new);
  }
}

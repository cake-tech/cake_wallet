//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <cw_monero/cw_monero_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) cw_monero_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "CwMoneroPlugin");
  cw_monero_plugin_register_with_registrar(cw_monero_registrar);
}

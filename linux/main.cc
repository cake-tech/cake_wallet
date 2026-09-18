#include "my_application.h"

#include <stdlib.h>

int main(int argc, char** argv) {
  // Flutter Linux can freeze for ~25s when a text field is focused (Sign /
  // Verify, wallet password) if GTK talks to AT-SPI on the UI thread.
  // Linux Mint sets GTK_MODULES=gail:atk-bridge, which loads that bridge.
  // https://github.com/flutter/flutter/issues/153560
  // https://github.com/cake-tech/cake_wallet/issues/2608
  setenv("NO_AT_BRIDGE", "1", 1);
  setenv("GTK_A11Y", "none", 1);
  setenv("GTK_MODULES", "", 1);
  setenv("GTK3_MODULES", "", 1);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}

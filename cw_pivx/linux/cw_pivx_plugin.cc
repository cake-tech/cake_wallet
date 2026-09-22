#include "include/cw_pivx/cw_pivx_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include "cw_pivx_sapling.h"

#define CW_PIVX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), cw_pivx_plugin_get_type(), CwPivxPlugin))

struct _CwPivxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(CwPivxPlugin, cw_pivx_plugin, g_object_get_type())

static void cw_pivx_plugin_handle_method_call(
    CwPivxPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    g_autofree gchar* version = g_strdup_printf("Linux");
    g_autoptr(FlValue) result = fl_value_new_string(version);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void cw_pivx_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(cw_pivx_plugin_parent_class)->dispose(object);
}

static void cw_pivx_plugin_class_init(CwPivxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = cw_pivx_plugin_dispose;
}

static void cw_pivx_plugin_init(CwPivxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data) {
  CwPivxPlugin* plugin = CW_PIVX_PLUGIN(user_data);
  cw_pivx_plugin_handle_method_call(plugin, method_call);
}

void cw_pivx_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  CwPivxPlugin* plugin = CW_PIVX_PLUGIN(
      g_object_new(cw_pivx_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "cw_pivx",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}

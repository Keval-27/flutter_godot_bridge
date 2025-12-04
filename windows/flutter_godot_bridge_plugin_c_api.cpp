#include "include/flutter_godot_bridge/flutter_godot_bridge_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_godot_bridge_plugin.h"

void FlutterGodotBridgePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_godot_bridge::FlutterGodotBridgePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

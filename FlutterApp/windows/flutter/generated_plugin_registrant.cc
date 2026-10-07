//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <file_selector_windows/file_selector_windows.h>
#include <public_file_saver/public_file_saver_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
  PublicFileSaverPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PublicFileSaverPluginCApi"));
}

package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import ch.aequitec.csv_parser.CsvParserPlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    CsvParserPlugin.registerWith(registry.registrarFor("ch.aequitec.csv_parser.CsvParserPlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}

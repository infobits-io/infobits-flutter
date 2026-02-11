/// Defines available regions for Infobits data collection
enum InfobitsRegion {
  /// European Union region (GDPR compliant)
  eu,
  // Future regions can be added here
  // us,
  // ap,
}

/// Configuration for regional endpoints
class RegionConfig {
  /// Get the analytics ingest URL for a specific region
  static String getAnalyticsIngestUrl(InfobitsRegion region) {
    switch (region) {
      case InfobitsRegion.eu:
        return 'https://eu.infobits.io/a/';
      // Future regions can be added here
      // case InfobitsRegion.us:
      //   return 'https://us.infobits.io/a/';
    }
  }

  /// Get the logging ingest URL for a specific region
  static String getLoggingIngestUrl(InfobitsRegion region) {
    switch (region) {
      case InfobitsRegion.eu:
        return 'https://eu.infobits.io/l/';
      // Future regions can be added here
      // case InfobitsRegion.us:
      //   return 'https://us.infobits.io/l/';
    }
  }

  /// Default region for data collection
  static const InfobitsRegion defaultRegion = InfobitsRegion.eu;

  /// Get the default analytics ingest URL
  static String get defaultAnalyticsIngestUrl =>
      getAnalyticsIngestUrl(defaultRegion);

  /// Get the default logging ingest URL
  static String get defaultLoggingIngestUrl =>
      getLoggingIngestUrl(defaultRegion);
}

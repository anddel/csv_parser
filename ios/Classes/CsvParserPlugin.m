#import "CsvParserPlugin.h"
#if __has_include(<csv_parser/csv_parser-Swift.h>)
#import <csv_parser/csv_parser-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "csv_parser-Swift.h"
#endif

@implementation CsvParserPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCsvParserPlugin registerWithRegistrar:registrar];
}
@end

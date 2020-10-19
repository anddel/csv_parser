#import <Flutter/Flutter.h>

@interface CsvParserPlugin : NSObject<FlutterPlugin>
@end

// --- Library API below ---

#define RESULT_ERR -1

#define RESULT_OK 1

const char *csv_to_json(const char *content);

const char *json_to_csv(const char *content);

void rust_cstr_free(char *s);

# CSV Parser

CSV Parser is safe and fault-tolerant native library for Flutter projects written in Rust. 

## Quick Start

Short example of usage:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:csv_parser/csv_parser.dart';

void main() {

}

void csvItemsToString() {
    List<AgendaItem> testData = [
      AgendaItem("title 1", "test description 1", "agenda type", "2/3", false),
      AgendaItem("title 2", "test description 2", "agenda type", "1/3", true),
      AgendaItem("title 3", "test description 3", "agenda type", "2/3", false),
      AgendaItem("title 4", "test description 4", "agenda type", "2/4", true),
      AgendaItem("title 5", "test description 5", "agenda type", "5/5", false)
    ];
    
    var csvData = CSVData.fromHeaderAndRows(AgendaItemCSVHandler.toCSVHeader(),
     testData.map((e) => e.toCSVRow()).toList());
    var rawCSV = csvData.toRawCSV();
}

void fileToCSVItems() {
    final file = File("path/to/data.csv");
    var content = file.readAsBytesSync();

    var csvData = CSVData(content);
    List<AgendaItem> result =
            csvData.rows.map((e) => AgendaItemCSVHandler.fromCSV(e)).toList();
}

class AgendaItem {
  String title;
  String description;
  String agendaItemType;
  String majority;
  bool notaryRequired;
}

extension AgendaItemCSVHandler on AgendaItem {
  static AgendaItem fromCSV(List<Object> csv) => AgendaItem()
    ..title = csv[0] as String
    ..description = csv[1] as String
    ..agendaItemType = csv[2] as String
    ..majority = csv[3] as String
    ..notaryRequired = (csv[4] as String).toLowerCase() == 'true';

  static List<String> toCSVHeader() => <String>[
        "TITLE",
        "DESCRIPTION",
        "AGENDAITEMTYPE",
        "MAJORITY",
        "NOTARYREQUIRED",
      ];

  List<Object> toCSV() => <Object>[
        title ?? '',
        description ?? '',
        agendaItemType ?? '',
        majority ?? '',
        notaryRequired ?? '',
      ];
}
```

## Development

### Requirements

- Make sure [Rust](https://rustup.rs) is installed;
- Make sure [Android NDK](https://developer.android.com/studio/projects/install-ndk) is installed;
  - You might also need LLVM from the SDK manager
- Ensure that the env variable `$ANDROID_NDK_HOME` points to the NDK base folder
  - It may look like `/Users/brickpop/Library/Android/sdk/ndk-bundle` on MacOS
  - And look like `/home/brickpop/dev/android/ndk-bundle` on Linux

### Rust Cross-Compilation requirements

> TODO: add all requirements here:

- Ubuntu 
    - `sudo apt-get install libclang-dev gcc-mingw-w64`
- MacOS
    - `brew install ...`
    
### Compile the library
- Run `make` to see the available actions
- Run `make init` to install the Rust targets
- Run `make all` to build the libraries and the `.h` file

Generated artifacts:

- Android libraries
  - `target/aarch64-linux-android/release/libcsv_parser.so`
  - `target/armv7-linux-androideabi/release/libcsv_parser.so`
  - `target/i686-linux-android/release/libcsv_parser.so`
- iOS library
  - `target/universal/release/libcsv_parser.a`
- Library for current platform
  - `target/release/libcsv_parser.so`
- Bindings header
  - `target/bindings.h`

Artifacts will be placed according to the following scheme:

1. Android

```
android
└── src/main
    └── jniLibs
        ├── arm64-v8a
        │   └── libcsv_parser.so
        ├── armeabi-v7a
        │   └── libcsv_parser.so
        └── x86
            └── libcsv_parser.so 
```

2. iOS

```
ios
├── libcsv_parser.a
└── Classes
    └── CsvParserPlugin.h
```

3. Library for current platform

```
lib
├── libcsv_parser.so
└── libcsv_parser.h
```
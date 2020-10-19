import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart' as ffi;

const LIB_RESULT_ERR = -1;
const LIB_RESULT_OK = 1;

/// C struct `LibResult`.
class LibResult extends Struct {
  @Int32()
  int code;
  Pointer<ffi.Utf8> data;
  Pointer<ffi.Utf8> err;

  static Pointer<LibResult> allocate() {
    return ffi.allocate<LibResult>();
  }

  static LibResult from(int ptr) {
    return Pointer<LibResult>.fromAddress(ptr).ref;
  }
}

class Result {
  String error;
  dynamic data;

  Result.fromError(String error) {
    this.error = error;
  }

  Result.fromLibResult(Pointer<ffi.Utf8> raw) {
    final rawResult = ffi.Utf8.fromUtf8(raw);

    // Free the string pointer, as we already have
    // an owned String to return
    _freeCString(raw);

    Map json = jsonDecode(rawResult);
    var err = json["error"] as String;
    if (err != null) {
      this.error = err;
      return;
    }

    this.data = json["data"];

    // switch (result.code) {
    //   case LIB_RESULT_OK:
    //     this.data = ffi.Utf8.fromUtf8(result.data);
    //     break;
    //   case LIB_RESULT_ERR:
    //     this.err = ffi.Utf8.fromUtf8(result.err);
    //     break;
    //   default:
    //     this.err = "UNKNOWN_CODE: " + result.code.toString();
    // }
  }
}

const LIB_CSV_PARSER_BINARY_PATH = 'LIB_CSV_PARSER_BINARY_PATH';

/// Sets path prefix to the root of this package of directory that assets
/// for current platform: 'assets/binary/lib_csv_parser.{so,dylib,dll}'.
/// This is useful **only for tests**, when you need to run dart code locally,
/// and therefore the library for you platform must be loaded.
String _localPathPrefix() {
  var envVar = Platform.environment[LIB_CSV_PARSER_BINARY_PATH];
  if (envVar != null) return envVar;

  var pathPrefix = "assets/binary/";

  var currentPath = Directory.current.path;
  if (currentPath.contains('/libs/csv_parser')) {
    return currentPath.replaceFirst(
        new RegExp(r'\/libs\/csv_parse.+'), '/libs/csv_parser/$pathPrefix');
  }

  if (currentPath.contains('flutter_app')) {
    return currentPath.replaceFirst(
        new RegExp(r'flutter_ap.+'), 'libs/csv_parser/$pathPrefix');
  }

  return pathPrefix;
}

/// Loads the library according to the current platform.
DynamicLibrary _nativeCsvParserLib() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open("libcsv_parser.so");
  }
  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }

  var pathPrefix = _localPathPrefix();
  if (Platform.isLinux) {
    return DynamicLibrary.open(pathPrefix + "libcsv_parser.so");
  }

  if (Platform.isMacOS) {
    return DynamicLibrary.open(pathPrefix + "libcsv_parser.dylib");
  }

  if (Platform.isWindows) {
    return DynamicLibrary.open(pathPrefix + "libcsv_parser.dll");
  }

  return DynamicLibrary.process();
}

/// Define types and signatures and locate the symbols we want to use

typedef _csvToJsonFunc = Pointer<ffi.Utf8> Function(Pointer<Uint8>);
typedef _csvToJsonFuncFFI = Pointer<ffi.Utf8> Function(Pointer<Uint8>);

final _csvToJsonFunc _csvToJson = _nativeCsvParserLib()
    .lookup<NativeFunction<_csvToJsonFuncFFI>>("csv_to_json")
    .asFunction();

typedef _jsonToCsvFunc = Pointer<ffi.Utf8> Function(Pointer<ffi.Utf8>);
typedef _jsonToCsvFuncFFI = Pointer<ffi.Utf8> Function(Pointer<ffi.Utf8>);

final _jsonToCsvFunc _jsonToCsv = _nativeCsvParserLib()
    .lookup<NativeFunction<_jsonToCsvFuncFFI>>("json_to_csv")
    .asFunction();

typedef _freeStringFunc = void Function(Pointer<ffi.Utf8>);
typedef _freeStringFuncFFI = Void Function(Pointer<ffi.Utf8>);

final _freeStringFunc _freeCString = _nativeCsvParserLib()
    .lookup<NativeFunction<_freeStringFuncFFI>>("rust_cstr_free")
    .asFunction();

/// HANDLERS

Result csvToJson(Uint8List content) {
  if (_nativeCsvParserLib() == null)
    return Result.fromError("ERROR: The libcsv_parser is not initialized");

  if (content == null) return Result.fromError("ERROR: empty csv content");

  final pointer = ffi.allocate<Uint8>(count: content.length);

  for (int i = 0; i < content.length; i++) {
    pointer[i] = content[i];
  }

  // The actual native call
  final resultPointer = _csvToJson(pointer);

  return Result.fromLibResult(resultPointer);
}

Result jsonToCsv(String content) {
  if (_nativeCsvParserLib() == null)
    return Result.fromError("ERROR: The libcsv_parser is not initialized");

  final pointer = ffi.Utf8.toUtf8(content);

  // The actual native call
  final resultPointer = _jsonToCsv(pointer);

  return Result.fromLibResult(resultPointer);
}

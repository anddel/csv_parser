import 'dart:convert';
import 'dart:typed_data';
import 'native.dart' as native;

abstract class CSVRow {
  List<String> toCSVHeader();

  List<String> toCSVRow();
}

/// This means that CSV row has an invalid format.
const ErrInvalidRow = "invalid_row";

/// This means that CSV row is longer than the header.
/// Actual value of this error will be in format:
///  "invalid_row_size: header(X), row(Y)"
const ErrInvalidRowSize = "invalid_row_size";

/// This is for the case when not possible to
/// serialize data to JSON, mostly impossible.
const ErrSerializationError = "serialization_error";

/// Error means that data contains unknown or unsupported encoding.
const ErrInvalidEncoding = "invalid_encoding";

/// A representation of parsed CSV file content.
class CSVData {
  /// An array of Header columns.
  List<String> header;

  /// An array that contains all rows of CSV file.
  /// Length of each row is equal to length of `header`
  List<List<String>> rows;

  /// Indicates CSV transcoding error, can be one of:
  /// [ErrInvalidRow], [ErrInvalidRowSize],
  /// [ErrSerializationError], [ErrInvalidEncoding
  String error;

  /// Constructs [CSVData] from raw CSV data,
  /// [rawContent] are the raw bytes of file content.
  /// This data will be transcode into JSON using native library.
  CSVData.fromRawCSV(Uint8List rawContent) {
    var result = native.csvToJson(rawContent);
    if (result.error != null) {
      this.error = result.error;
      return;
    }

    this.fromJson(result.data);
  }

  /// Constructs [CSVData].
  CSVData.fromHeaderAndRows(List<String> header, List<List<String>> rows) {
    this.header = header;
    this.rows = rows;
  }

  /// Coverts List of [CSVRow] objects into [CSVData] object.
  CSVData.fromRows(List<CSVRow> rows) {
    this.header = rows.first.toCSVHeader();
    this.rows = rows.map((e) => e.toCSVRow()).toList();
  }

  /// Decodes a JSON string into a [CSVData] object.
  /// First checks for [error], if yes, processing will be interrupted.
  void fromJson(Map<String, dynamic> jsonData) {
    var header = jsonData['header'] as List<dynamic>;
    var rows = jsonData['rows'] as List<dynamic>;

    this.header = header.map((e) => e as String).toList();

    this.rows = List();
    rows.forEach((e) {
      var row = (e as List<dynamic>).map((e) => e as String).toList();
      this.rows.add(row);
    });
  }

  /// Encodes [CSVData] into JSON string.
  String toJson() {
    Map<String, dynamic> data = {
      'header': header,
      'rows': rows,
    };

    return jsonEncode(data);
  }

  /// Encodes [CSVData] into CSV string using the native library.
  native.Result toRawCSV() {
    return native.jsonToCsv(this.toJson());
  }
}

use std::fmt;

/// A representation of parsed CSV file content.
#[derive(Default, Debug, Clone, Serialize, Deserialize)]
pub struct CSVData {
    /// An array of Header columns.
    pub(crate) header: Vec<String>,
    /// An array that contains all rows of CSV file.
    /// Length of each row is equal to length of `header`.
    pub(crate) rows: Vec<Vec<String>>,
}

#[derive(Default, Debug, Clone, Serialize, Deserialize)]
pub struct ErrorResult {
    error: String,
}

/// Represents kind of errors than can be caught
/// when transcoding CSV <-> JSON data.
#[derive(Debug, Eq, PartialEq, Clone, Serialize, Deserialize)]
pub enum Error {
    /// This means that data contains unknown or unsupported encoding.
    InvalidEncoding,
    /// This means that CSV row has an invalid format.
    InvalidRow,
    /// This means that CSV row is longer than the header.
    InvalidRowSize(usize, usize),
    /// This is for the case when not possible to
    /// serialize data to JSON, mostly impossible.
    JSONSerializationError(String),
    JSONDeserializationError(String),
    CSVWriteHeaderError(String),
    CSVWriteRowError(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Error::InvalidEncoding => write!(f, "invalid_encoding"),
            Error::InvalidRow => write!(f, "invalid_row"),
            Error::InvalidRowSize(header, row) => {
                write!(f, "invalid_row_size: header({}), row({})", header, row)
            }
            Error::JSONSerializationError(s) => write!(f, "json_serialization_error: {}", s),
            Error::JSONDeserializationError(s) => write!(f, "json_deserialization_error: {}", s),
            Error::CSVWriteHeaderError(s) => write!(f, "csv_write_header_error: {}", s),
            Error::CSVWriteRowError(s) => write!(f, "csv_write_row_error: {}", s),
        }
    }
}

/// Takes JSON string with `CSVData` and transcode it into CSV.
/// Is an methods for public C API.
///
/// ## Arguments
/// * `json_data` - a byte array of UTF-8 with JSON.
pub fn json_to_csv(json_data: Vec<u8>) -> Result<String, Error> {
    let res = match serde_json::from_slice::<CSVData>(json_data.as_slice()) {
        Ok(res) => res,
        Err(err) => return Err(Error::JSONDeserializationError(err.to_string()))
    };

    marshal_csv(res)
}

/// Takes raw CSV file content and transcode it into JSON string with `CSVData`.
/// Is an methods for public C API.
///
/// ## Arguments
/// * `csv_data` - a byte array of UTF-8 or LATIN1 symbols with CSV-encoded information.
pub fn csv_to_json(csv_data: Vec<u8>) -> Result<String, Error> {
    let serde_result = match parse_csv(sanitize_string(csv_data)) {
        Ok(data) => serde_json::to_string(&data),
        Err(e) => return Err(e),
    };

    match serde_result {
        Ok(v) => Ok(v),
        Err(err) => Err(Error::JSONSerializationError(err.to_string()))
    }
}

/// Takes raw byte content and re-encodes it to UTF-8 array.
///
/// ## Arguments
/// * `csv_data` - a byte array of UTF-8 or LATIN1 symbols.
pub(crate) fn sanitize_string(csv_data: Vec<u8>) -> String {
    match std::str::from_utf8(csv_data.as_slice()) {
        Ok(data) => data.to_string(),
        Err(_) => {
            let res = encoding_rs::mem::decode_latin1(csv_data.as_slice());
            res.to_string()
        }
    }
}

/// Encodes `CSVData` into CSV format.
pub fn marshal_csv(data: CSVData) -> Result<String, Error> {
    let mut wrt = csv::WriterBuilder::new()
        .has_headers(true)
        .from_writer(vec![]);

    match wrt.write_record(data.header.as_slice()) {
        Ok(_) => (),
        Err(err) => return Err(Error::CSVWriteHeaderError(err.to_string()))
    };

    for row in data.rows {
        match wrt.write_record(row.as_slice()) {
            Ok(_) => (),
            Err(err) => return Err(Error::CSVWriteRowError(err.to_string()))
        };
    }

    match wrt.into_inner() {
        Ok(raw) => {
            let data = String::from_utf8(raw).unwrap();
            Ok(data)
        }
        Err(err) => Err(Error::CSVWriteRowError(err.to_string()))
    }
}

/// Takes UTF-8 encoded CSV string and try to figure-out it into `CSVData` structure.
/// At first fetch headers and than collect rows.
///
/// ## Errors
/// * `Error::InvalidEncoding` -  means than string contains non-UTF-8 symbols, mostly impossible case.
/// * `Error::InvalidRowSize`- will be in case when `row` longer than `header`.
/// * `Error::InvalidRow` - will be in case of invalid row format.
pub fn parse_csv(csv_data: String) -> Result<CSVData, Error> {
    if !csv_data.contains(',') {
        return Ok(CSVData::default());
    }

    let mut rdr = csv::ReaderBuilder::new()
        .has_headers(true)
        .flexible(true)
        .from_reader(csv_data.as_bytes());

    let header: Vec<String> = match rdr.headers() {
        Ok(v) => v.iter().map(|el| -> String { el.to_string() }).collect(),
        // according to implementation,
        // this error will be present only in case of invalid encoding
        Err(_) => return Err(Error::InvalidEncoding),
    };

    let header_length = header.len();
    let mut rows: Vec<Vec<String>> = Vec::new();

    for r in rdr.records() {
        match r {
            Ok(record) => {
                // todo(mike): improve this in feature
                if record.as_slice().len() < header_length && record.len() < header_length {
                    continue;
                }

                let mut row: Vec<String> = record
                    .iter()
                    .map(|el| -> String { el.to_string() })
                    .collect();

                let row_len = row.len();
                if row_len > header_length {
                    return Err(Error::InvalidRowSize(header_length, row_len));
                }

                // if `row` less than `header`, append empty values
                if row_len < header_length {
                    while row.len() < header_length {
                        row.push("".to_string())
                    }
                }

                rows.push(row);
            }
            Err(_) => return Err(Error::InvalidRow),
        }
    }

    Ok(CSVData { header, rows })
}

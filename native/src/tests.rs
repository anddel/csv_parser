use csv;
use std::fs::File;
use std::io::Read;

use crate::csv_tool::*;

fn test_files() -> [(&'static str, usize, usize); 8] {
    [
        ("BeKB_agenda.csv", 5, 15),
        ("CapShare Random Test Data.csv", 21, 117),
        ("share_register_template.csv", 38, 4),
        ("temp.csv", 16, 4),
        ("UploadLegalEntity.csv", 13, 3),
        ("UploadNaturalPerson.csv", 20, 7),
        ("UploadRegister.csv", 21, 10),
        ("Zermatt_Bergbahnen_AG_-_Agenda_Items_2019_Upload.csv", 5, 8),
    ]
}

#[test]
fn empty_csv_to_json() {
    let empty = "".to_string().as_bytes().to_vec();
    let res = csv_to_json(empty).unwrap();
    assert_eq!(res, r#"{"header":[],"rows":[]}"#)
}

#[test]
fn handle_row_size() {
    let csv_str = "a,,b\nd,d,S,";
    let result = parse_csv(csv_str.to_string());

    match result {
        Err(e) => assert_eq!(e, Error::InvalidRowSize(3, 4)),
        Ok(_) => assert!(false),
    }
}

#[test]
fn transcode_test_files_as_expected() {
    let test_set = test_files();

    for (path, col_n, rows_n) in test_set.iter() {
        let mut f = File::open("../test/data/".to_owned() + path).unwrap();
        let mut buffer = Vec::new();

        // read the whole file
        f.read_to_end(&mut buffer).unwrap();

        let str_data = csv_to_json(buffer).unwrap();
        let res: CSVData = serde_json::from_str(str_data.as_str()).unwrap();

        assert_eq!(col_n.to_owned(), res.header.len(), "{}", path);
        assert_eq!(rows_n.to_owned(), res.rows.len(), "{}", path);
    }
}

#[test]
fn check_that_test_files_parse_as_expected() {
    let file_list = test_files();

    for (path, col_n, rows_n) in file_list.iter() {
        let mut f = File::open("../test/data/".to_owned() + path).unwrap();
        let mut buffer = Vec::new();

        // read the whole file
        f.read_to_end(&mut buffer).unwrap();

        let str_data = sanitize_string(buffer);

        let mut rdr = csv::ReaderBuilder::new()
            .has_headers(true)
            .flexible(true)
            .from_reader(str_data.as_bytes());

        let col = col_n.to_owned();
        match rdr.headers() {
            Ok(header) => {
                // println!("{:?}", header);
                assert_eq!(col, header.len(), "{}", path);
            }
            Err(e) => {
                println!("ERROR: {}", e);
                assert!(false)
            }
        };

        let mut row_counter = 0 as usize;
        for result in rdr.records() {
            match result {
                Ok(record) => {
                    // todo(mike): improve this in feature
                    if record.as_slice().len() < col && record.len() < col {
                        continue;
                    }
                    // println!("{:?}", record);
                    row_counter += 1;
                }
                Err(e) => {
                    println!("ERROR: {}", e);
                    assert!(false)
                }
            };
        }

        assert_eq!(rows_n.to_owned(), row_counter, "{}", path);
    }
}

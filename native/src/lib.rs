#![allow(clippy::not_unsafe_ptr_arg_deref)]

#[macro_use]
extern crate serde_derive;

use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::ptr::null;

mod csv_tool;

#[cfg(test)]
mod tests;

pub const RESULT_ERR: c_int = -1;
pub const RESULT_OK: c_int = 1;

#[repr(C)]
pub struct Result {
    code: c_int,
    data: *const c_char,
    err: *const c_char,
}

impl Result {
    fn ok_result<T: Into<Vec<u8>>>(data: T) -> Self {
        let s_val = CString::new(data).unwrap();
        let pointer = s_val.as_ptr();
        std::mem::forget(s_val);

        Result { code: RESULT_OK, data: pointer, err: null() }
    }

    fn err_result(err: csv_tool::Error) -> Self {
        let err_str = format!(r#"{{"error": "{}"}}"#, err.to_string());
        let s_val = CString::new(err_str).unwrap();
        let pointer = s_val.as_ptr();
        std::mem::forget(s_val);

        Result { code: RESULT_ERR, data: null(), err: pointer }
    }

    fn result(&self) -> *const c_char {
        match self.code {
            RESULT_OK => self.data,
            RESULT_ERR => self.err,
            _ => self.err
        }
    }
}

#[no_mangle]
pub extern "C" fn rust_cstr_free(s: *mut c_char) {
    unsafe {
        if s.is_null() {
            return;
        }
        CString::from_raw(s)
    };
}

#[no_mangle]
pub extern "C" fn csv_to_json(content: *const c_char) -> *const c_char {
    let c_str = unsafe { CStr::from_ptr(content) };
    let csv_data = c_str.to_bytes().to_vec();

    match csv_tool::csv_to_json(csv_data) {
        Ok(json) => {
            let data = format!(r#"{{"data": {}}}"#, json);
            Result::ok_result(data).result()
        },
        Err(err) => Result::err_result(err).result()
    }
}

#[no_mangle]
pub extern "C" fn json_to_csv(content: *const c_char) -> *const c_char {
    let c_str = unsafe { CStr::from_ptr(content) };
    let json_data = c_str.to_bytes().to_vec();


    match csv_tool::json_to_csv(json_data) {
        Ok(csv) => {
            let data = format!(r#"{{"data": {:?}}}"#, csv);
            Result::ok_result(data).result()
        },
        Err(err) => Result::err_result(err).result()
    }
}

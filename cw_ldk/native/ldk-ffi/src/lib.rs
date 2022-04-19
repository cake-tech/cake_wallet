#![allow(unused_imports)]
#![allow(unused_variables)]
#![allow(unused_macros)]

use std::os::raw::{c_char};
use std::ffi::{CString, CStr};
use std::env;
use std::fs;
use std::path::Path;
use std::fs::File;
use std::io::prelude::*;

use ldk_lib::cli::{ LdkUserInfo, setup_ldkuserinfo};

// lib.rs
use tokio::runtime::{Builder, Runtime};
use lazy_static::lazy_static;
use std::io;

use allo_isolate::Isolate;
use std::sync::mpsc;

lazy_static! {
    // build runtime
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread()
        .worker_threads(4)
        .thread_name("flutterrust")
        .thread_stack_size(3 * 1024 * 1024)
        .build();
    
    // static ref STATIC_CHANNEL: (mpsc::Sender<String>, mpsc::Receiver<String>) = mpsc::channel(); 
}

/// Simple Macro to help getting the value of the runtime.
macro_rules! runtime {
    () => {
        match RUNTIME.as_ref() {
            Ok(rt) => rt,
            Err(_) => {
                return 0;
            }
        }
    };
}

#[allow(unused_macros)]
macro_rules! error {
    ($result:expr) => {
        error!($result, 0);
    };
    ($result:expr, $error:expr) => {
        match $result {
            Ok(value) => value,
            Err(e) => {
                ffi_helpers::update_last_error(e);
                return $error;
            }
        }
    };
}

#[allow(unused_macros)]
macro_rules! cstr {
    ($ptr:expr) => {
        cstr!($ptr, 0);
    };
    ($ptr:expr, $error:expr) => {{
        null_pointer_check!($ptr);
        error!(unsafe { CStr::from_ptr($ptr).to_str() }, $error)
    }};
}


pub fn c_char_to_string(arg: *const c_char) -> String {
    let c_str: &CStr = unsafe { CStr::from_ptr(arg) };
    let str_slice: &str = c_str.to_str().unwrap();
    str_slice.to_string()
}

#[no_mangle]
pub extern "C" fn test_ldk_block(
    path: *const c_char,
    func: unsafe extern "C" fn(*mut c_char)
) -> *mut c_char {
    
    // let rt = runtime!(); 
    // figure out how to make this static latter
    // let rt = Runtime::new().unwrap();

	// let ldk_userinfo: LdkUserInfo = setup_ldkuserinfo(
	// 	"polaruser:polarpass@192.168.0.6:18443".to_string(),
	// 	"./".to_string(),
	// 	9732,
	// 	"regtest".to_string(),
    //     "hellolightning".to_string(),
	// 	"0.0.0.0".to_string()
	// ).unwrap();

    // let res = rt.block_on(async move {
    //     ldk_lib::flutter_ldk(ldk_userinfo).await
    // });

    unsafe {
        func(CString::new("hello world").unwrap().into_raw());
    }

    // let penv = env::current_dir().unwrap();
    // let p = format!("{}/.ldk", penv.display());
    // let p = ".ldk";
    let p = c_char_to_string(path);
   
    let res:&str;
    if !Path::new(&p).exists() {
        res = match std::fs::create_dir(&p) {
            Ok(_) => "...directory was created",
            Err(_) => "!!!***error: could not create dir",
        };
    }
    else {
        res = "....directory already exists"
    }
    
    // let mut file = File::create("foo.txt").expect("can't create file.");
    // file.write_all(b"hello world!").expect("can not write to file");
    // let path = std::path::Path::new(&p);

    CString::new(format!("{}", res)).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn test_ldk_async(
    isolate_port: i64, 
    rpc_info: *const c_char,
    ldk_storage_path: *const c_char,
) -> i32 {

    let rt = runtime!();

	let ldk_userinfo: LdkUserInfo = setup_ldkuserinfo(
		c_char_to_string(rpc_info),
        c_char_to_string(ldk_storage_path),
		9732,
		"regtest".to_string(),
        "hellolightning".to_string(),
		"0.0.0.0".to_string()
	).unwrap();

    // let task = Isolate::new(isolate_port).task(async move {
    //     ldk_lib::flutter_ldk(ldk_userinfo).await
    // });

    // rt.spawn(task);

    rt.spawn(async move {
        let isolate = Isolate::new(isolate_port);
        let res = ldk_lib::flutter_ldk(ldk_userinfo).await;
        isolate.post(res);
    });

    1
}

#[no_mangle]
pub unsafe extern "C" fn last_error_length() -> i32 {
    ffi_helpers::error_handling::last_error_length()
}

#[no_mangle]
pub unsafe extern "C" fn error_message_utf8(buf: *mut c_char, length: i32) -> i32 {
    ffi_helpers::error_handling::error_message_utf8(buf, length)
}
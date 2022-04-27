#![allow(unused_imports)]
#![allow(unused_variables)]
#![allow(unused_macros)]

/// this is the code that creates an interface to the flutter ffi.

// standard libary
use std::os::raw::c_char;
use std::ffi::{CString, CStr};
use std::env;
use std::fs;
use std::path::Path;
use std::fs::File;
use std::io::prelude::*;
use std::io;
use std::sync::mpsc;
use std::sync::mpsc::{Sender, SyncSender, Receiver, sync_channel};
use std::sync::Mutex;
use std::thread;

// packages.
use tokio::runtime::{Builder, Runtime};
use lazy_static::lazy_static;
use allo_isolate::Isolate;

// code in workspace.
// use ldk_lib::cli::{ LdkUserInfo, setup_ldkuserinfo};

// Create runtime for tokio in the static scope 
lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread()
        .worker_threads(4)
        .thread_name("flutterrust")
        .thread_stack_size(3 * 1024 * 1024)
        .build();
}

// Get reference to runtime in static scope
macro_rules! runtime {
    () => {
        RUNTIME.as_ref().unwrap()
    };
}

// Create channels on the static scope.
lazy_static! {
	static ref LDK_CHANNEL: (SyncSender<String>, Mutex<Receiver<String>> ) = {
		let (send, recv) = sync_channel(1);
		(send, Mutex::new(recv))
	};
	static ref FFI_CHANNEL: (SyncSender<String>, Mutex<Receiver<String>> ) = {
		let (send, recv) = sync_channel(1);
		(send, Mutex::new(recv))
	};
}

// Get references to channels on the static scope.
macro_rules! channel {
    (ldk) => {
	    (&(*LDK_CHANNEL).0, &(*LDK_CHANNEL).1)
    };
    (ffi) => {
	    (&(*FFI_CHANNEL).0, &(*FFI_CHANNEL).1)
    };
}

// get senders for static channels
macro_rules! sender {
    (ldk) => {
	    &(*LDK_CHANNEL).0
    };
    (ffi) => {
	    &(*FFI_CHANNEL).0
    };
}

// get receivers for static channels
macro_rules! receiver {
    (ldk) => {
	    &((*LDK_CHANNEL).1).lock().unwrap()
    };
    (ffi) => {
	    &((*FFI_CHANNEL).1).lock().unwrap()
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

/// Convert c_char to String.
pub fn c_char_to_string(arg: *const c_char) -> String {
    let c_str: &CStr = unsafe { CStr::from_ptr(arg) };
    let str_slice: &str = c_str.to_str().unwrap();
    str_slice.to_string()
}


#[no_mangle]
pub unsafe extern "C" fn last_error_length() -> i32 {
    ffi_helpers::error_handling::last_error_length()
}

#[no_mangle]
pub unsafe extern "C" fn error_message_utf8(buf: *mut c_char, length: i32) -> i32 {
    ffi_helpers::error_handling::error_message_utf8(buf, length)
}

#[no_mangle]
pub extern "C" fn start_ldk(
    rpc_info: *const c_char,
    ldk_storage_path: *const c_char,
    port: u16,
    network: *const c_char,
    node_name: *const c_char,
    address: *const c_char,
    mnemonic_key_phrase: *const c_char,
    func: unsafe extern "C" fn(*mut c_char)
) -> *mut c_char  {

    // let callback = move |msg| {
    //     unsafe {
    //         func(CString::new(msg).unwrap().into_raw());
    //     }
    // };

    let rt = runtime!(); 
    rt.block_on(async move {
        let ffi_sender = sender!(ffi);
        let res = ldk_lib::start_ldk(
            c_char_to_string(rpc_info),
            c_char_to_string(ldk_storage_path),
            port,
            c_char_to_string(network),
            c_char_to_string(node_name),
            c_char_to_string(address),
            c_char_to_string(mnemonic_key_phrase),
            ffi_sender,
            Box::new(move |msg| { 
            unsafe {
                func(CString::new(msg).unwrap().into_raw());
            }
        })).await;
        // ffi_sender.send(res).unwrap();
    });

    let ffi_receiver = receiver!(ffi);
    let res = ffi_receiver.recv().unwrap();

    CString::new(res).unwrap().into_raw()
}

// /// remove later.
// /// for testing code that is blocking.
// #[no_mangle]
// pub extern "C" fn test_ldk_block(
//     path: *const c_char,
//     func: unsafe extern "C" fn(*mut c_char)
// ) -> *mut c_char {
    
//     // let rt = runtime!(); 
//     // figure out how to make this static latter
//     // let rt = Runtime::new().unwrap();

// 	// let ldk_userinfo: LdkUserInfo = setup_ldkuserinfo(
// 	// 	"polaruser:polarpass@192.168.0.6:18443".to_string(),
// 	// 	"./".to_string(),
// 	// 	9732,
// 	// 	"regtest".to_string(),
//     //     "hellolightning".to_string(),
// 	// 	"0.0.0.0".to_string()
// 	// ).unwrap();

//     // let res = rt.block_on(async move {
//     //     ldk_lib::flutter_ldk(ldk_userinfo).await
//     // });

//     unsafe {
//         func(CString::new("hello world").unwrap().into_raw());
//     }

//     // let penv = env::current_dir().unwrap();
//     // let p = format!("{}/.ldk", penv.display());
//     // let p = ".ldk";
//     let p = c_char_to_string(path);
   
//     let res:&str;
//     if !Path::new(&p).exists() {
//         res = match std::fs::create_dir(&p) {
//             Ok(_) => "...directory was created",
//             Err(_) => "!!!***error: could not create dir",
//         };
//     }
//     else {
//         res = "....directory already exists"
//     }
    
//     // let mut file = File::create("foo.txt").expect("can't create file.");
//     // file.write_all(b"hello world!").expect("can not write to file");
//     // let path = std::path::Path::new(&p);

//     CString::new(format!("{}", res)).unwrap().into_raw()
// }


// /// Run LDK asynchronous 
// #[no_mangle]
// pub extern "C" fn test_ldk_async(
//     isolate_port: i64, 
//     rpc_info: *const c_char,
//     ldk_storage_path: *const c_char,
// ) -> i32 {
//     let rt = runtime!();

// 	let ldk_userinfo: LdkUserInfo = setup_ldkuserinfo(
// 		c_char_to_string(rpc_info),
//         c_char_to_string(ldk_storage_path),
// 		9732,
// 		"regtest".to_string(),
//         "hellolightning".to_string(),
// 		"0.0.0.0".to_string()
// 	).unwrap();
   
//     // run ldk in seperate thread.
//     let ffi_sender = sender!(ffi);
//     let ffi_sender_clone = ffi_sender.clone();
//     rt.spawn(async move {
//         let res = ldk_lib::flutter_ldk(ldk_userinfo).await;

//         ffi_sender_clone.send(res).unwrap();
//     });

//     // wait for ldk response in seperate thread.
//     // then post to isolate.
//     rt.spawn(async move {
//         let isolate = Isolate::new(isolate_port);
//         let ffi_receiver = receiver!(ffi);

//         let res = ffi_receiver.recv().unwrap();

//         isolate.post(res);
//     });

//     1
// }

// /// remove later.
// /// test to see if channels work on phone.
// #[no_mangle]
// pub extern "C" fn ldk_channels(
//     func: unsafe extern "C" fn(*mut c_char)
// ) {
//     let rt = runtime!();
//     let ldk_sender = sender!(ldk);

//     // test sender.
//     let ldk_sender_clone = ldk_sender.clone();
//     rt.spawn(async move {
//         ldk_sender_clone.send("message1 from ldk sender".to_string()).unwrap();        
//         ldk_sender_clone.send("message2 from ldk sender".to_string()).unwrap();
//         ldk_sender_clone.send("message3 from ldk sender".to_string()).unwrap();
//         ldk_sender_clone.send("exit".to_string()).unwrap();
//     });

//     // wait until receive messages from sender.
// 	let rx = receiver!(ldk);
// 	for msg in rx.iter() {
//         // exit out of loop
// 		if msg == "exit" {
//             unsafe {
//                 func(CString::new("exit from ldk sender").unwrap().into_raw());
//             }
// 			break;
// 		}
//         // print to debug console.
//         unsafe {
//             func(CString::new(msg).unwrap().into_raw());
//         }
// 	}
// }

// /// remove later.
// /// another test for channels.
// #[no_mangle]
// pub extern "C" fn ffi_channels(
//     func: unsafe extern "C" fn(*mut c_char)
// ) {
//     let rt = runtime!();
//     let ffi_sender = sender!(ffi);

//     // test ffi_sender
//     let ffi_sender_clone = ffi_sender.clone();
//     rt.spawn(async move {
//         ffi_sender_clone.send("message1 from ffi sender".to_string()).unwrap();        
//         ffi_sender_clone.send("message2 from ffi sender".to_string()).unwrap();
//         ffi_sender_clone.send("message3 from ffi sender".to_string()).unwrap();
//         ffi_sender_clone.send("exit".to_string()).unwrap();
//     });

//     // receive messages from ffi
// 	let rx = receiver!(ffi);
// 	for msg in rx.iter() {
//         // exit out of loop
// 		if msg == "exit" {
//             unsafe {
//                 func(CString::new("exit from ffi sender").unwrap().into_raw());
//             }
// 			break;
// 		}
//         // print message to debug console.
//         unsafe {
//             func(CString::new(msg).unwrap().into_raw());
//         }
// 	}

//     // test ldk sender
//     let ldk_sender = sender!(ldk);
//     ldk_sender.send("hello from ldk_sender".to_string()).unwrap();

//     // receive message from ldk seperate thread.
//     let ffi_sender_clone2 = ffi_sender.clone();
//     rt.spawn(async move {
//         let ldk_receiver = receiver!(ldk);
//         let res = ldk_receiver.recv().unwrap();
//         ffi_sender_clone2.send(format!("resend from ffi_sender: {}",res)).unwrap();
//     });

//     // receive message from ffi
//     let res = rx.recv().unwrap();
//     unsafe {
//         func(CString::new(res).unwrap().into_raw());
//     }
// }

/// my tests.
#[cfg(test)]
mod tests {

    // use super::{ldk_channels, ffi_channels};

    // no longer works on computer.  only on phone.
	#[test]
	fn test_start_ldk(){
        // ldk_channels();
		// ffi_channels();
	}


}

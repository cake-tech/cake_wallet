#![allow(unused_imports)]

use std::os::raw::{c_char};
use std::ffi::{CString, CStr};
use std::str;

// use std::ffi::CStr;
// use std::str;

#[tokio::main]
async fn main(){
    // let rpc_info = CString::new("polaruser:polarpass@127.0.0.1:18443").unwrap().into_raw();
    // let rpc_info = CString::new("polaruser:polarpass@192.168.0.6:18443").unwrap().into_raw();
    // let res: *const c_char = ldk_ffi::test_ldk(rpc_info);
    // let res = ldk_ffi::c_char_to_string(res);
    // println!("{}", res);
}

// #[cfg(test)]
// mod tests {

    // #[test]
    // fn test_blocking(){
    //     let res = ldk_ffi::test_ldk_block();
    //     let res = ldk_ffi::c_char_to_string(res);
    //     println!("{}",res);
    // }
    // #[tokio::test]
    // async fn test_ldk() {
    //     let res = ldk_ffi::test_ldk();
    //     let res = ldk_ffi::c_char_to_string(res);
    //     assert_ne!(res, "");
    // }
// }

#![allow(unused_imports)]

use ldk_lib::cli::{ LdkUserInfo, setup_ldkuserinfo};


#[tokio::main]
pub async fn main(){
	let ldk_userinfo: LdkUserInfo = setup_ldkuserinfo(
		"polaruser:polarpass@127.0.0.1:18443".to_string(),
		"./".to_string(),
		9732,
		"regtest".to_string(),
        "hellolightning".to_string(),
		"0.0.0.0".to_string()
	).unwrap();

	ldk_lib::start_ldk(Some(ldk_userinfo)).await;
	// let res = ldk_lib::flutter_ldk(ldk_userinfo).await;
	// println!("{}",res);
}


// #[cfg(test)]
// mod tests {

	// #[test]
	// fn test_threads(){
	// 	println!("hello test thread");
	// }
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
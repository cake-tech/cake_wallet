#![allow(dead_code)]

pub async fn start_ldk(
    rpc_info: String,
    ldk_storage_path: String,
    mnemonic_key_phrase: String,
    callback: Box<dyn Fn(&str)>
) -> String {
    callback("...hello from start_ldk");
    format!("...finish start_ldk({}, {}, {})", rpc_info, ldk_storage_path, mnemonic_key_phrase)
}


#[cfg(test)]
mod tests {
    use super::start_ldk;

	#[test]
	fn test_start_ldk(){
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async move {
            // println!("hello ldk...");
            let res = start_ldk(
                "rpc_info".to_string(),
                "ldk_storage_path".to_string(),
                "mnemonic_key_phrase".to_string(),
                Box::new(|msg| { println!("{}",msg)})).await;
            
            println!("{}",res);
        })
	}
}

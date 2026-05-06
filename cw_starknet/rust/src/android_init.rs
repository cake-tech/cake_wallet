#![cfg(target_os = "android")]

use std::sync::Once;

use jni::objects::{JClass, JObject};
use jni::JNIEnv;

static INIT: Once = Once::new();

#[no_mangle]
pub extern "system" fn Java_com_cakewallet_cake_1wallet_StarknetRust_nativeInit<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    context: JObject<'local>,
) {
    INIT.call_once(|| {
        crate::ensure_crypto_provider();
        if let Err(err) = rustls_platform_verifier::android::init_hosted(&mut env, context) {
            eprintln!("[cw_starknet] rustls_platform_verifier init_hosted failed: {err:?}");
        }
    });
}

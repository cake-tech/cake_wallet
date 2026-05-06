pub mod api;
mod frb_generated;

#[cfg(target_os = "android")]
mod android_init;

pub(crate) fn ensure_crypto_provider() {
    use std::sync::Once;
    static INIT: Once = Once::new();
    INIT.call_once(|| {
        let _ = rustls::crypto::ring::default_provider().install_default();
    });
}

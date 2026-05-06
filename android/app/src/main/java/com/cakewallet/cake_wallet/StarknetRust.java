package com.cakewallet.cake_wallet;

import android.content.Context;

public final class StarknetRust {
    private static boolean sInitialized = false;

    static {
        System.loadLibrary("cw_starknet_rust");
    }

    private StarknetRust() {}

    public static synchronized void ensureInitialized(Context context) {
        if (sInitialized) return;
        nativeInit(context.getApplicationContext());
        sInitialized = true;
    }

    private static native void nativeInit(Context context);
}

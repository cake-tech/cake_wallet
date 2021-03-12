package com.cakewallet.cake_wallet;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.nio.ByteBuffer;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryCodec;
import io.flutter.plugins.GeneratedPluginRegistrant;


public class MainActivity extends FlutterFragmentActivity {
    public static final int DATA_EXISTS = 1;
    public static final int DATA_NOT_EXISTS = 0;
    BasicMessageChannel<ByteBuffer> dataChannel;
    Handler handler = new Handler(Looper.getMainLooper());

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        dataChannel = new BasicMessageChannel<ByteBuffer>(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                "data_change", BinaryCodec.INSTANCE);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        ByteBuffer buffer = ByteBuffer.allocateDirect(4);
        if (data != null) {
          buffer.putInt(DATA_EXISTS);  
        } else {
          buffer.putInt(DATA_NOT_EXISTS);
        }
        handler.post(() -> dataChannel.send(buffer));
    }
}
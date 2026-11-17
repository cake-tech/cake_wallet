package com.cakewallet.cake_wallet;

import android.content.Context;
import android.media.AudioManager;
import android.os.Build;

import androidx.annotation.RequiresApi;

import io.flutter.plugin.common.EventChannel;

final class PhoneCallStatusStreamHandler implements EventChannel.StreamHandler {
    private final Context context;
    @RequiresApi(api = Build.VERSION_CODES.S)
    private AudioManager.OnModeChangedListener audioModeListener;

    PhoneCallStatusStreamHandler(Context context) {
        this.context = context.getApplicationContext();
    }

    static boolean isOnPhoneCall(Context context) {
        return isCallMode(getAudioManager(context).getMode());
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioModeListener = mode -> events.success(isCallMode(mode));
            getAudioManager(context).addOnModeChangedListener(context.getMainExecutor(), audioModeListener);
        }
        events.success(isOnPhoneCall(context));
    }

    @Override
    public void onCancel(Object arguments) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && audioModeListener != null) {
            getAudioManager(context).removeOnModeChangedListener(audioModeListener);
            audioModeListener = null;
        }
    }

    private static AudioManager getAudioManager(Context context) {
        return (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
    }

    private static boolean isCallMode(int mode) {
        return mode == AudioManager.MODE_IN_CALL || mode == AudioManager.MODE_IN_COMMUNICATION;
    }
}

package com.cakewallet.cake_wallet;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import java.io.File;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class AppBackupChannel implements MethodChannel.MethodCallHandler {
    static final String CHANNEL = "com.cake_wallet/app_backup";

    // yes this is the google drive app. this is not google docs.
    private static final String DRIVE_PACKAGE = "com.google.android.apps.docs";

    private final Activity activity;

    AppBackupChannel(Activity activity) {
        this.activity = activity;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "is_drive_installed":
                result.success(isDriveInstalled());
                break;
            case "share_to_drive":
                String path = call.argument("path");
                if (path == null || !new File(path).isFile()) {
                    result.error("file_not_found", "No file to share at " + path, null);
                    return;
                }
                try {
                    Uri uri = FileProvider.getUriForFile(activity,
                            activity.getPackageName() + ".app_backup_fileprovider", new File(path));
                    Intent intent = new Intent(Intent.ACTION_SEND)
                            .setType("application/zip")
                            .setPackage(DRIVE_PACKAGE)
                            .putExtra(Intent.EXTRA_STREAM, uri)
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    intent.setClipData(ClipData.newRawUri("", uri));
                    activity.startActivity(intent);
                    result.success(true);
                } catch (Exception e) {
                    result.error("share_failed", e.getMessage(), null);
                }
                break;
            default:
                result.notImplemented();
        }
    }

    private boolean isDriveInstalled() {
        try {
            activity.getPackageManager().getPackageInfo(DRIVE_PACKAGE, 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }
}

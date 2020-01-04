#include <string.h>
#include <jni.h>
#include "../../ios/Classes/monero_api.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT void JNICALL
Java_com_cakewallet_monero_MoneroApi_setNodeAddressJNI(
        JNIEnv *env,
        jobject inst,
        jstring uri,
        jstring login,
        jstring password,
        jboolean use_ssl,
        jboolean is_light_wallet) {
    const char *_uri = env->GetStringUTFChars(uri, 0);
    const char *_login = "";
    const char *_password = "";
    char *error;

    if (login != NULL) {
        _login = env->GetStringUTFChars(login, 0);
    }

    if (password != NULL) {
        _password = env->GetStringUTFChars(password, 0);
    }
    char *__uri = (char*) _uri;
    char *__login = (char*) _login;
    char *__password = (char*) _password;
    bool inited = setup_node(__uri, __login, __password, false, false, error);

    if (!inited) {
        env->ThrowNew(env->FindClass("java/lang/Exception"), error);
    }
}

JNIEXPORT void JNICALL
Java_com_cakewallet_monero_MoneroApi_connectToNodeJNI(
        JNIEnv *env,
        jobject inst) {
    char *error;
    bool is_connected = connect_to_node(error);

    if (!is_connected) {
        env->ThrowNew(env->FindClass("java/lang/Exception"), error);
    }
}

JNIEXPORT void JNICALL
Java_com_cakewallet_monero_MoneroApi_startSyncJNI(
        JNIEnv *env,
        jobject inst) {
    start_refresh();
}

JNIEXPORT void JNICALL
Java_com_cakewallet_monero_MoneroApi_loadWalletJNI(
        JNIEnv *env,
        jobject inst,
        jstring path,
        jstring password) {
    char *_path = (char *) env->GetStringUTFChars(path, 0);
    char *_password = (char *) env->GetStringUTFChars(password, 0);

    load_wallet(_path, _password, 0);
}

#ifdef __cplusplus
}
#endif
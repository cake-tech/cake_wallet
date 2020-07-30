#include <string.h>
#include <jni.h>
#include "../../ios/Classes/monero_api.cpp"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

static JavaVM *jvm = NULL;
static jclass listener_class;

std::mutex _listenerMutex;

int attachJVM(JNIEnv **jenv) {
    int envStat = jvm->GetEnv((void **) jenv, JNI_VERSION_1_6);
    if (envStat == JNI_EDETACHED) {
        if (jvm->AttachCurrentThread(jenv, nullptr) != 0) {
            return JNI_ERR;
        }
    } else if (envStat == JNI_EVERSION) {
        return JNI_ERR;
    }

    return envStat;
}

void detachJVM(JNIEnv *jenv, int envStat) {
    if (jenv->ExceptionCheck()) {
        jenv->ExceptionDescribe();
    }

    if (envStat == JNI_EDETACHED) {
        jvm->DetachCurrentThread();
    }
}

struct MoneroWalletListenerWrapper: Monero::WalletListener {
    jobject listener;

    MoneroWalletListenerWrapper(JNIEnv *env, jobject aListener) {
        listener = env->NewGlobalRef(aListener);
    }

    void moneySpent(const std::string &txId, uint64_t amount) {
        std::lock_guard<std::mutex> lock(_listenerMutex);
        JNIEnv *jenv;
        int envStat = attachJVM(&jenv);
        if (envStat == JNI_ERR) return;

        jmethodID mid = jenv->GetMethodID(listener_class, "moneySpent", "()V");
        jenv->CallVoidMethod(listener, mid);
        detachJVM(jenv, envStat);
    }

    void moneyReceived(const std::string &txId, uint64_t amount) {
        std::lock_guard<std::mutex> lock(_listenerMutex);
        JNIEnv *jenv;
        int envStat = attachJVM(&jenv);
        if (envStat == JNI_ERR) return;

        jmethodID mid = jenv->GetMethodID(listener_class, "moneyReceived", "()V");
        jenv->CallVoidMethod(listener, mid);
        detachJVM(jenv, envStat);
    }

    void unconfirmedMoneyReceived(const std::string &txId, uint64_t amount) {
        std::lock_guard<std::mutex> lock(_listenerMutex);
        JNIEnv *jenv;
        int envStat = attachJVM(&jenv);
        if (envStat == JNI_ERR) return;

        jmethodID mid = jenv->GetMethodID(listener_class, "unconfirmedMoneyReceived", "()V");
        jenv->CallVoidMethod(listener, mid);
        detachJVM(jenv, envStat);
    }

    void newBlock(uint64_t height) {
        std::lock_guard<std::mutex> lock(_listenerMutex);
        JNIEnv *jenv;
        int envStat = attachJVM(&jenv);
        if (envStat == JNI_ERR) return;

        jmethodID mid = jenv->GetMethodID(listener_class, "newBlock", "(J)V");
        jlong height_as_long = static_cast<jlong>(height);
        jenv->CallVoidMethod(listener, mid, height_as_long);
        detachJVM(jenv, envStat);
    }

    void updated() {
        std::lock_guard<std::mutex> lock(_listenerMutex);
        JNIEnv *jenv;
        int envStat = attachJVM(&jenv);
        if (envStat == JNI_ERR) return;

        jmethodID mid = jenv->GetMethodID(listener_class, "updated", "()V");
        jenv->CallVoidMethod(listener, mid);
        detachJVM(jenv, envStat);
    }

    void refreshed() {
        std::lock_guard<std::mutex> lock(_listenerMutex);
        JNIEnv *jenv;
        int envStat = attachJVM(&jenv);
        if (envStat == JNI_ERR) return;

        jmethodID mid = jenv->GetMethodID(listener_class, "refreshed", "()V");
        jenv->CallVoidMethod(listener, mid);
        detachJVM(jenv, envStat);
    }
};

static MoneroWalletListenerWrapper *listenerWrapper = NULL;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *_jvm, void *reserved) {
    jvm = _jvm;
    JNIEnv *jenv;

    if (jvm->GetEnv(reinterpret_cast<void **>(&jenv), JNI_VERSION_1_6) != JNI_OK) {
        return -1;
    }

    listener_class = static_cast<jclass>(jenv->NewGlobalRef(jenv->FindClass("com/cakewallet/monero/MoneroWalletSyncStatusListener")));

    return JNI_VERSION_1_6;
}

JNIEXPORT void JNICALL
Java_com_cakewallet_monero_MoneroApi_setupListenerJNI(JNIEnv *env, jobject inst, jobject listener) {
    listenerWrapper = new MoneroWalletListenerWrapper(env, listener);
    get_current_wallet()->setListener(listenerWrapper);
}

#ifdef __cplusplus
}
#endif
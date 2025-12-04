#include "godot_bridge.h"
#include <android/log.h>
#include <chrono>
#include <atomic>

#define LOG_TAG "GodotBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global state
static std::atomic<uint64_t> g_messages_sent{0};
static std::atomic<uint64_t> g_messages_received{0};
static std::atomic<uint64_t> g_total_latency{0};
static std::atomic<uint64_t> g_min_latency{UINT64_MAX};
static std::atomic<uint64_t> g_max_latency{0};

extern "C" {

int initialize_shared_memory(uint8_t* buffer, size_t size) {
    LOGI("Initialize shared memory: %zu bytes", size);
    return 1;
}

int send_binary_message(size_t length) {
    g_messages_sent++;
    return 1;
}

int receive_binary_message() {
    g_messages_received++;
    return 0;
}

PerformanceMetrics* get_performance_metrics() {
    static PerformanceMetrics metrics;
    metrics.messages_sent = g_messages_sent.load();
    metrics.messages_received = g_messages_received.load();
    metrics.total_latency_nanos = g_total_latency.load();
    metrics.min_latency_nanos = g_min_latency.load();
    metrics.max_latency_nanos = g_max_latency.load();
    return &metrics;
}

void reset_performance_metrics() {
    g_messages_sent = 0;
    g_messages_received = 0;
    g_total_latency = 0;
    g_min_latency = UINT64_MAX;
    g_max_latency = 0;
}

void cleanup() {
    reset_performance_metrics();
    LOGI("Cleanup completed");
}

// JNI Bindings
JNIEXPORT jboolean JNICALL
Java_com_example_flutter_1godot_1bridge_CommunicationBridge_nativeInitializeGodot(
        JNIEnv* env, jobject thiz, jobject context, jstring projectPath) {
    const char* path = env->GetStringUTFChars(projectPath, nullptr);
    LOGI("nativeInitializeGodot path=%s", path);
    env->ReleaseStringUTFChars(projectPath, path);
    reset_performance_metrics();
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_com_example_flutter_1godot_1bridge_CommunicationBridge_nativeSendMessage(
        JNIEnv* env, jobject thiz, jstring channel, jobject data, jlong timestamp) {
    // Accept jobject (ByteBuffer) instead of jbyteArray
    if (!data) return JNI_FALSE;

    // Process message
    g_messages_sent++;

    return JNI_TRUE;
}

JNIEXPORT jbyteArray JNICALL
Java_com_example_flutter_1godot_1bridge_CommunicationBridge_nativeReceiveMessage(
        JNIEnv* env, jobject thiz) {
    g_messages_received++;
    return nullptr;
}

JNIEXPORT jobject JNICALL
Java_com_example_flutter_1godot_1bridge_CommunicationBridge_nativeGetPerformanceMetrics(
        JNIEnv* env, jobject thiz) {
    PerformanceMetrics* metrics = get_performance_metrics();

    jclass mapClass = env->FindClass("java/util/HashMap");
    if (!mapClass) return nullptr;

    jmethodID init = env->GetMethodID(mapClass, "<init>", "()V");
    jmethodID put = env->GetMethodID(mapClass, "put",
                                     "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
    if (!init || !put) return nullptr;

    jobject map = env->NewObject(mapClass, init);
    if (!map) return nullptr;

    jclass longClass = env->FindClass("java/lang/Long");
    if (!longClass) return nullptr;

    jmethodID valueOf = env->GetStaticMethodID(longClass, "valueOf", "(J)Ljava/lang/Long;");
    if (!valueOf) return nullptr;

    env->CallObjectMethod(map, put,
                          env->NewStringUTF("messagesSent"),
                          env->CallStaticObjectMethod(longClass, valueOf, (jlong)metrics->messages_sent));

    env->CallObjectMethod(map, put,
                          env->NewStringUTF("messagesReceived"),
                          env->CallStaticObjectMethod(longClass, valueOf, (jlong)metrics->messages_received));

    return map;
}

JNIEXPORT void JNICALL
Java_com_example_flutter_1godot_1bridge_CommunicationBridge_nativeCleanup(
        JNIEnv* env, jobject thiz) {
cleanup();
}

}



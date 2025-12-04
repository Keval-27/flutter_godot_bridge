#ifndef GODOT_BRIDGE_H
#define GODOT_BRIDGE_H

#include <jni.h>
#include <cstdint>

extern "C" {

// Performance metrics structure
struct PerformanceMetrics {
    uint64_t messages_sent;
    uint64_t messages_received;
    uint64_t total_latency_nanos;
    uint64_t min_latency_nanos;
    uint64_t max_latency_nanos;
};

// Core functions
int initialize_shared_memory(uint8_t* buffer, size_t size);
int send_binary_message(size_t length);
int receive_binary_message();
PerformanceMetrics* get_performance_metrics();
void reset_performance_metrics();
void cleanup();

} // extern "C"

#endif // GODOT_BRIDGE_H

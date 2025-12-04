import Foundation
import Flutter

@objc
public class CommunicationBridge: NSObject {
    private let channel: FlutterMethodChannel
    private var isInitialized = false
    private let messageQueue = DispatchQueue(label: "godot.bridge.messages", qos: .userInitiated)

    // Performance metrics
    private var messagesSent: UInt64 = 0
    private var messagesReceived: UInt64 = 0
    private var totalLatency: UInt64 = 0
    private var minLatency: UInt64 = UInt64.max
    private var maxLatency: UInt64 = 0

    @objc
    public init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    @objc
    public func initialize(config: [String: Any]) -> Bool {
        return messageQueue.sync {
            // TODO: Initialize Godot communication bridge
            self.isInitialized = true
            NSLog("CommunicationBridge initialized with config: \(config)")
            return true
        }
    }

    @objc
    public func sendMessage(_ data: [String: Any], channel: String, timestamp: Int64) -> Bool {
        guard isInitialized else { return false }

        return messageQueue.sync {
            let startTime = DispatchTime.now().uptimeNanoseconds

            // TODO: Send message to Godot
            // Simulate message processing
            Thread.sleep(forTimeInterval: 0.001) // 1ms simulation

            let endTime = DispatchTime.now().uptimeNanoseconds
            let latency = endTime - startTime

            updatePerformanceMetrics(latency: latency)
            messagesSent += 1

            NSLog("Sent message to channel '\(channel)': \(data)")
            return true
        }
    }

    @objc
    public func sendSyncMessage(_ data: [String: Any], channel: String, timestamp: Int64) -> [String: Any] {
        guard isInitialized else {
            return ["error": "Bridge not initialized"]
        }

        return messageQueue.sync {
            let startTime = DispatchTime.now().uptimeNanoseconds

            // TODO: Send sync message to Godot and wait for response
            let response: [String: Any] = [
                "success": true,
                "originalMessage": data,
                "responseTime": Date().timeIntervalSince1970 * 1000,
                "platform": "iOS"
            ]

            let endTime = DispatchTime.now().uptimeNanoseconds
            let latency = endTime - startTime

            updatePerformanceMetrics(latency: latency)
            messagesSent += 1

            return response
        }
    }

    @objc
    public func receiveMessage(channel: String, data: [String: Any]) {
        guard isInitialized else { return }

        messageQueue.async {
            self.messagesReceived += 1

            // Forward message to Flutter
            DispatchQueue.main.async {
                self.channel.invokeMethod("onGodotMessage", arguments: [
                    "channel": channel,
                    "data": data
                ])
            }
        }
    }

    @objc
    public func getPerformanceMetrics() -> [String: NSNumber] {
        return messageQueue.sync {
            let avgLatency = messagesSent > 0 ?
                Double(totalLatency) / Double(messagesSent) / 1_000_000.0 : 0.0

            return [
                "messagesSent": NSNumber(value: messagesSent),
                "messagesReceived": NSNumber(value: messagesReceived),
                "averageLatencyMs": NSNumber(value: avgLatency),
                "minLatencyMs": NSNumber(value: Double(minLatency) / 1_000_000.0),
                "maxLatencyMs": NSNumber(value: Double(maxLatency) / 1_000_000.0)
            ]
        }
    }

    private func updatePerformanceMetrics(latency: UInt64) {
        totalLatency += latency
        if minLatency == UInt64.max {
            minLatency = latency
        } else {
            minLatency = min(minLatency, latency)
        }
        maxLatency = max(maxLatency, latency)
    }

    @objc
    public func dispose() -> Bool {
        return messageQueue.sync {
            isInitialized = false
            messagesSent = 0
            messagesReceived = 0
            totalLatency = 0
            minLatency = UInt64.max
            maxLatency = 0
            return true
        }
    }
}

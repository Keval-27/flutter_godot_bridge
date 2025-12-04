import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

class PerformanceMetrics {
  final double averageLatencyMs;
  final double minLatencyMs;
  final double maxLatencyMs;
  final double throughputMsgPerSec;
  final double memoryUsageMB;
  final double cpuUsagePercent;
  final int totalMessagesSent;
  final int totalMessagesReceived;
  final int droppedMessages;
  final int queuedMessages;
  final Map<String, double> channelMetrics;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.averageLatencyMs,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.throughputMsgPerSec,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.totalMessagesSent,
    required this.totalMessagesReceived,
    required this.droppedMessages,
    required this.queuedMessages,
    required this.channelMetrics,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'averageLatencyMs': averageLatencyMs,
      'minLatencyMs': minLatencyMs,
      'maxLatencyMs': maxLatencyMs,
      'throughputMsgPerSec': throughputMsgPerSec,
      'memoryUsageMB': memoryUsageMB,
      'cpuUsagePercent': cpuUsagePercent,
      'totalMessagesSent': totalMessagesSent,
      'totalMessagesReceived': totalMessagesReceived,
      'droppedMessages': droppedMessages,
      'queuedMessages': queuedMessages,
      'channelMetrics': channelMetrics,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class LatencyTracker {
  final Queue<int> _latencies = Queue<int>();
  final int maxSamples;
  int _minLatency = 0;
  int _maxLatency = 0;
  int _totalLatency = 0;

  LatencyTracker({this.maxSamples = 1000});

  void addLatency(int latencyMicros) {
    _latencies.add(latencyMicros);
    _totalLatency += latencyMicros;

    if (_latencies.length == 1) {
      _minLatency = _maxLatency = latencyMicros;
    } else {
      _minLatency = math.min(_minLatency, latencyMicros);
      _maxLatency = math.max(_maxLatency, latencyMicros);
    }

    if (_latencies.length > maxSamples) {
      final removed = _latencies.removeFirst();
      _totalLatency -= removed;

      // Recalculate min/max if necessary
      if (removed == _minLatency || removed == _maxLatency) {
        _recalculateMinMax();
      }
    }
  }

  double get averageLatencyMs =>
      _latencies.isEmpty ? 0.0 : (_totalLatency / _latencies.length) / 1000.0;

  double get minLatencyMs => _minLatency / 1000.0;
  double get maxLatencyMs => _maxLatency / 1000.0;
  int get sampleCount => _latencies.length;

  void _recalculateMinMax() {
    if (_latencies.isEmpty) {
      _minLatency = _maxLatency = 0;
      return;
    }

    _minLatency = _maxLatency = _latencies.first;
    for (final latency in _latencies) {
      _minLatency = math.min(_minLatency, latency);
      _maxLatency = math.max(_maxLatency, latency);
    }
  }

  void reset() {
    _latencies.clear();
    _totalLatency = 0;
    _minLatency = _maxLatency = 0;
  }
}

class ThroughputTracker {
  final Queue<int> _timestamps = Queue<int>();
  final Duration measurementWindow;

  ThroughputTracker({this.measurementWindow = const Duration(seconds: 1)});

  void recordMessage() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _timestamps.add(now);

    // Remove old timestamps outside the window
    final cutoff = now - measurementWindow.inMilliseconds;
    while (_timestamps.isNotEmpty && _timestamps.first < cutoff) {
      _timestamps.removeFirst();
    }
  }

  double get messagesPerSecond {
    if (_timestamps.isEmpty) return 0.0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - measurementWindow.inMilliseconds;

    // Count messages in the current window
    int count = 0;
    for (final timestamp in _timestamps) {
      if (timestamp >= cutoff) count++;
    }

    return count * (1000.0 / measurementWindow.inMilliseconds);
  }

  void reset() {
    _timestamps.clear();
  }
}

class ChannelPerformanceTracker {
  final String channelName;
  final LatencyTracker latencyTracker;
  final ThroughputTracker throughputTracker;
  int messagesSent = 0;
  int messagesReceived = 0;
  int droppedMessages = 0;
  int totalBytes = 0;

  ChannelPerformanceTracker(this.channelName)
      : latencyTracker = LatencyTracker(),
        throughputTracker = ThroughputTracker();

  void recordSentMessage(int sizeBytes) {
    messagesSent++;
    totalBytes += sizeBytes;
    throughputTracker.recordMessage();
  }

  void recordReceivedMessage(int sizeBytes) {
    messagesReceived++;
    totalBytes += sizeBytes;
  }

  void recordLatency(int latencyMicros) {
    latencyTracker.addLatency(latencyMicros);
  }

  void recordDroppedMessage() {
    droppedMessages++;
  }

  Map<String, double> getMetrics() {
    return {
      'messages_sent': messagesSent.toDouble(),
      'messages_received': messagesReceived.toDouble(),
      'dropped_messages': droppedMessages.toDouble(),
      'total_bytes': totalBytes.toDouble(),
      'average_latency_ms': latencyTracker.averageLatencyMs,
      'min_latency_ms': latencyTracker.minLatencyMs,
      'max_latency_ms': latencyTracker.maxLatencyMs,
      'throughput_msg_per_sec': throughputTracker.messagesPerSecond,
      'average_message_size':
          messagesSent > 0 ? totalBytes / messagesSent : 0.0,
    };
  }

  void reset() {
    messagesSent = 0;
    messagesReceived = 0;
    droppedMessages = 0;
    totalBytes = 0;
    latencyTracker.reset();
    throughputTracker.reset();
  }
}

class PerformanceMonitor {
  static const Duration _defaultUpdateInterval = Duration(milliseconds: 500);
  static const Duration _defaultRetentionPeriod = Duration(minutes: 5);

  final Map<String, ChannelPerformanceTracker> _channelTrackers = {};
  final LatencyTracker _globalLatencyTracker = LatencyTracker();
  final ThroughputTracker _globalThroughputTracker = ThroughputTracker();
  final Queue<PerformanceMetrics> _metricsHistory = Queue<PerformanceMetrics>();

  Timer? _updateTimer;
  final StreamController<PerformanceMetrics> _metricsController =
      StreamController<PerformanceMetrics>.broadcast();

  // Counters
  int _totalMessagesSent = 0;
  int _totalMessagesReceived = 0;
  int _globalDroppedMessages = 0;
  int _queuedMessages = 0;

  // Configuration
  Duration updateInterval;
  Duration retentionPeriod;
  bool enableDetailedTracking;

  PerformanceMonitor({
    this.updateInterval = _defaultUpdateInterval,
    this.retentionPeriod = _defaultRetentionPeriod,
    this.enableDetailedTracking = true,
  }) {
    _startMonitoring();
  }

  // Public API
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  void recordSentMessage({
    required String channel,
    required int sizeBytes,
    int? latencyMicros,
  }) {
    _totalMessagesSent++;
    _globalThroughputTracker.recordMessage();

    if (latencyMicros != null) {
      _globalLatencyTracker.addLatency(latencyMicros);
    }

    if (enableDetailedTracking) {
      final tracker = _getOrCreateChannelTracker(channel);
      tracker.recordSentMessage(sizeBytes);

      if (latencyMicros != null) {
        tracker.recordLatency(latencyMicros);
      }
    }
  }

  void recordReceivedMessage({
    required String channel,
    required int sizeBytes,
  }) {
    _totalMessagesReceived++;

    if (enableDetailedTracking) {
      final tracker = _getOrCreateChannelTracker(channel);
      tracker.recordReceivedMessage(sizeBytes);
    }
  }

  void recordDroppedMessage({String? channel}) {
    _globalDroppedMessages++;

    if (enableDetailedTracking && channel != null) {
      final tracker = _getOrCreateChannelTracker(channel);
      tracker.recordDroppedMessage();
    }
  }

  void updateQueuedMessages(int count) {
    _queuedMessages = count;
  }

  ChannelPerformanceTracker _getOrCreateChannelTracker(String channel) {
    return _channelTrackers.putIfAbsent(
      channel,
      () => ChannelPerformanceTracker(channel),
    );
  }

  // Monitoring
  void _startMonitoring() {
    _updateTimer = Timer.periodic(updateInterval, (_) {
      _updateMetrics();
    });
  }

  void _updateMetrics() {
    final metrics = _collectCurrentMetrics();

    // Add to history
    _metricsHistory.add(metrics);

    // Clean old metrics
    final cutoffTime = DateTime.now().subtract(retentionPeriod);
    while (_metricsHistory.isNotEmpty &&
        _metricsHistory.first.timestamp.isBefore(cutoffTime)) {
      _metricsHistory.removeFirst();
    }

    // Broadcast current metrics
    if (!_metricsController.isClosed) {
      _metricsController.add(metrics);
    }
  }

  PerformanceMetrics _collectCurrentMetrics() {
    // Collect channel metrics
    final channelMetrics = <String, double>{};
    for (final entry in _channelTrackers.entries) {
      final metrics = entry.value.getMetrics();
      for (final metricEntry in metrics.entries) {
        channelMetrics['${entry.key}_${metricEntry.key}'] = metricEntry.value;
      }
    }

    return PerformanceMetrics(
      averageLatencyMs: _globalLatencyTracker.averageLatencyMs,
      minLatencyMs: _globalLatencyTracker.minLatencyMs,
      maxLatencyMs: _globalLatencyTracker.maxLatencyMs,
      throughputMsgPerSec: _globalThroughputTracker.messagesPerSecond,
      memoryUsageMB: _estimateMemoryUsage(),
      cpuUsagePercent: 0.0, // Would need platform-specific implementation
      totalMessagesSent: _totalMessagesSent,
      totalMessagesReceived: _totalMessagesReceived,
      droppedMessages: _globalDroppedMessages,
      queuedMessages: _queuedMessages,
      channelMetrics: channelMetrics,
      timestamp: DateTime.now(),
    );
  }

  double _estimateMemoryUsage() {
    // Rough estimation based on tracked data
    double usage = 0.0;

    // Base overhead
    usage += 1.0; // 1MB base

    // Channel trackers
    usage += _channelTrackers.length * 0.5; // 0.5MB per channel

    // Latency samples
    usage += _globalLatencyTracker.sampleCount *
        8 /
        (1024 * 1024); // 8 bytes per sample

    // Metrics history
    usage += _metricsHistory.length * 0.1; // 0.1MB per metrics snapshot

    return usage;
  }

  // Statistics and reporting
  Map<String, dynamic> getDetailedStatistics() {
    final current = _collectCurrentMetrics();

    return {
      'current_metrics': current.toMap(),
      'channel_count': _channelTrackers.length,
      'history_length': _metricsHistory.length,
      'monitoring_uptime_ms':
          _updateTimer != null ? DateTime.now().millisecondsSinceEpoch : 0,
      'channels': _channelTrackers.map(
        (key, value) => MapEntry(key, value.getMetrics()),
      ),
    };
  }

  List<PerformanceMetrics> getMetricsHistory() {
    return List.from(_metricsHistory);
  }

  PerformanceMetrics? getLatestMetrics() {
    return _metricsHistory.isNotEmpty ? _metricsHistory.last : null;
  }

  // Performance analysis
  Map<String, dynamic> analyzePerformance() {
    if (_metricsHistory.isEmpty) {
      return {'status': 'no_data'};
    }

    final recent = _metricsHistory.take(10).toList();
    if (recent.isEmpty) return {'status': 'insufficient_data'};

    final avgLatency =
        recent.map((m) => m.averageLatencyMs).reduce((a, b) => a + b) /
            recent.length;
    final avgThroughput =
        recent.map((m) => m.throughputMsgPerSec).reduce((a, b) => a + b) /
            recent.length;
    final totalDropped = recent.last.droppedMessages;

    // Performance assessment
    String status = 'good';
    final issues = <String>[];

    if (avgLatency > 10.0) {
      status = 'poor';
      issues.add('High latency: ${avgLatency.toStringAsFixed(2)}ms');
    } else if (avgLatency > 5.0) {
      status = 'warning';
      issues.add('Elevated latency: ${avgLatency.toStringAsFixed(2)}ms');
    }

    if (totalDropped > 100) {
      status = 'poor';
      issues.add('High message drop rate: $totalDropped');
    }

    if (avgThroughput < 10.0 && _totalMessagesSent > 0) {
      status = status == 'good' ? 'warning' : status;
      issues.add('Low throughput: ${avgThroughput.toStringAsFixed(1)} msg/s');
    }

    return {
      'status': status,
      'average_latency_ms': avgLatency,
      'average_throughput_msg_per_sec': avgThroughput,
      'total_dropped_messages': totalDropped,
      'issues': issues,
      'recommendations': _generateRecommendations(status, issues),
    };
  }

  List<String> _generateRecommendations(String status, List<String> issues) {
    final recommendations = <String>[];

    if (status == 'poor' || status == 'warning') {
      recommendations.add('Consider reducing message frequency');
      recommendations.add('Enable high-performance mode if available');
      recommendations.add('Check for memory pressure');
    }

    if (issues.any((issue) => issue.contains('latency'))) {
      recommendations.add('Use binary messages for large data');
      recommendations.add('Batch related messages together');
    }

    if (issues.any((issue) => issue.contains('drop rate'))) {
      recommendations.add('Increase queue sizes');
      recommendations.add('Implement exponential backoff');
    }

    return recommendations;
  }

  // Management
  void reset() {
    _totalMessagesSent = 0;
    _totalMessagesReceived = 0;
    _globalDroppedMessages = 0;
    _queuedMessages = 0;

    _globalLatencyTracker.reset();
    _globalThroughputTracker.reset();

    for (final tracker in _channelTrackers.values) {
      tracker.reset();
    }

    _metricsHistory.clear();
  }

  void resetChannel(String channel) {
    _channelTrackers[channel]?.reset();
  }

  void dispose() {
    _updateTimer?.cancel();
    _metricsController.close();
    _channelTrackers.clear();
    _metricsHistory.clear();
  }
}

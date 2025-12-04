import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

enum EventPriority {
  critical, // Camera controls, input events
  high, // Game state updates, UI changes
  medium, // Asset loading, settings
  low, // Analytics, logging
}

enum EventType {
  message,
  binary,
  sync,
  broadcast,
}

class GodotEvent {
  final String id;
  final String channel;
  final Map<String, dynamic>? data;
  final Uint8List? binaryData;
  final EventType type;
  final EventPriority priority;
  final int timestamp;
  final Completer<dynamic>? responseCompleter;
  final Duration? timeout;

  GodotEvent({
    required this.id,
    required this.channel,
    this.data,
    this.binaryData,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.responseCompleter,
    this.timeout,
  });

  bool get isExpired {
    if (timeout == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - timestamp;
    return elapsed > timeout!.inMilliseconds;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channel': channel,
      'data': data,
      'type': type.name,
      'priority': priority.name,
      'timestamp': timestamp,
      'has_binary': binaryData != null,
      'binary_size': binaryData?.length ?? 0,
    };
  }
}

class EventManager {
  static const int _maxQueueSize = 10000;
  static const int _maxRetries = 3;
  static const Duration _defaultTimeout = Duration(seconds: 5);

  // Priority queues for different event types
  final Map<EventPriority, Queue<GodotEvent>> _eventQueues = {
    EventPriority.critical: Queue<GodotEvent>(),
    EventPriority.high: Queue<GodotEvent>(),
    EventPriority.medium: Queue<GodotEvent>(),
    EventPriority.low: Queue<GodotEvent>(),
  };

  // Event tracking
  final Map<String, GodotEvent> _pendingEvents = {};
  final Map<String, StreamController<GodotEvent>> _channelStreams = {};
  final Map<String, int> _channelMessageCounts = {};

  // Processing control
  bool _isProcessing = false;
  Timer? _processingTimer;
  Timer? _cleanupTimer;

  // Statistics
  int _totalEventsProcessed = 0;
  int _totalEventsDropped = 0;
  int _totalEventsRetried = 0;
  final List<int> _processingTimes = [];

  // Configuration
  Duration processingInterval = const Duration(microseconds: 100);
  Duration cleanupInterval = const Duration(seconds: 30);
  bool enableDebugLogging = false;

  EventManager() {
    _startProcessing();
    _startCleanup();
  }

  // Public API
  String addEvent({
    required String channel,
    Map<String, dynamic>? data,
    Uint8List? binaryData,
    EventType type = EventType.message,
    EventPriority priority = EventPriority.medium,
    Duration? timeout,
  }) {
    final eventId = _generateEventId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final event = GodotEvent(
      id: eventId,
      channel: channel,
      data: data,
      binaryData: binaryData,
      type: type,
      priority: priority,
      timestamp: timestamp,
      timeout: timeout ?? _defaultTimeout,
    );

    return _enqueueEvent(event) ? eventId : '';
  }

  Future<T?> addSyncEvent<T>({
    required String channel,
    Map<String, dynamic>? data,
    Uint8List? binaryData,
    EventPriority priority = EventPriority.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final eventId = _generateEventId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final responseCompleter = Completer<T?>();

    final event = GodotEvent(
      id: eventId,
      channel: channel,
      data: data,
      binaryData: binaryData,
      type: EventType.sync,
      priority: priority,
      timestamp: timestamp,
      responseCompleter: responseCompleter,
      timeout: timeout,
    );

    if (_enqueueEvent(event)) {
      _pendingEvents[eventId] = event;

      try {
        return await responseCompleter.future.timeout(timeout);
      } on TimeoutException {
        _pendingEvents.remove(eventId);
        _debugLog('Sync event $eventId timed out');
        return null;
      }
    }

    return null;
  }

  void handleResponse(String eventId, dynamic response) {
    final event = _pendingEvents.remove(eventId);
    if (event?.responseCompleter != null &&
        !event!.responseCompleter!.isCompleted) {
      event.responseCompleter!.complete(response);
    }
  }

  Stream<GodotEvent> getChannelStream(String channel) {
    if (!_channelStreams.containsKey(channel)) {
      _channelStreams[channel] = StreamController<GodotEvent>.broadcast();
    }
    return _channelStreams[channel]!.stream;
  }

  void broadcastEvent(GodotEvent event) {
    final controller = _channelStreams[event.channel];
    if (controller != null && !controller.isClosed) {
      controller.add(event);
    }

    // Update channel statistics
    _channelMessageCounts[event.channel] =
        (_channelMessageCounts[event.channel] ?? 0) + 1;
  }

  // Queue management
  bool _enqueueEvent(GodotEvent event) {
    final queue = _eventQueues[event.priority]!;

    // Check queue size limit
    if (queue.length >= _maxQueueSize) {
      _totalEventsDropped++;
      _debugLog('Event queue full, dropping event: ${event.id}');
      return false;
    }

    queue.add(event);
    _debugLog('Enqueued event: ${event.id} (${event.priority.name})');
    return true;
  }

  GodotEvent? _dequeueNextEvent() {
    // Process events by priority order
    for (final priority in EventPriority.values) {
      final queue = _eventQueues[priority]!;
      if (queue.isNotEmpty) {
        return queue.removeFirst();
      }
    }
    return null;
  }

  // Processing loop
  void _startProcessing() {
    _processingTimer = Timer.periodic(processingInterval, (_) {
      _processEvents();
    });
  }

  void _processEvents() {
    if (_isProcessing) return;

    _isProcessing = true;
    final startTime = DateTime.now().microsecondsSinceEpoch;

    try {
      int processedCount = 0;
      const maxBatchSize = 50; // Process max 50 events per batch

      while (processedCount < maxBatchSize) {
        final event = _dequeueNextEvent();
        if (event == null) break;

        if (event.isExpired) {
          _handleExpiredEvent(event);
          continue;
        }

        _processEvent(event);
        processedCount++;
        _totalEventsProcessed++;
      }

      final endTime = DateTime.now().microsecondsSinceEpoch;
      final processingTime = endTime - startTime;

      _processingTimes.add(processingTime);
      if (_processingTimes.length > 1000) {
        _processingTimes.removeAt(0);
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _processEvent(GodotEvent event) {
    try {
      switch (event.type) {
        case EventType.message:
        case EventType.binary:
          _processMessageEvent(event);
          break;
        case EventType.sync:
          _processSyncEvent(event);
          break;
        case EventType.broadcast:
          _processBroadcastEvent(event);
          break;
      }
    } catch (e) {
      _debugLog('Error processing event ${event.id}: $e');
      _retryEvent(event);
    }
  }

  void _processMessageEvent(GodotEvent event) {
    // This would be called by the actual message sender
    // For now, we'll simulate successful processing
    broadcastEvent(event);
    _debugLog('Processed message event: ${event.id}');
  }

  void _processSyncEvent(GodotEvent event) {
    // Add to pending events for response tracking
    if (!_pendingEvents.containsKey(event.id)) {
      _pendingEvents[event.id] = event;
    }

    // Process the sync event (would be handled by message sender)
    broadcastEvent(event);
    _debugLog('Processed sync event: ${event.id}');
  }

  void _processBroadcastEvent(GodotEvent event) {
    // Broadcast to all interested channels
    broadcastEvent(event);
    _debugLog('Processed broadcast event: ${event.id}');
  }

  void _handleExpiredEvent(GodotEvent event) {
    _totalEventsDropped++;

    if (event.responseCompleter != null &&
        !event.responseCompleter!.isCompleted) {
      event.responseCompleter!
          .completeError(TimeoutException('Event expired', event.timeout));
    }

    _pendingEvents.remove(event.id);
    _debugLog('Event expired: ${event.id}');
  }

  void _retryEvent(GodotEvent event) {
    // Simple retry logic - could be more sophisticated
    _totalEventsRetried++;

    // Re-enqueue with lower priority
    final retryPriority = event.priority == EventPriority.critical
        ? EventPriority.high
        : EventPriority.low;

    final retryEvent = GodotEvent(
      id: '${event.id}_retry',
      channel: event.channel,
      data: event.data,
      binaryData: event.binaryData,
      type: event.type,
      priority: retryPriority,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      responseCompleter: event.responseCompleter,
      timeout: event.timeout,
    );

    _enqueueEvent(retryEvent);
  }

  // Cleanup
  void _startCleanup() {
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _cleanup();
    });
  }

  void _cleanup() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredEvents = <String>[];

    // Find expired pending events
    for (final entry in _pendingEvents.entries) {
      if (entry.value.isExpired) {
        expiredEvents.add(entry.key);
      }
    }

    // Remove expired events
    for (final eventId in expiredEvents) {
      final event = _pendingEvents.remove(eventId);
      if (event?.responseCompleter != null &&
          !event!.responseCompleter!.isCompleted) {
        event.responseCompleter!.completeError(
            TimeoutException('Event cleanup timeout', event.timeout));
      }
    }

    _debugLog('Cleanup removed ${expiredEvents.length} expired events');
  }

  // Statistics and monitoring
  Map<String, dynamic> getStatistics() {
    final avgProcessingTime = _processingTimes.isEmpty
        ? 0.0
        : _processingTimes.reduce((a, b) => a + b) / _processingTimes.length;

    return {
      'total_events_processed': _totalEventsProcessed,
      'total_events_dropped': _totalEventsDropped,
      'total_events_retried': _totalEventsRetried,
      'pending_events': _pendingEvents.length,
      'average_processing_time_micros': avgProcessingTime,
      'queue_sizes':
          _eventQueues.map((key, value) => MapEntry(key.name, value.length)),
      'channel_message_counts': _channelMessageCounts,
      'active_channels': _channelStreams.length,
    };
  }

  void resetStatistics() {
    _totalEventsProcessed = 0;
    _totalEventsDropped = 0;
    _totalEventsRetried = 0;
    _processingTimes.clear();
    _channelMessageCounts.clear();
  }

  // Utility methods
  String _generateEventId() {
    return 'evt_${DateTime.now().microsecondsSinceEpoch}_${_totalEventsProcessed}';
  }

  void _debugLog(String message) {
    if (enableDebugLogging) {
      debugPrint('[EventManager] $message');
    }
  }

  // Disposal
  void dispose() {
    _processingTimer?.cancel();
    _cleanupTimer?.cancel();

    // Close all stream controllers
    for (final controller in _channelStreams.values) {
      controller.close();
    }
    _channelStreams.clear();

    // Complete any pending events with error
    for (final event in _pendingEvents.values) {
      if (event.responseCompleter != null &&
          !event.responseCompleter!.isCompleted) {
        event.responseCompleter!.completeError('EventManager disposed');
      }
    }
    _pendingEvents.clear();

    // Clear all queues
    for (final queue in _eventQueues.values) {
      queue.clear();
    }
  }
}

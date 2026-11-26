import 'dart:convert';
import 'dart:io';

import '../errors/netpulse_exception.dart';
import '../models/history_entry.dart';

/// Bounded storage for history entries, ordered oldest first.
///
/// Operations are serialised, so concurrent calls cannot interleave. When no
/// directory is supplied the history lives in memory only.
class HistoryStore {
  /// Creates a store, persisted in [directory] if given.
  HistoryStore({
    required this.maxEntries,
    required this.retention,
    String? directory,
    DateTime Function()? clock,
  }) : _file = directory == null
           ? null
           : File('$directory${Platform.pathSeparator}$fileName'),
       _clock = clock ?? DateTime.now;

  /// The name of the history file.
  static const String fileName = 'netpulse_history.json';

  /// The most entries retained.
  final int maxEntries;

  /// How long entries are retained.
  final Duration retention;

  final File? _file;
  final DateTime Function() _clock;
  List<HistoryEntry>? _entries;
  Future<void> _queue = Future<void>.value();

  /// Returns the retained entries, oldest first.
  Future<List<HistoryEntry>> read() =>
      _serialized(() async => List.of(_prune(await _load())));

  /// Appends [entry] and persists the result.
  Future<void> add(HistoryEntry entry) => _serialized(() async {
    final next = _prune([...await _load(), entry]);
    await _save(next);
    _entries = next;
  });

  /// Deletes all entries.
  Future<void> clear() => _serialized(() async {
    await _save(const []);
    _entries = [];
  });

  /// Completes when all queued operations have finished.
  Future<void> flush() => _queue;

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  List<HistoryEntry> _prune(List<HistoryEntry> entries) {
    final cutoff = _clock().subtract(retention);
    final kept = entries.where((e) => !e.timestamp.isBefore(cutoff)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (kept.length > maxEntries) {
      kept.removeRange(0, kept.length - maxEntries);
    }
    return kept;
  }

  Future<List<HistoryEntry>> _load() async {
    final cached = _entries;
    if (cached != null) return cached;
    final file = _file;
    if (file == null) return _entries = [];

    final entries = <HistoryEntry>[];
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          for (final item in decoded) {
            try {
              entries.add(
                HistoryEntry.fromMap((item as Map).cast<Object?, Object?>()),
              );
            } on FormatException {
              // Skip a damaged entry and keep the rest.
            } on TypeError {
              // Skip an entry with fields of the wrong type.
            }
          }
        }
      }
    } on FormatException {
      // The file is not valid JSON or UTF-8. Start over; the next write
      // replaces it.
    } on FileSystemException catch (error) {
      throw _failure('Could not read history.', error);
    }
    return _entries = entries;
  }

  Future<void> _save(List<HistoryEntry> entries) async {
    final file = _file;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      // Write then rename, so an interrupted write cannot corrupt history.
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode([for (final e in entries) e.toMap()]),
        flush: true,
      );
      await temporary.rename(file.path);
    } on FileSystemException catch (error) {
      throw _failure('Could not write history.', error);
    }
  }

  NetPulseException _failure(String message, Object cause) => NetPulseException(
    NetPulseErrorCode.storageFailure,
    message,
    cause: cause,
  );
}

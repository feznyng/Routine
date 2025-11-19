import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DesktopLogger extends LogPrinter {
  final SimplePrinter _delegate;
  final int _flushThreshold;

  IOSink? _sink;
  final List<String> _buffer = [];
  Future<void>? _initFuture;

  DesktopLogger({
    bool printTime = false,
    bool colors = true,
    int flushThreshold = 10,
  })  : _delegate = SimplePrinter(
          printTime: printTime,
          colors: colors,
        ),
        _flushThreshold = flushThreshold;

  @override
  Future<void> init() async {
    _initFuture ??= _initInternal();
    await _initFuture;
  }

  Future<void> _initInternal() async {
    try {
      final file = await _resolveLogFile();
      print("DesktopLogger: file = $file");
      await file.parent.create(recursive: true);
      _sink = file.openWrite(mode: FileMode.append);
    } catch (_) {
      // If we fail to initialize file logging, we still want console logging to work.
      _sink = null;
    }
  }

  Future<File> _resolveLogFile() async {
    if (Platform.isWindows) {
      // Same directory as the executable.
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent;
      return File(p.join(exeDir.path, 'routine.log'));
    }

    if (Platform.isMacOS) {
      // User Documents directory on macOS: ~/Documents.
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final docsPath = p.join(home, 'Documents');
        return File(p.join(docsPath, 'routine.log'));
      }
    }

    // Fallback for other platforms: use application documents directory if available.
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, 'routine.log'));
  }

  @override
  List<String> log(LogEvent event) {
    final lines = _delegate.log(event);

    // For file output we only want timestamp, level and message.
    final fileLine = _formatFileLine(event);

    if (fileLine.isNotEmpty) {
      _buffer.add(fileLine);

      if (_buffer.length >= _flushThreshold) {
        // Fire-and-forget to avoid blocking the logger call.
        _flushBufferedLines();
      } else {
        // Ensure initialization has been started at least once.
        _ensureInitialized();
      }
    }

    return lines;
  }

  String _formatFileLine(LogEvent event) {
    final timestamp = DateTime.now().toIso8601String();
    final level = _levelToString(event.level);
    final message = event.message?.toString() ?? '';
    return '[$timestamp] [$level] $message';
  }

  String _levelToString(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRACE';
      case Level.debug:
        return 'DEBUG';
      case Level.verbose:
        return 'VERBOSE';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARN';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      case Level.all:
        return 'ALL';
      case Level.wtf:
        return 'WTF';
      case Level.nothing:
        return 'NOTHING';
      case Level.off:
        return 'OFF';
    }
  }

  void _ensureInitialized() {
    _initFuture ??= _initInternal();
  }

  Future<void> _flushBufferedLines() async {
    await init();

    final sink = _sink;
    if (sink == null || _buffer.isEmpty) {
      return;
    }

    // Copy and clear buffer quickly to minimize time holding data.
    final linesToWrite = List<String>.from(_buffer);
    _buffer.clear();

    try {
      sink.writeln(linesToWrite.join('\n'));
      await sink.flush();
    } catch (_) {
      // Ignore write errors; console logging has already occurred.
    }
  }

  @override
  Future<void> destroy() async {
    try {
      await _flushBufferedLines();
    } finally {
      final sink = _sink;
      _sink = null;
      await sink?.close();
    }
  }
}
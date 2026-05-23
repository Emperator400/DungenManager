import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/companion_map_state.dart';
import '../models/ort.dart';
import '../services/lan_map_server.dart';

class LanMapViewModel extends ChangeNotifier {
  LanMapViewModel();

  final LanMapServer _server = LanMapServer();
  static const _uuid = Uuid();

  // ── Public state ──────────────────────────────────────────────────────────
  bool   isRunning   = false;
  String serverUrl   = '';
  String localIp     = '';
  int    clientCount = 0;

  String? imagePath;
  Size?   imageNaturalSize; // loaded async after setImage()
  bool    fogEnabled = true;

  final Set<int>       revealedCells = {};
  final List<MapToken> tokens        = [];

  // Paint mode: 'reveal' | 'cover' | 'token' | 'viewport'
  String paintMode  = 'reveal';
  String tokenLabel = '';
  String tokenColor = '#e74c3c';

  // Manual viewport override (null = follow InteractiveViewer)
  Offset? viewportNorm;
  double  broadcastScale = 2.0;

  void setPaintMode(String mode) { paintMode = mode; notifyListeners(); }
  void setTokenColor(String color) { tokenColor = color; notifyListeners(); }

  void moveViewportTo(Offset norm) {
    viewportNorm = norm;
    if (imageNaturalSize == null) return;
    final iw = imageNaturalSize!.width;
    final ih = imageNaturalSize!.height;
    _server.setViewport(
      -(norm.dx - 0.5) * iw,
      -(norm.dy - 0.5) * ih,
      broadcastScale,
    );
    notifyListeners();
  }

  void clearViewport() {
    viewportNorm = null;
    _server.clearViewport();
    notifyListeners();
  }

  void setBroadcastScale(double scale) {
    broadcastScale = scale.clamp(0.5, 10.0);
    if (viewportNorm != null) moveViewportTo(viewportNorm!);
    notifyListeners();
  }

  // ── Server control ────────────────────────────────────────────────────────

  // Actual player browser canvas dimensions (updated via WebSocket message)
  Size get playerCanvasSize => Size(_server.playerCanvasW, _server.playerCanvasH);

  // URL für Geräte im selben WLAN
  String get lanUrl       => isRunning ? 'http://$localIp:${LanMapServer.port}' : '';
  // URL für Browser auf demselben Rechner (Emulator, Localhost-Test)
  String get localhostUrl => isRunning ? 'http://localhost:${LanMapServer.port}' : '';
  // URL für Android-Emulator (10.0.2.2 = Windows-Host aus AVD)
  String get emulatorUrl  => isRunning ? 'http://10.0.2.2:${LanMapServer.port}' : '';

  Future<void> startServer() async {
    if (isRunning) return;
    localIp   = await LanMapServer.getLocalIp();
    await _server.start();
    isRunning = true;
    serverUrl = lanUrl;
    notifyListeners();
    _pollClientCount();
    _loadIdleImage();   // fire-and-forget
  }

  // Loads the idle image: custom file in AppSupport overrides the bundled asset.
  Future<void> _loadIdleImage() async {
    try {
      final customPath = await _customIdlePath();
      final customFile = File(customPath);
      if (await customFile.exists()) {
        final bytes = await customFile.readAsBytes();
        final ext   = p.extension(customPath).toLowerCase().replaceFirst('.', '');
        final mime  = switch (ext) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'webp'          => 'image/webp',
          'gif'           => 'image/gif',
          _               => 'image/png',
        };
        _server.setIdleImage(bytes, mime);
        return;
      }
    } catch (e) {
      debugPrint('[LanMapViewModel] Custom idle load failed: $e');
    }
    // Fall back to the bundled asset
    try {
      final data = await rootBundle.load('assets/lan/idle_screen.png');
      _server.setIdleImage(data.buffer.asUint8List(), 'image/png');
    } catch (e) {
      debugPrint('[LanMapViewModel] Asset idle load failed: $e');
    }
  }

  // Returns (and creates) the well-known custom idle image path.
  Future<String> customIdlePath() => _customIdlePath();

  Future<String> _customIdlePath() async {
    final support = await getApplicationSupportDirectory();
    final dir     = Directory(p.join(support.path, 'lan'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return p.join(dir.path, 'idle_screen.png');
  }

  Future<void> stopServer() async {
    _stopPolling();
    await _server.stop();
    isRunning   = false;
    clientCount = 0;
    notifyListeners();
  }

  // ── Map image ─────────────────────────────────────────────────────────────

  void setImage(String path) {
    imagePath = path;
    imageNaturalSize = null;
    _server.setImage(path);
    notifyListeners();
    _loadImageSize(path);
  }

  Future<void> _loadImageSize(String path) async {
    try {
      final completer = Completer<ImageInfo>();
      final stream = FileImage(File(path)).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete(info);
        },
        onError: (Object e, _) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.completeError(e);
        },
      );
      stream.addListener(listener);
      final info = await completer.future;
      imageNaturalSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
      notifyListeners();
    } catch (e) {
      debugPrint('[LanMapViewModel] Image size load failed: $e');
    }
  }

  // ── Viewport (called from InteractiveViewer transform callback) ───────────

  void syncViewport(Matrix4 matrix) {
    if (viewportNorm != null) return; // manual viewport active
    final scale = matrix.getMaxScaleOnAxis();
    final tx    = matrix.getTranslation();
    _server.setViewport(tx.x, tx.y, scale);
  }

  // ── Fog of war ────────────────────────────────────────────────────────────

  void toggleFog() {
    fogEnabled = !fogEnabled;
    _server.setFogEnabled(fogEnabled);
    notifyListeners();
  }

  void paintCell(int cellIndex) {
    if (paintMode == 'reveal') {
      if (revealedCells.add(cellIndex)) {
        _server.revealCells([cellIndex]);
        notifyListeners();
      }
    } else if (paintMode == 'cover') {
      if (revealedCells.remove(cellIndex)) {
        _server.coverCells([cellIndex]);
        notifyListeners();
      }
    }
  }

  void revealAll() {
    final all = List.generate(400, (i) => i); // 20×20
    revealedCells.addAll(all);
    _server.revealCells(all);
    notifyListeners();
  }

  void coverAll() {
    revealedCells.clear();
    _server.coverCells(List.generate(400, (i) => i));
    notifyListeners();
  }

  // ── Tokens ────────────────────────────────────────────────────────────────

  void placeToken(int col, int row) {
    final token = MapToken(
      id:    _uuid.v4(),
      x:     col,
      y:     row,
      label: tokenLabel,
      color: tokenColor,
    );
    tokens.add(token);
    _server.upsertToken(token);
    notifyListeners();
  }

  void removeToken(String id) {
    tokens.removeWhere((t) => t.id == id);
    _server.removeToken(id);
    notifyListeners();
  }

  // Per-ort token sizes (session-scoped, keyed by ort ID)
  final Map<String, double> _tokenOrtSizes = {};

  double tokenOrtSize(String ortId) => _tokenOrtSizes[ortId] ?? 1.0;

  void setTokenOrtSize(String ortId, double size) {
    _tokenOrtSizes[ortId] = size.clamp(0.5, 4.0);
    final idx = tokens.indexWhere((t) => t.id == 'ort_$ortId');
    if (idx != -1) {
      final updated = tokens[idx].copyWith(size: _tokenOrtSizes[ortId]!);
      tokens[idx] = updated;
      _server.upsertToken(updated);
      notifyListeners();
    }
  }

  // Syncs OrtType.token markers as MapTokens (id prefix "ort_").
  // Replaces all previously synced ort-tokens with the current set.
  void syncOrtTokens(List<Ort> tokenOrte) {
    final stale = tokens.where((t) => t.id.startsWith('ort_')).toList();
    for (final t in stale) {
      tokens.remove(t);
      _server.removeToken(t.id);
    }
    final imgPaths = <String, String>{};
    for (final ort in tokenOrte) {
      if (ort.mapX == null || ort.mapY == null) continue;
      final col = (ort.mapX! * 20).floor().clamp(0, 19);
      final row = (ort.mapY! * 20).floor().clamp(0, 19);
      if (ort.tokenImagePath != null) imgPaths[ort.id] = ort.tokenImagePath!;
      final token = MapToken(
        id:       'ort_${ort.id}',
        x:        col,
        y:        row,
        label:    ort.name,
        color:    '#9b59b6',
        size:     _tokenOrtSizes[ort.id] ?? 1.0,
        imageUrl: ort.tokenImagePath != null ? '/img/${ort.id}' : null,
      );
      tokens.add(token);
      _server.upsertToken(token);
    }
    _server.setTokenImages(imgPaths);
    notifyListeners();
  }

  // ── Client count polling ──────────────────────────────────────────────────

  bool _polling = false;

  void _pollClientCount() {
    _polling = true;
    Future.doWhile(() async {
      if (!_polling) return false;
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!_polling) return false;
      final count = _server.clientCount;
      if (count != clientCount) {
        clientCount = count;
        notifyListeners();
      }
      return _polling;
    });
  }

  void _stopPolling() => _polling = false;

  @override
  void dispose() {
    _stopPolling();
    _server.stop();
    super.dispose();
  }
}

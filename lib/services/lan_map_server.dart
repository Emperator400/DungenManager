import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/companion_map_state.dart';

// ── Protocol message types (server → browser) ────────────────────────────────
const String _msgFullState      = 'full_state';
const String _msgViewport       = 'viewport';
const String _msgFog            = 'fog';
const String _msgToken          = 'token';
const String _msgTokenRemove    = 'token_remove';
const String _msgImage          = 'image';
const String _msgRoomEnded      = 'room_ended';
const String _msgViewportActive = 'viewport_active';

class LanMapServer {
  static const int _port = 7771;

  HttpServer? _httpServer;
  final List<WebSocket> _clients = [];

  // ── In-memory state ───────────────────────────────────────────────────────
  String? _imagePath;
  final Set<int> _revealedCells = {};
  final List<MapToken> _tokens  = [];
  bool _fogEnabled              = true;

  // Viewport: x, y offsets (fractional 0-1 of image size) + scale
  double _vpX = 0, _vpY = 0, _vpScale = 1.0;

  // Last known player browser canvas size (sent by client on connect + resize)
  double playerCanvasW = 1280;
  double playerCanvasH = 720;

  // Whether a viewport position is currently set (controls what browser shows)
  bool _viewportActive = false;

  // Idle screen image (loaded from asset or custom file by ViewModel)
  Uint8List? _idleImageBytes;
  String     _idleImageMime = 'image/png';

  // Token images: ort_id → absolute file path on DM machine
  final Map<String, String> _tokenImgPaths = {};

  bool get isRunning   => _httpServer != null;
  static int get port  => _port;
  int  get clientCount => _clients.length;

  // ── Start / Stop ──────────────────────────────────────────────────────────

  Future<String> start() async {
    if (_httpServer != null) return _serverUrl();

    try {
      // shared: true allows a new server to bind while a previous instance is
      // still draining — prevents SocketException when navigating away and back.
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, _port, shared: true);
    } catch (e) {
      debugPrint('[LanMapServer] Bind failed: $e');
      return '';
    }
    debugPrint('[LanMapServer] Listening on port $_port');
    _httpServer!.listen(_handleRequest, onError: (Object e) {
      debugPrint('[LanMapServer] HTTP error: $e');
    });
    return _serverUrl();
  }

  Future<void> stop() async {
    for (final ws in List<WebSocket>.from(_clients)) {
      _send(ws, {'type': _msgRoomEnded});
      await ws.close();
    }
    _clients.clear();
    await _httpServer?.close(force: true);
    _httpServer = null;
    debugPrint('[LanMapServer] Stopped');
  }

  // ── Request routing ───────────────────────────────────────────────────────

  Future<void> _handleRequest(HttpRequest req) async {
    final path = req.uri.path;

    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final ws = await WebSocketTransformer.upgrade(req);
      _onClientConnected(ws);
      return;
    }

    switch (path) {
      case '/':
      case '/index.html':
        _serveHtml(req.response);
      case '/map':
        await _serveImage(req.response);
      case '/idle':
        await _serveIdleImage(req.response);
      default:
        if (path.startsWith('/img/')) {
          await _serveTokenImage(req.response, path.substring(5));
          return;
        }
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found')
          ..close();
    }
  }

  // ── WebSocket lifecycle ───────────────────────────────────────────────────

  void _onClientConnected(WebSocket ws) {
    _clients.add(ws);
    debugPrint('[LanMapServer] Client connected (${_clients.length} total)');

    // Send full state immediately
    _send(ws, _buildFullState());

    ws.listen(
      (data) {
        try {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          if (msg['type'] == 'canvas_size') {
            playerCanvasW = (msg['w'] as num).toDouble();
            playerCanvasH = (msg['h'] as num).toDouble();
          }
        } catch (_) {}
      },
      onDone: () {
        _clients.remove(ws);
        debugPrint('[LanMapServer] Client disconnected (${_clients.length} total)');
      },
      onError: (Object e) {
        _clients.remove(ws);
        debugPrint('[LanMapServer] Client error: $e');
      },
    );
  }

  void _send(WebSocket ws, Map<String, dynamic> msg) {
    try {
      ws.add(jsonEncode(msg));
    } catch (e) {
      debugPrint('[LanMapServer] Send error: $e');
    }
  }

  void _broadcast(Map<String, dynamic> msg) {
    final json = jsonEncode(msg);
    for (final ws in List<WebSocket>.from(_clients)) {
      try {
        ws.add(json);
      } catch (e) {
        _clients.remove(ws);
      }
    }
  }

  // ── State update methods (called by ViewModel) ────────────────────────────

  void setImage(String path) {
    _imagePath = path;
    _broadcast({'type': _msgImage, 'hasImage': true});
  }

  void setViewport(double x, double y, double scale) {
    _vpX = x; _vpY = y; _vpScale = scale;
    if (!_viewportActive) {
      _viewportActive = true;
      _broadcast({'type': _msgViewportActive, 'active': true});
    }
    _broadcast({'type': _msgViewport, 'x': x, 'y': y, 'scale': scale});
  }

  void clearViewport() {
    _viewportActive = false;
    _broadcast({'type': _msgViewportActive, 'active': false});
  }

  void setIdleImage(Uint8List bytes, String mime) {
    _idleImageBytes = bytes;
    _idleImageMime  = mime;
  }

  void setTokenImages(Map<String, String> paths) {
    _tokenImgPaths
      ..clear()
      ..addAll(paths);
  }

  void revealCells(List<int> indices) {
    _revealedCells.addAll(indices);
    _broadcast({
      'type': _msgFog,
      'revealed': _revealedCells.toList(),
      'fogEnabled': _fogEnabled,
    });
  }

  void coverCells(List<int> indices) {
    _revealedCells.removeAll(indices);
    _broadcast({
      'type': _msgFog,
      'revealed': _revealedCells.toList(),
      'fogEnabled': _fogEnabled,
    });
  }

  void setFogEnabled(bool enabled) {
    _fogEnabled = enabled;
    _broadcast({
      'type': _msgFog,
      'revealed': _revealedCells.toList(),
      'fogEnabled': _fogEnabled,
    });
  }

  void upsertToken(MapToken token) {
    _tokens.removeWhere((t) => t.id == token.id);
    _tokens.add(token);
    _broadcast({
      'type': _msgToken,
      'token': token.toMap(),
    });
  }

  void removeToken(String tokenId) {
    _tokens.removeWhere((t) => t.id == tokenId);
    _broadcast({'type': _msgTokenRemove, 'id': tokenId});
  }

  // ── Full state snapshot ───────────────────────────────────────────────────

  Map<String, dynamic> _buildFullState() => {
    'type': _msgFullState,
    'hasImage': _imagePath != null,
    'viewportActive': _viewportActive,
    'viewport': {'x': _vpX, 'y': _vpY, 'scale': _vpScale},
    'fog': {
      'revealed': _revealedCells.toList(),
      'fogEnabled': _fogEnabled,
    },
    'tokens': _tokens.map((t) => t.toMap()).toList(),
  };

  // ── HTTP response helpers ─────────────────────────────────────────────────

  void _serveHtml(HttpResponse res) {
    res.headers
      ..contentType = ContentType.html
      ..set('Cache-Control', 'no-cache');
    res.write(_htmlViewer);
    res.close();
  }

  Future<void> _serveImage(HttpResponse res) async {
    if (_imagePath == null) {
      res.statusCode = HttpStatus.noContent;
      res.close();
      return;
    }
    try {
      final file = File(_imagePath!);
      if (!await file.exists()) {
        res.statusCode = HttpStatus.notFound;
        res.close();
        return;
      }
      final bytes = await file.readAsBytes();
      final ext   = _imagePath!.split('.').last.toLowerCase();
      final mime  = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png'            => 'image/png',
        'gif'            => 'image/gif',
        'webp'           => 'image/webp',
        _                => 'application/octet-stream',
      };
      res.headers
        ..contentType = ContentType.parse(mime)
        ..set('Cache-Control', 'no-cache');
      res.add(bytes);
      res.close();
    } catch (e) {
      debugPrint('[LanMapServer] Image serve error: $e');
      res.statusCode = HttpStatus.internalServerError;
      res.close();
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
            return ip;
          }
        }
      }
    } catch (e) {
      debugPrint('[LanMapServer] IP lookup error: $e');
    }
    return '127.0.0.1';
  }

  Future<void> _serveIdleImage(HttpResponse res) async {
    final bytes = _idleImageBytes;
    if (bytes == null) {
      res.statusCode = HttpStatus.noContent;
      res.close();
      return;
    }
    res.headers
      ..contentType = ContentType.parse(_idleImageMime)
      ..set('Cache-Control', 'no-cache');
    res.add(bytes);
    res.close();
  }

  Future<void> _serveTokenImage(HttpResponse res, String ortId) async {
    final path = _tokenImgPaths[ortId];
    if (path == null) {
      res.statusCode = HttpStatus.noContent;
      res.close();
      return;
    }
    try {
      final file  = File(path);
      final bytes = await file.readAsBytes();
      final ext   = path.split('.').last.toLowerCase();
      final mime  = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'webp'          => 'image/webp',
        'gif'           => 'image/gif',
        'png'           => 'image/png',
        _               => 'application/octet-stream',
      };
      res.headers
        ..contentType = ContentType.parse(mime)
        ..set('Cache-Control', 'no-cache');
      res.add(bytes);
    } catch (e) {
      res.statusCode = HttpStatus.notFound;
    }
    res.close();
  }

  String _serverUrl() => 'http://PLACEHOLDER:$_port';
}

// ── Embedded HTML viewer ──────────────────────────────────────────────────────

const String _htmlViewer = r'''<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<title>DungenManager – Karte</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #0d0d1a;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 100vw;
    height: 100vh;
    overflow: hidden;
    font-family: sans-serif;
    color: #ccc;
  }
  #status {
    position: fixed;
    top: 8px; left: 50%;
    transform: translateX(-50%);
    background: rgba(0,0,0,0.6);
    border-radius: 12px;
    padding: 4px 14px;
    font-size: 12px;
    z-index: 10;
    transition: opacity .5s;
  }
  #status.hidden { opacity: 0; }
  canvas {
    display: block;
    image-rendering: pixelated;
  }
  #placeholder {
    color: #555;
    text-align: center;
    font-size: 18px;
    user-select: none;
  }
  #placeholder span { font-size: 64px; display: block; margin-bottom: 16px; }
  #idle-bg {
    position: fixed;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #0d0d1a;
    z-index: 5;
  }
  #idle-img {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: none;
  }
  #idle-txt { color: #2a2a3a; font-size: 22px; z-index: 1; user-select: none; }
</style>
</head>
<body>

<div id="status">Verbinde…</div>
<div id="idle-bg">
  <img id="idle-img" src="" alt="">
  <p id="idle-txt">Warte auf DM…</p>
</div>
<canvas id="c"></canvas>
<div id="placeholder" style="display:none"><span>🗺️</span>Warte auf Karte…</div>

<script>
const canvas = document.getElementById('c');
const ctx         = canvas.getContext('2d');
const status      = document.getElementById('status');
const placeholder = document.getElementById('placeholder');
const idleBg      = document.getElementById('idle-bg');
const idleImg     = document.getElementById('idle-img');
const idleTxt     = document.getElementById('idle-txt');

let mapImg        = null;
let vpX = 0, vpY = 0, vpScale = 1;
let revealedSet   = new Set();
let fogEnabled    = true;
let tokens        = [];
let viewportActive = false;
const GRID_COLS   = 20;
const GRID_ROWS   = 20;
let ws, reconnectTimer;
const imgCache    = {}; // key: imageUrl → HTMLImageElement | 'loading'

idleImg.onload  = () => { idleImg.style.display = 'block'; idleTxt.style.display = 'none';  };
idleImg.onerror = () => { idleImg.style.display = 'none';  idleTxt.style.display = 'block'; };

function loadIdleImage() {
  idleImg.src = `/idle?t=${Date.now()}`;
}

function applyIdleState() {
  idleBg.style.display = viewportActive ? 'none' : 'flex';
}

function showStatus(msg, hide=true) {
  status.textContent = msg;
  status.classList.remove('hidden');
  if (hide) setTimeout(() => status.classList.add('hidden'), 2500);
}

// ── Resize ─────────────────────────────────────────────────────────────────

function resize() {
  canvas.width  = window.innerWidth;
  canvas.height = window.innerHeight;
  draw();
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({type: 'canvas_size', w: canvas.width, h: canvas.height}));
  }
}
window.addEventListener('resize', resize);
resize();

// ── Draw ───────────────────────────────────────────────────────────────────

function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  if (!mapImg) {
    canvas.style.display = 'none';
    placeholder.style.display = 'block';
    return;
  }
  canvas.style.display = 'block';
  placeholder.style.display = 'none';

  ctx.save();
  // Centre of canvas
  const cx = canvas.width  / 2;
  const cy = canvas.height / 2;

  ctx.translate(cx + vpX * vpScale, cy + vpY * vpScale);
  ctx.scale(vpScale, vpScale);

  const iw = mapImg.naturalWidth;
  const ih = mapImg.naturalHeight;
  ctx.drawImage(mapImg, -iw/2, -ih/2, iw, ih);

  // Fog overlay
  if (fogEnabled) drawFog(iw, ih);

  // Tokens
  drawTokens(iw, ih);

  ctx.restore();
}

function drawFog(iw, ih) {
  const cw = iw / GRID_COLS;
  const ch = ih / GRID_ROWS;
  ctx.fillStyle = 'rgba(0,0,0,0.85)';
  for (let r = 0; r < GRID_ROWS; r++) {
    for (let c = 0; c < GRID_COLS; c++) {
      const idx = r * GRID_COLS + c;
      if (!revealedSet.has(idx)) {
        ctx.fillRect(-iw/2 + c*cw, -ih/2 + r*ch, cw, ch);
      }
    }
  }
}

function drawTokens(iw, ih) {
  const cw = iw / GRID_COLS;
  const ch = ih / GRID_ROWS;
  for (const t of tokens) {
    const px = -iw/2 + (t.x + 0.5) * cw;
    const py = -ih/2 + (t.y + 0.5) * ch;
    const r  = Math.min(cw, ch) * 0.4 * (t.size || 1.0);

    if (t.imageUrl) {
      const cached = imgCache[t.imageUrl];
      if (cached && cached !== 'loading') {
        ctx.save();
        ctx.beginPath();
        ctx.arc(px, py, r, 0, Math.PI * 2);
        ctx.clip();
        ctx.drawImage(cached, px - r, py - r, r * 2, r * 2);
        ctx.restore();
        ctx.beginPath();
        ctx.arc(px, py, r, 0, Math.PI * 2);
        ctx.strokeStyle = '#fff';
        ctx.lineWidth   = 2 / vpScale;
        ctx.stroke();
        continue;
      }
      if (!cached) {
        imgCache[t.imageUrl] = 'loading';
        const img = new Image();
        img.onload  = () => { imgCache[t.imageUrl] = img; draw(); };
        img.onerror = () => { delete imgCache[t.imageUrl]; };
        img.src = t.imageUrl;
      }
      // fall through — draw placeholder while loading
    }

    ctx.beginPath();
    ctx.arc(px, py, r, 0, Math.PI*2);
    ctx.fillStyle   = t.color || '#e74c3c';
    ctx.strokeStyle = '#fff';
    ctx.lineWidth   = 2 / vpScale;
    ctx.fill();
    ctx.stroke();
    if (t.label) {
      ctx.fillStyle = '#fff';
      ctx.font      = `bold ${Math.max(10, r * 0.8)}px sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(t.label.substring(0, 2).toUpperCase(), px, py);
    }
  }
}

// ── WebSocket ──────────────────────────────────────────────────────────────

function connect() {
  const url = `ws://${location.host}/ws`;
  ws = new WebSocket(url);

  ws.onopen = () => {
    showStatus('Verbunden ✓');
    clearTimeout(reconnectTimer);
    ws.send(JSON.stringify({type: 'canvas_size', w: canvas.width, h: canvas.height}));
  };

  ws.onmessage = e => {
    const msg = JSON.parse(e.data);
    handleMessage(msg);
  };

  ws.onerror = () => {};
  ws.onclose = () => {
    showStatus('Verbindung getrennt – verbinde neu…', false);
    reconnectTimer = setTimeout(connect, 3000);
  };
}

function handleMessage(msg) {
  switch (msg.type) {
    case 'full_state':
      fogEnabled     = msg.fog?.fogEnabled ?? true;
      revealedSet    = new Set(msg.fog?.revealed ?? []);
      tokens         = msg.tokens ?? [];
      viewportActive = msg.viewportActive ?? false;
      applyViewport(msg.viewport);
      if (msg.hasImage) loadImage();
      loadIdleImage();
      applyIdleState();
      draw();
      break;

    case 'viewport_active':
      viewportActive = msg.active ?? false;
      applyIdleState();
      break;

    case 'viewport':
      applyViewport(msg);
      draw();
      break;

    case 'fog':
      fogEnabled  = msg.fogEnabled ?? true;
      revealedSet = new Set(msg.revealed ?? []);
      draw();
      break;

    case 'token':
      if (msg.token) {
        tokens = tokens.filter(t => t.id !== msg.token.id);
        tokens.push(msg.token);
        draw();
      }
      break;

    case 'token_remove':
      tokens = tokens.filter(t => t.id !== msg.id);
      draw();
      break;

    case 'image':
      if (msg.hasImage) loadImage();
      break;

    case 'room_ended':
      showStatus('Session beendet', false);
      break;
  }
}

function applyViewport(vp) {
  if (!vp) return;
  vpX     = vp.x     ?? 0;
  vpY     = vp.y     ?? 0;
  vpScale = vp.scale ?? 1;
}

function loadImage() {
  const img = new Image();
  img.onload = () => { mapImg = img; draw(); };
  img.onerror = () => showStatus('Karte konnte nicht geladen werden');
  img.src = `/map?t=${Date.now()}`;
}

connect();
</script>
</body>
</html>''';

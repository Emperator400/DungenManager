import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/resource_service.dart';

/// Zeigt ein Bild aus einem beliebigen Referenz-Format an.
///
/// Unterstützte Formate:
/// - `resource://filename.jpg` → lokal aus `resources/`-Ordner
/// - Absoluter Pfad (`/…` oder `C:\…`) → lokal via `Image.file`
/// - `http://` / `https://` → `Image.network`
/// - null / leer → [fallback] Widget
Widget buildResourceImage({
  required String? ref,
  required Widget fallback,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (ref == null || ref.isEmpty) return fallback;

  // HTTP(S)-URL → direkt netzwerkladen
  if (ref.startsWith('http://') || ref.startsWith('https://')) {
    return Image.network(
      ref,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
    );
  }

  // resource://… oder absoluter Pfad → lokal
  final localPath = ResourceService.resolveLocalPath(ref);
  if (localPath == null) return fallback;
  final file = File(localPath);
  if (!file.existsSync()) return fallback;

  return Image.file(
    file,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback,
  );
}

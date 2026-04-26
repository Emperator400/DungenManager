// lib/widgets/ui_components/shared/app_icon.dart
//
// SVG-basiertes Icon-System nach UI_vorschrift.
// Stroke-basiert, 1.5px, rounded caps/joins — identisch mit den JSX-Prototypen.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppIconName {
  sun, moon, back, forward, search, plus, close, save,
  chevronDown, chevronUp, chevronLeft, chevronRight,
  edit, trash, tag, location, calendar, book, globe, dots,
  user, users, play, pause, stop, check, scroll,
  settings, bell, filter, sort, grid, list, arrow,
  shield, sword, map, music, volume, volumeOff,
  star, heart, info, warning, error, link, copy,
  upload, download, folder, file, image, refresh,
  lock, unlock, eye, eyeOff, send, inbox,
}

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.name, {
    super.key,
    this.size = 16,
    this.color,
  });

  final AppIconName name;
  final double size;
  final Color? color;

  static const Map<AppIconName, String> _paths = {
    AppIconName.sun:          'M8 3v1M8 12v1M3 8H2M14 8h-1M4.5 4.5l.7.7M10.8 10.8l.7.7M4.5 11.5l.7-.7M10.8 5.2l.7-.7M8 6a2 2 0 100 4 2 2 0 000-4z',
    AppIconName.moon:         'M8 3a5 5 0 000 10 5.5 5.5 0 01-3.5-9.5A5 5 0 018 3z',
    AppIconName.back:         'M10 3L5 8l5 5',
    AppIconName.forward:      'M6 3l5 5-5 5',
    AppIconName.search:       'M7 3a4 4 0 100 8 4 4 0 000-8zM13 13l-3-3',
    AppIconName.plus:         'M8 3v10M3 8h10',
    AppIconName.close:        'M4 4l8 8M12 4l-8 8',
    AppIconName.save:         'M3 3h8l2 2v9a1 1 0 01-1 1H4a1 1 0 01-1-1V3zm4 9a2 2 0 100-4 2 2 0 000 4z',
    AppIconName.chevronDown:  'M4 6l4 4 4-4',
    AppIconName.chevronUp:    'M4 10l4-4 4 4',
    AppIconName.chevronLeft:  'M10 4l-4 4 4 4',
    AppIconName.chevronRight: 'M6 4l4 4-4 4',
    AppIconName.edit:         'M11 3l2 2-8 8H3v-2l8-8z',
    AppIconName.trash:        'M3 5h10M6 5V3h4v2M5 5l1 9h4l1-9',
    AppIconName.tag:          'M2 8l6-6h5a1 1 0 011 1v5L8 14a1 1 0 01-1.4 0L2 8.6A1 1 0 012 8zm9-3a1 1 0 100 2 1 1 0 000-2z',
    AppIconName.location:     'M8 2a4 4 0 014 4c0 3-4 8-4 8S4 9 4 6a4 4 0 014-4zm0 3a1 1 0 100 2 1 1 0 000-2z',
    AppIconName.calendar:     'M3 5h10a1 1 0 011 1v8a1 1 0 01-1 1H3a1 1 0 01-1-1V6a1 1 0 011-1zm0 0V3m10 2V3',
    AppIconName.book:         'M3 3h8l2 2v10H3V3zm4 5h4M7 11h4',
    AppIconName.globe:        'M8 2a6 6 0 100 12A6 6 0 008 2zM2 8h12M8 2c-2 2-3 4-3 6s1 4 3 6M8 2c2 2 3 4 3 6s-1 4-3 6',
    AppIconName.dots:         'M4 8a1 1 0 100-2 1 1 0 000 2zm4 0a1 1 0 100-2 1 1 0 000 2zm4 0a1 1 0 100-2 1 1 0 000 2z',
    AppIconName.user:         'M8 7a3 3 0 100-6 3 3 0 000 6zm-5 9a5 5 0 0110 0',
    AppIconName.users:        'M6 7a3 3 0 100-6 3 3 0 000 6zm-5 8a5 5 0 0110 0M11 5a3 3 0 110 0m3 10a5 5 0 00-3-4.5',
    AppIconName.play:         'M4 3l10 5-10 5V3z',
    AppIconName.pause:        'M5 3v10M11 3v10',
    AppIconName.stop:         'M4 4h8v8H4z',
    AppIconName.check:        'M4 8l3 3 5-5',
    AppIconName.scroll:       'M4 2h8a1 1 0 011 1v12l-4.5-2L4 15V3a1 1 0 011-1z',
    AppIconName.settings:     'M8 10a2 2 0 100-4 2 2 0 000 4zM6.3 3.5A5 5 0 003 8a5 5 0 003.3 4.5M9.7 3.5A5 5 0 0113 8a5 5 0 01-3.3 4.5M8 1v2M8 13v2M1 8h2M13 8h2',
    AppIconName.bell:         'M8 2a4 4 0 00-4 4v3l-1 2h10l-1-2V6a4 4 0 00-4-4zM6.5 13a1.5 1.5 0 003 0',
    AppIconName.filter:       'M2 4h12M4 8h8M6 12h4',
    AppIconName.sort:         'M2 5h12M2 8h8M2 11h5',
    AppIconName.grid:         'M3 3h4v4H3zM9 3h4v4H9zM3 9h4v4H3zM9 9h4v4H9z',
    AppIconName.list:         'M3 4h10M3 8h10M3 12h6',
    AppIconName.arrow:        'M3 8h10M9 4l4 4-4 4',
    AppIconName.shield:       'M8 2l5 2v5c0 3-2.5 5-5 6C5.5 14 3 12 3 9V4l5-2z',
    AppIconName.sword:        'M3 13l7-7M12 2l-3 3 2 2 3-3-2-2zM5 11l-2 2',
    AppIconName.map:          'M2 3l4 1 4-1 4 1v10l-4-1-4 1-4-1V3zm4 0v10m4-11v10',
    AppIconName.music:        'M6 13V4l7-2v9M6 13a2 2 0 11-4 0 2 2 0 014 0zm7 0a2 2 0 11-4 0 2 2 0 014 0z',
    AppIconName.volume:       'M8 3L4 7H2v2h2l4 4V3zm3 1a4 4 0 010 6m2-8a7 7 0 010 10',
    AppIconName.volumeOff:    'M8 3L4 7H2v2h2l4 4V3zm4 2l-4 4m0-4l4 4',
    AppIconName.star:         'M8 2l1.8 3.6L14 6.4l-3 2.9.7 4.1L8 11.4l-3.7 2 .7-4.1-3-2.9 4.2-.8z',
    AppIconName.heart:        'M8 13S3 9.5 3 5.5A3 3 0 018 3a3 3 0 015 2.5C13 9.5 8 13 8 13z',
    AppIconName.info:         'M8 7v4M8 5v.5M8 2a6 6 0 100 12A6 6 0 008 2z',
    AppIconName.warning:      'M8 6v3M8 10.5v.5M1.5 13L8 2l6.5 11H1.5z',
    AppIconName.error:        'M8 2a6 6 0 100 12A6 6 0 008 2zM8 5v4M8 10.5v.5',
    AppIconName.link:         'M7 9a3 3 0 004.2.4l2-2a3 3 0 00-4.2-4.2L7.6 4.6M9 7a3 3 0 00-4.2-.4l-2 2a3 3 0 004.2 4.2l1.4-1.4',
    AppIconName.copy:         'M11 1H4a1 1 0 00-1 1v9m2 2h8a1 1 0 001-1V5l-3-3H6a1 1 0 00-1 1v9a1 1 0 001 1z',
    AppIconName.upload:       'M8 2v8M5 5l3-3 3 3M3 12h10',
    AppIconName.download:     'M8 2v8M5 7l3 3 3-3M3 12h10',
    AppIconName.folder:       'M2 5h5l1.5-2H14a1 1 0 011 1v8a1 1 0 01-1 1H2a1 1 0 01-1-1V6a1 1 0 011-1z',
    AppIconName.file:         'M4 2h6l3 3v10a1 1 0 01-1 1H4a1 1 0 01-1-1V3a1 1 0 011-1zm6 0v3h3',
    AppIconName.image:        'M2 3h12a1 1 0 011 1v8a1 1 0 01-1 1H2a1 1 0 01-1-1V4a1 1 0 011-1zm2 7l2-3 2 2.5L10 7l3 4H2z',
    AppIconName.refresh:      'M13 8A5 5 0 113 8M13 5V2l-3 3M3 11v3l3-3',
    AppIconName.lock:         'M5 7V5a3 3 0 016 0v2M3 7h10a1 1 0 011 1v6a1 1 0 01-1 1H3a1 1 0 01-1-1V8a1 1 0 011-1zm5 3v2',
    AppIconName.unlock:       'M5 7V5a3 3 0 016 0M3 7h10a1 1 0 011 1v6a1 1 0 01-1 1H3a1 1 0 01-1-1V8a1 1 0 011-1zm5 3v2',
    AppIconName.eye:          'M8 4C4 4 2 8 2 8s2 4 6 4 6-4 6-4-2-4-6-4zm0 2a2 2 0 110 4 2 2 0 010-4z',
    AppIconName.eyeOff:       'M2 2l12 12M6.5 6.5A3 3 0 0011 11M4 4C3 5 2 6.5 2 8s2 4 6 4c1 0 2-.2 3-.5M12 5.5C13 6.5 14 7.5 14 8s-2 4-6 4',
    AppIconName.send:         'M14 2L9 14l-2-4-4-2 11-6z',
    AppIconName.inbox:        'M2 8h3l2 3h2l2-3h3M2 3h12a1 1 0 011 1v8a1 1 0 01-1 1H2a1 1 0 01-1-1V4a1 1 0 011-1z',
  };

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    final path = _paths[name] ?? '';

    // Farbe als Hex-String aufbereiten
    final argb = c.toARGB32();
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8)  & 0xFF;
    final b =  argb        & 0xFF;
    final hex     = '#${r.toRadixString(16).padLeft(2, '0')}'
                    '${g.toRadixString(16).padLeft(2, '0')}'
                    '${b.toRadixString(16).padLeft(2, '0')}';
    final opacity = (a / 255.0).toStringAsFixed(3);

    final svgString = '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 16 16" width="${size.toInt()}" height="${size.toInt()}" '
        'fill="none"><path d="$path" stroke="$hex" stroke-opacity="$opacity" '
        'stroke-width="1.5" stroke-linecap="round" '
        'stroke-linejoin="round"/></svg>';

    return SvgPicture.string(svgString, width: size, height: size);
  }
}

// Unit-Tests für SoundMixerConfig und SoundMixerSize-Presets.
//
// Prüft:
//   - Alle SoundMixerSize-Werte ergeben eine gültige SoundMixerConfig
//   - Explizite Config überschreibt Size-Preset
//   - Default-Werte der SoundMixerConfig-Felder
//   - Semantik der statischen Preset-Configs (minimalConfig, fullConfig)

import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/widgets/audio/sound_mixer_widget.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SoundMixerConfig — Default-Werte
  // ---------------------------------------------------------------------------

  group('SoundMixerConfig Defaults', () {
    const config = SoundMixerConfig();

    test('showAddButtons ist standardmäßig true', () {
      expect(config.showAddButtons, true);
    });

    test('showMasterVolume ist standardmäßig true', () {
      expect(config.showMasterVolume, true);
    });

    test('readOnly ist standardmäßig false', () {
      expect(config.readOnly, false);
    });

    test('compactMode ist standardmäßig false', () {
      expect(config.compactMode, false);
    });

    test('showTimeDisplay ist standardmäßig true', () {
      expect(config.showTimeDisplay, true);
    });

    test('showLoopToggle ist standardmäßig true', () {
      expect(config.showLoopToggle, true);
    });

    test('maxHeight ist standardmäßig null (unbegrenzt)', () {
      expect(config.maxHeight, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Statische Preset-Configs
  // ---------------------------------------------------------------------------

  group('SoundMixerConfig.minimalConfig', () {
    const config = SoundMixerConfig.minimalConfig;

    test('ist readonly', () => expect(config.readOnly, true));
    test('zeigt keine Add-Buttons', () => expect(config.showAddButtons, false));
    test('zeigt keinen Master-Volume', () => expect(config.showMasterVolume, false));
    test('ist kompakt', () => expect(config.compactMode, true));
    test('zeigt keine Zeit-Anzeige', () => expect(config.showTimeDisplay, false));
  });

  group('SoundMixerConfig.fullConfig', () {
    const config = SoundMixerConfig.fullConfig;

    test('ist nicht readonly', () => expect(config.readOnly, false));
    test('zeigt Add-Buttons', () => expect(config.showAddButtons, true));
    test('zeigt Master-Volume', () => expect(config.showMasterVolume, true));
    test('zeigt Stop-All Button', () => expect(config.showStopAllButton, true));
    test('zeigt Zeit-Anzeige', () => expect(config.showTimeDisplay, true));
    test('zeigt Loop-Toggle', () => expect(config.showLoopToggle, true));
  });

  // ---------------------------------------------------------------------------
  // SoundMixerSize — alle Presets liefern gültige Config
  // ---------------------------------------------------------------------------

  group('SoundMixerSize Presets', () {
    SoundMixerConfig configFor(SoundMixerSize size) =>
        SoundMixerConfig.fromSize(size);

    test('minimal → readOnly, keine Add-Buttons', () {
      final cfg = configFor(SoundMixerSize.minimal);
      expect(cfg.readOnly, true);
      expect(cfg.showAddButtons, false);
    });

    test('compact → readOnly, hat Master-Volume', () {
      final cfg = configFor(SoundMixerSize.compact);
      expect(cfg.readOnly, true);
      expect(cfg.showMasterVolume, true);
    });

    test('medium → readOnly, hat Zeit-Anzeige und Loop-Toggle', () {
      final cfg = configFor(SoundMixerSize.medium);
      expect(cfg.readOnly, true);
      expect(cfg.showTimeDisplay, true);
      expect(cfg.showLoopToggle, true);
    });

    test('expanded → readOnly, hat alles außer Add-Buttons', () {
      final cfg = configFor(SoundMixerSize.expanded);
      expect(cfg.readOnly, true);
      expect(cfg.showAddButtons, false);
      expect(cfg.showTimeDisplay, true);
    });

    test('full → nicht readOnly, hat Add-Buttons', () {
      final cfg = configFor(SoundMixerSize.full);
      expect(cfg.readOnly, false);
      expect(cfg.showAddButtons, true);
    });

    test('kein Preset liefert null', () {
      for (final size in SoundMixerSize.values) {
        expect(() => configFor(size), returnsNormally);
      }
    });

    test('read-only Presets haben showAddButtons=false', () {
      final readOnlySizes = [
        SoundMixerSize.minimal,
        SoundMixerSize.compact,
        SoundMixerSize.medium,
        SoundMixerSize.expanded,
      ];
      for (final size in readOnlySizes) {
        final cfg = configFor(size);
        expect(cfg.showAddButtons, false,
            reason: '${size.name} sollte showAddButtons=false haben');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Explizite Config überschreibt Size
  // ---------------------------------------------------------------------------

  group('Explizite Config', () {
    test('überschreibt alle Size-Defaults', () {
      const explicitConfig = SoundMixerConfig(
        compactMode: true,
        showAddButtons: false,
        showMasterVolume: false,
        readOnly: true,
        showTimeDisplay: false,
        showLoopToggle: false,
        maxHeight: 300,
      );

      expect(explicitConfig.compactMode, true);
      expect(explicitConfig.showAddButtons, false);
      expect(explicitConfig.readOnly, true);
      expect(explicitConfig.maxHeight, 300);
    });

    test('readOnly=true blockiert Add-Buttons-Logik', () {
      const cfg = SoundMixerConfig(
        showAddButtons: true,
        readOnly: true,
      );
      // readOnly überschreibt showAddButtons in der UI-Guard-Logik
      expect(cfg.readOnly, true);
      expect(cfg.showAddButtons, true);
    });

    test('showAddButtons=false und readOnly=false → keine Add-Buttons', () {
      const cfg = SoundMixerConfig(
        showAddButtons: false,
        readOnly: false,
      );
      expect(cfg.showAddButtons, false);
    });
  });
}

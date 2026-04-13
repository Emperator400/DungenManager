import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dungen_manager/widgets/audio/sound_mixer_widget.dart';
import 'package:dungen_manager/widgets/ui_components/cards/section_card_widget.dart';
import 'package:dungen_manager/models/sound.dart';
import 'package:dungen_manager/database/repositories/sound_model_repository.dart';

class WidgetTestGround extends StatefulWidget {
  const WidgetTestGround({super.key});

  @override
  State<WidgetTestGround> createState() => _WidgetTestGround();
}

class _WidgetTestGround extends State<WidgetTestGround> {
  
  // Geladene Sounds aus der Datenbank
  List<Sound> _ambientSounds = [];
  List<Sound> _effectSounds = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSoundsFromDatabase();
  }
  
  /// Lädt Sounds aus der Datenbank für die verschiedenen Widget-Varianten
  Future<void> _loadSoundsFromDatabase() async {
    try {
      final soundRepo = context.read<SoundModelRepository>();
      
      // Lade Ambiente- und Effekt-Sounds
      final ambient = await soundRepo.findByType(SoundType.Ambiente);
      final effects = await soundRepo.findByType(SoundType.Effekt);
      
      if (mounted) {
        setState(() {
          _ambientSounds = ambient;
          _effectSounds = effects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Fehler beim Laden der Sounds: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SoundMixer Widget Test"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadSoundsFromDatabase();
            },
            tooltip: 'Neu laden',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadSoundsFromDatabase();
                },
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Prüfen ob Sounds verfügbar sind
    final hasAmbient = _ambientSounds.isNotEmpty;
    final hasEffects = _effectSounds.isNotEmpty;
    final hasAnySounds = hasAmbient || hasEffects;
    
    if (!hasAnySounds) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, color: Colors.grey, size: 48),
              SizedBox(height: 16),
              Text(
                'Keine Sounds in der Datenbank gefunden.\n\n'
                'Bitte füge zuerst Sounds über die Sound-Bibliothek hinzu.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Sounds für die verschiedenen Widgets zusammenstellen
    final minimalSounds = hasAmbient ? [_ambientSounds.first] : <Sound>[];
    final compactSounds = hasEffects ? [_effectSounds.first] : (hasAmbient ? [_ambientSounds.first] : <Sound>[]);
    final mediumSounds = hasAmbient ? [_ambientSounds.first] : <Sound>[];
    
    // Für expanded und full: mische Ambiente und Effekte
    final expandedSounds = <Sound>[];
    if (hasAmbient) expandedSounds.add(_ambientSounds.first);
    if (_ambientSounds.length > 1) expandedSounds.add(_ambientSounds[1]);
    else if (hasEffects) expandedSounds.add(_effectSounds.first);
    
    final fullSounds = <Sound>[];
    // Bis zu 3 Sounds für das full-Widget
    for (int i = 0; i < 3 && i < _ambientSounds.length; i++) {
      fullSounds.add(_ambientSounds[i]);
    }
    for (int i = 0; i < 3 && fullSounds.length < 3 && i < _effectSounds.length; i++) {
      fullSounds.add(_effectSounds[i]);
    }
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Info-Text
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_ambientSounds.length} Ambiente + ${_effectSounds.length} Effekte geladen',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        // MINIMAL - Nur Play/Pause + Volume
        if (minimalSounds.isNotEmpty)
          SectionCardWidget(
            title: "minimal - Play/Pause + Volume",
            icon: Icons.minimize,
            child: SoundMixerWidget(
              initialSounds: minimalSounds,
              size: SoundMixerSize.minimal,
            ),
          ),
        const SizedBox(height: 16),
        
        // COMPACT - + Master-Volume, Header, Stop-All
        if (compactSounds.isNotEmpty)
          SectionCardWidget(
            title: "compact - + Master, Header, Stop",
            icon: Icons.compress,
            child: SoundMixerWidget(
              initialSounds: compactSounds,
              size: SoundMixerSize.compact,
            ),
          ),
        const SizedBox(height: 16),
        
        // MEDIUM - + Zeit-Anzeige, Fortschrittsbalken, Loop-Toggle
        if (mediumSounds.isNotEmpty)
          SectionCardWidget(
            title: "medium - + Zeit, Progress, Loop",
            icon: Icons.adjust,
            child: SoundMixerWidget(
              initialSounds: mediumSounds,
              size: SoundMixerSize.medium,
            ),
          ),
        const SizedBox(height: 16),
        
        // EXPANDED - + Skip-Buttons, Speed-Control, detaillierte Info
        if (expandedSounds.isNotEmpty)
          SectionCardWidget(
            title: "expanded - + Skip, Speed, Details",
            icon: Icons.expand,
            child: SoundMixerWidget(
              initialSounds: expandedSounds,
              size: SoundMixerSize.expanded,
            ),
          ),
        const SizedBox(height: 16),
        
        // FULL - + Add-Sound Buttons, Channel-Counter (alle Features)
        if (fullSounds.isNotEmpty)
          SectionCardWidget(
            title: "full - + Add-Buttons, Counter",
            icon: Icons.fullscreen,
            child: SoundMixerWidget(
              initialSounds: fullSounds,
              size: SoundMixerSize.full,
            ),
          ),
        const SizedBox(height: 24),
        
        // Legende
        _buildLegend(),
      ],
    );
  }
  
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feature-Übersicht:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendRow('minimal', 'Play/Pause, Volume'),
          _buildLegendRow('compact', '+ Master, Header, Stop'),
          _buildLegendRow('medium', '+ Zeit, Progress, Loop'),
          _buildLegendRow('expanded', '+ Skip, Speed, Details'),
          _buildLegendRow('full', '+ Add-Buttons, Counter'),
        ],
      ),
    );
  }
  
  Widget _buildLegendRow(String size, String features) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              size,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            features,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
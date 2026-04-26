import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scene.dart';
import '../../viewmodels/edit_scene_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../characters/select_character_screen.dart';

const _purple = Color(0xFF7C3AED);

const Map<SceneType, Color> _typeColor = {
  SceneType.Introduction: Color(0xFF2F6FEB),
  SceneType.Social:       Color(0xFF7C3AED),
  SceneType.Exploration:  Color(0xFF1A7F4B),
  SceneType.Combat:       Color(0xFFC93A3A),
  SceneType.Puzzle:       Color(0xFFB45309),
  SceneType.Climax:       Color(0xFF0891B2),
  SceneType.Resolution:   Color(0xFF065F46),
};

const Map<SceneType, String> _typeLabel = {
  SceneType.Introduction: 'Einführung',
  SceneType.Social:       'Sozial',
  SceneType.Exploration:  'Erforschung',
  SceneType.Combat:       'Kampf',
  SceneType.Puzzle:       'Rätsel',
  SceneType.Climax:       'Höhepunkt',
  SceneType.Resolution:   'Auflösung',
};

class EditSceneScreen extends StatefulWidget {
  final Scene? scene;
  final String? sessionId;

  const EditSceneScreen({Key? key, this.scene, this.sessionId}) : super(key: key);

  @override
  State<EditSceneScreen> createState() => _EditSceneScreenState();
}

class _EditSceneScreenState extends State<EditSceneScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeViewModel());
  }

  Future<void> _initializeViewModel() async {
    if (!mounted) return;
    final vm = context.read<EditSceneViewModel>();
    await vm.initialize(widget.scene, sessionId: widget.sessionId);
    if (!mounted) return;
    _controllersFromViewModel();
    await vm.loadAvailableQuests();
    if (!mounted) return;
    await vm.loadAvailableSounds();
    if (!mounted) return;
    await vm.loadAvailableWikiEntries();
    if (!mounted) return;
    await vm.buildLinkedCharactersList();
    if (!mounted) return;
    await vm.buildLinkedQuestsList();
    if (!mounted) return;
    await vm.buildLinkedSoundsList();
    if (!mounted) return;
    await vm.buildLinkedWikiEntriesList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _controllersFromViewModel() {
    final scene = context.read<EditSceneViewModel>().scene;
    if (scene != null) {
      _nameController.text = scene.name;
      _descriptionController.text = scene.description;
    }
  }

  void _updateViewModel() {
    final vm = context.read<EditSceneViewModel>();
    vm.updateName(_nameController.text);
    vm.updateDescription(_descriptionController.text);
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      body: Consumer<EditSceneViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return Center(child: CircularProgressIndicator(color: C.accent, strokeWidth: 2));
          }

          final sceneType = vm.scene?.sceneType ?? SceneType.Exploration;
          final typeColor = _typeColor[sceneType] ?? C.accent;
          final isNew = widget.scene == null;

          return Column(
            children: [
              _buildHeader(C, typeColor, isNew),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vm.errorMessage != null) _buildErrorBanner(C, vm),
                      _buildBasicInfoCard(C, vm, sceneType),
                      const SizedBox(height: 12),
                      _buildDescriptionCard(C),
                      const SizedBox(height: 12),
                      _buildLinkedCard(
                        C: C,
                        icon: Icons.person_outline,
                        label: 'Charaktere',
                        color: C.accent,
                        count: vm.linkedCharacters.length,
                        tags: vm.linkedCharacters
                            .map((ch) => _buildTagChip(C, ch['name'].toString(), C.accent,
                                () => vm.removeCharacter(ch['id'].toString())))
                            .toList(),
                        onAdd: () => _showCharacterSelector(vm),
                      ),
                      const SizedBox(height: 12),
                      _buildLinkedCard(
                        C: C,
                        icon: Icons.flag_outlined,
                        label: 'Quests',
                        color: C.amber,
                        count: vm.linkedQuests.length,
                        tags: vm.linkedQuests
                            .map((q) => _buildTagChip(C, q.title, C.amber,
                                () => vm.removeQuest(q.id.toString())))
                            .toList(),
                        onAdd: () => _showQuestSelector(vm),
                      ),
                      const SizedBox(height: 12),
                      _buildLinkedCard(
                        C: C,
                        icon: Icons.music_note_outlined,
                        label: 'Sounds',
                        color: C.green,
                        count: vm.linkedSounds.length,
                        tags: vm.linkedSounds
                            .map((s) => _buildTagChip(C, s.name, C.green,
                                () => vm.removeSound(s.id)))
                            .toList(),
                        onAdd: () => _showSoundSelector(vm),
                      ),
                      const SizedBox(height: 12),
                      _buildLinkedCard(
                        C: C,
                        icon: Icons.book_outlined,
                        label: 'Wiki-Einträge',
                        color: _purple,
                        count: vm.linkedWikiEntries.length,
                        tags: vm.linkedWikiEntries
                            .map((w) => _buildTagChip(C, w.title, _purple,
                                () => vm.removeWikiEntry(w.id)))
                            .toList(),
                        onAdd: () => _showWikiEntrySelector(vm),
                      ),
                      if (sceneType == SceneType.Combat) ...[
                        const SizedBox(height: 12),
                        _buildCombatCard(C, vm),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _buildFooter(C, vm, isNew),
            ],
          );
        },
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppColorsExtension C, Color typeColor, bool isNew) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(Icons.article_outlined, size: 13, color: typeColor),
                ),
                const SizedBox(width: 10),
                Text(
                  isNew ? 'Neue Szene' : 'Szene bearbeiten',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: C.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.close, size: 14, color: C.textMid),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: C.border),
      ],
    );
  }

  // ── FOOTER ───────────────────────────────────────────────────────────────────

  Widget _buildFooter(AppColorsExtension C, EditSceneViewModel vm, bool isNew) {
    final canSave = vm.canSave;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: C.border),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        border: Border.all(color: C.border),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.textMid),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: canSave ? _saveScene : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: canSave ? C.accent : C.bgHover,
                        border: canSave ? null : Border.all(color: C.border),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, size: 13,
                              color: canSave ? Colors.white : C.textSoft),
                          const SizedBox(width: 6),
                          Text(
                            isNew ? 'Szene erstellen' : 'Speichern',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: canSave ? Colors.white : C.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── SECTION CARDS ─────────────────────────────────────────────────────────────

  Widget _buildBasicInfoCard(AppColorsExtension C, EditSceneViewModel vm, SceneType sceneType) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GRUNDINFORMATIONEN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: C.textSoft, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Text('Name *', style: TextStyle(fontSize: 11, color: C.textSoft)),
          const SizedBox(height: 4),
          TextField(
            controller: _nameController,
            style: TextStyle(fontSize: 13, color: C.text),
            decoration: _inputDeco(C, hint: 'Szenen-Name'),
            onChanged: (_) => _updateViewModel(),
          ),
          const SizedBox(height: 10),
          Text('Szenen-Typ', style: TextStyle(fontSize: 11, color: C.textSoft)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: SceneType.values.map((type) {
              final color = _typeColor[type] ?? C.accent;
              final label = _typeLabel[type] ?? type.name;
              final isActive = sceneType == type;
              return GestureDetector(
                onTap: () => vm.updateSceneType(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
                    border: Border.all(color: isActive ? color : C.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                      color: isActive ? color : C.textMid,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BESCHREIBUNG',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: C.textSoft, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            style: TextStyle(fontSize: 13, color: C.text, height: 1.6),
            decoration: _inputDeco(C,
                hint: 'Szenen-Beschreibung, DM-Notizen, wichtige Details...'),
            onChanged: (_) => _updateViewModel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedCard({
    required AppColorsExtension C,
    required IconData icon,
    required String label,
    required Color color,
    required int count,
    required List<Widget> tags,
    required VoidCallback onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(C, icon, label, count, color, onAdd),
          const SizedBox(height: 8),
          if (tags.isEmpty)
            Text('Keine verknüpft',
                style: TextStyle(fontSize: 12, color: C.textSoft, fontStyle: FontStyle.italic))
          else
            Wrap(spacing: 5, runSpacing: 5, children: tags),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(AppColorsExtension C, IconData icon, String label,
      int count, Color color, VoidCallback onAdd) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: C.bgActive, borderRadius: BorderRadius.circular(4)),
          child: Text('$count', style: TextStyle(fontSize: 10, color: C.textSoft)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: C.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 11, color: C.textSoft),
                const SizedBox(width: 4),
                Text('Hinzufügen', style: TextStyle(fontSize: 11, color: C.textMid)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(
      AppColorsExtension C, String text, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 11, color: C.textSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(AppColorsExtension C, EditSceneViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.red.withValues(alpha: 0.08),
        border: Border.all(color: C.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: C.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(vm.errorMessage!, style: TextStyle(fontSize: 12, color: C.text))),
          GestureDetector(
            onTap: vm.clearError,
            child: Icon(Icons.close, size: 14, color: C.textSoft),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(AppColorsExtension C, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: C.textSoft),
      filled: true,
      fillColor: C.bgActive,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.accent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    );
  }

  // ── COMBAT CARD ───────────────────────────────────────────────────────────────

  Widget _buildCombatCard(AppColorsExtension C, EditSceneViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, size: 13, color: C.red),
              const SizedBox(width: 6),
              Text('Kampf-Planung',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: C.red.withValues(alpha: 0.06),
              border: Border.all(color: C.red.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: C.red, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kampfszene: Encounter planen, der während der Session gestartet werden kann.',
                    style: TextStyle(fontSize: 12, color: C.textMid),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (vm.hasLinkedEncounter)
            _buildEncounterInfo(C, vm)
          else
            GestureDetector(
              onTap: () => _planEncounter(vm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: C.red.withValues(alpha: 0.1),
                  border: Border.all(color: C.red.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gavel, size: 13, color: C.red),
                    const SizedBox(width: 6),
                    Text('Encounter planen',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.red)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEncounterInfo(AppColorsExtension C, EditSceneViewModel vm) {
    final encounter = vm.linkedEncounter!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.green.withValues(alpha: 0.08),
        border: Border.all(color: C.green.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel, color: C.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Encounter geplant',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(height: 2),
                Text(encounter.title, style: TextStyle(fontSize: 12, color: C.amber)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusBadge(C, Icons.people,
                        '${encounter.participantIds.length} Teiln.', C.accent),
                    const SizedBox(width: 6),
                    _buildStatusBadge(
                      C,
                      _encounterStatusIcon(encounter.status.toString()),
                      _encounterStatusLabel(encounter.status.toString()),
                      _encounterStatusColor(C, encounter.status.toString()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteEncounter(vm),
            child: Icon(Icons.delete_outline, color: C.red, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppColorsExtension C, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── SELECTION MODAL ───────────────────────────────────────────────────────────

  Future<void> _showSelectionDialog({
    required String title,
    required List<({String id, String label})> allItems,
    required Set<String> selectedIds,
    required void Function(String id, bool add) onToggle,
  }) async {
    final C = context.appColors;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: C.bgPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: C.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(Icons.close, size: 16, color: C.textMid),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: C.border),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: allItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Keine Einträge verfügbar',
                              style: TextStyle(fontSize: 13, color: C.textSoft),
                              textAlign: TextAlign.center),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: allItems.length,
                          itemBuilder: (ctx, i) {
                            final item = allItems[i];
                            final isSelected = selectedIds.contains(item.id);
                            return GestureDetector(
                              onTap: () {
                                onToggle(item.id, !isSelected);
                                setS(() {
                                  if (isSelected) {
                                    selectedIds.remove(item.id);
                                  } else {
                                    selectedIds.add(item.id);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? C.bgActive : Colors.transparent,
                                  border: Border(bottom: BorderSide(color: C.border)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: isSelected ? C.accent : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? C.accent : C.borderStrong,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              size: 10, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(item.label,
                                          style:
                                              TextStyle(fontSize: 13, color: C.text)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Divider(height: 1, color: C.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                            color: C.accent,
                            borderRadius: BorderRadius.circular(7)),
                        child: const Text('Fertig',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SELECTORS ─────────────────────────────────────────────────────────────────

  Future<void> _showCharacterSelector(EditSceneViewModel vm) async {
    final selectedIds = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute<List<String>>(
        builder: (ctx) => SelectCharacterForSceneScreen(
          previouslySelectedIds: vm.scene?.linkedCharacterIds ?? [],
        ),
      ),
    );
    if (selectedIds != null) {
      vm.updateLinkedCharacters(selectedIds);
      vm.buildLinkedCharactersList();
      await vm.loadAvailableQuests();
      vm.buildLinkedQuestsList();
    }
  }

  Future<void> _showQuestSelector(EditSceneViewModel vm) async {
    final linkedIds =
        Set<String>.from(vm.scene?.linkedQuestIds ?? []);
    await _showSelectionDialog(
      title: 'Quests verknüpfen',
      allItems:
          vm.availableQuests.map((q) => (id: q.id.toString(), label: q.title)).toList(),
      selectedIds: linkedIds,
      onToggle: (id, add) => add ? vm.addQuest(id) : vm.removeQuest(id),
    );
    if (mounted) await vm.buildLinkedQuestsList();
  }

  Future<void> _showSoundSelector(EditSceneViewModel vm) async {
    final linkedIds = Set<String>.from(vm.scene?.linkedSoundIds ?? []);
    await _showSelectionDialog(
      title: 'Sounds verknüpfen',
      allItems: vm.availableSounds.map((s) => (id: s.id, label: s.name)).toList(),
      selectedIds: linkedIds,
      onToggle: (id, add) => add ? vm.addSound(id) : vm.removeSound(id),
    );
    if (mounted) await vm.buildLinkedSoundsList();
  }

  Future<void> _showWikiEntrySelector(EditSceneViewModel vm) async {
    final linkedIds = Set<String>.from(vm.scene?.linkedWikiEntryIds ?? []);
    await _showSelectionDialog(
      title: 'Wiki-Einträge verknüpfen',
      allItems: vm.availableWikiEntries.map((w) => (id: w.id, label: w.title)).toList(),
      selectedIds: linkedIds,
      onToggle: (id, add) => add ? vm.addWikiEntry(id) : vm.removeWikiEntry(id),
    );
    if (mounted) await vm.buildLinkedWikiEntriesList();
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────────

  Future<void> _saveScene() async {
    final C = context.appColors;
    final vm = context.read<EditSceneViewModel>();
    final success = await vm.saveScene();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            const Text('Szene gespeichert', style: TextStyle(color: Colors.white)),
        backgroundColor: C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ));
      Navigator.pop(context, true);
    }
  }

  // ── ENCOUNTER MANAGEMENT ──────────────────────────────────────────────────────

  Future<void> _deleteEncounter(EditSceneViewModel vm) async {
    final C = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: BorderSide(color: C.border)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.warning_outlined, color: C.red, size: 18),
                const SizedBox(width: 8),
                Text('Encounter löschen?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
              ]),
              const SizedBox(height: 12),
              Text(
                'Möchtest du den Encounter "${vm.linkedEncounter?.title ?? "Unbenannt"}" wirklich löschen?',
                style: TextStyle(fontSize: 13, color: C.textMid),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _dialogBtn(C, 'Abbrechen', C.textMid, outlined: true,
                      onTap: () => Navigator.pop(ctx, false)),
                  const SizedBox(width: 8),
                  _dialogBtn(C, 'Löschen', Colors.white, bgColor: C.red,
                      onTap: () => Navigator.pop(ctx, true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      final success = await vm.deleteLinkedEncounter();
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Encounter gelöscht', style: TextStyle(color: Colors.white)),
          backgroundColor: context.appColors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  void _planEncounter(EditSceneViewModel vm) {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: BorderSide(color: C.border)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.gavel, color: C.red, size: 16),
                const SizedBox(width: 8),
                Text('Encounter planen',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
              ]),
              const SizedBox(height: 12),
              Text('Möchtest du einen Encounter für diese Kampfszene planen?',
                  style: TextStyle(fontSize: 13, color: C.textMid)),
              const SizedBox(height: 4),
              Text('Tipp: Speichere die Szene zuerst.',
                  style: TextStyle(
                      fontSize: 12, color: C.amber, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _dialogBtn(C, 'Abbrechen', C.textMid, outlined: true,
                      onTap: () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  _dialogBtn(C, 'Encounter erstellen', Colors.white, bgColor: C.red,
                      onTap: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    if (vm.hasUnsavedChanges || !vm.isEditing) {
                      final saved = await vm.saveScene();
                      if (!mounted) return;
                      if (!saved) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Fehler beim Speichern der Szene'),
                          backgroundColor: context.appColors.red,
                        ));
                        return;
                      }
                    }
                    _showEncounterTitleDialog(vm);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEncounterTitleDialog(EditSceneViewModel vm) {
    final C = context.appColors;
    final titleController =
        TextEditingController(text: vm.scene?.name ?? 'Kampf');

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: BorderSide(color: C.border)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Encounter erstellen',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 12),
              Text('Name für den Encounter:',
                  style: TextStyle(fontSize: 11, color: C.textSoft)),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                style: TextStyle(fontSize: 13, color: C.text),
                decoration: _inputDeco(C, hint: 'Leer lassen für Szenennamen'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _dialogBtn(C, 'Abbrechen', C.textMid, outlined: true,
                      onTap: () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  _dialogBtn(C, 'Erstellen', Colors.white, bgColor: C.accent,
                      onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    final customTitle = titleController.text.trim();
                    final encounter = await vm.createEncounterForScene(
                        customTitle: customTitle.isEmpty ? null : customTitle);
                    if (!mounted) return;
                    if (encounter != null) {
                      messenger.showSnackBar(SnackBar(
                        content: Text('Encounter "${encounter.title}" erstellt!',
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: context.appColors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ));
                    } else {
                      messenger.showSnackBar(SnackBar(
                        content: Text(
                            vm.errorMessage ?? 'Fehler beim Erstellen des Encounters',
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: context.appColors.red,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogBtn(AppColorsExtension C, String label, Color textColor,
      {Color? bgColor, bool outlined = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: outlined ? Border.all(color: C.border) : null,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
      ),
    );
  }

  // ── ENCOUNTER STATUS ──────────────────────────────────────────────────────────

  IconData _encounterStatusIcon(String status) => switch (status) {
        'preparation' => Icons.schedule,
        'active' => Icons.play_circle_outline,
        'completed' => Icons.check_circle_outline,
        'paused' => Icons.pause_circle_outline,
        _ => Icons.help_outline,
      };

  String _encounterStatusLabel(String status) => switch (status) {
        'preparation' => 'Vorbereitung',
        'active' => 'Aktiv',
        'completed' => 'Abgeschlossen',
        'paused' => 'Pausiert',
        _ => 'Unbekannt',
      };

  Color _encounterStatusColor(AppColorsExtension C, String status) => switch (status) {
        'active' => C.red,
        'completed' => C.green,
        'paused' => C.amber,
        _ => C.accent,
      };
}

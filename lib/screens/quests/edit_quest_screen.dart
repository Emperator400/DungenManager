import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/edit_quest_viewmodel.dart';
import '../../models/quest.dart';
import '../../models/quest_reward.dart';
import '../../theme/app_theme.dart';

class EditQuestScreen extends StatefulWidget {
  final Quest? quest;
  final String? campaignId;
  final String? initialTitle;
  final String? initialDescription;

  const EditQuestScreen({
    super.key,
    this.quest,
    this.campaignId,
    this.initialTitle,
    this.initialDescription,
  });

  @override
  State<EditQuestScreen> createState() => _EditQuestScreenState();
}

class _EditQuestScreenState extends State<EditQuestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _recommendedLevelController = TextEditingController();
  final _estimatedDurationController = TextEditingController();

  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _recommendedLevelFocusNode = FocusNode();
  final _estimatedDurationFocusNode = FocusNode();

  late final EditQuestViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EditQuestViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize(widget.quest, campaignId: widget.campaignId);
      _populateFields();
      _viewModel.addListener(_onViewModelChanged);
    });
  }

  void _onViewModelChanged() {
    final quest = _viewModel.quest;
    if (quest != null && mounted) {
      if (!_titleFocusNode.hasFocus && _titleController.text != quest.title) {
        _titleController.text = quest.title;
      }
      if (!_descriptionFocusNode.hasFocus &&
          _descriptionController.text != quest.description) {
        _descriptionController.text = quest.description;
      }
      if (!_locationFocusNode.hasFocus &&
          _locationController.text != (quest.location ?? '')) {
        _locationController.text = quest.location ?? '';
      }
      if (!_recommendedLevelFocusNode.hasFocus &&
          _recommendedLevelController.text !=
              (quest.recommendedLevel?.toString() ?? '')) {
        _recommendedLevelController.text =
            quest.recommendedLevel?.toString() ?? '';
      }
      if (!_estimatedDurationFocusNode.hasFocus &&
          _estimatedDurationController.text !=
              (quest.estimatedDurationHours?.toString() ?? '')) {
        _estimatedDurationController.text =
            quest.estimatedDurationHours?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _recommendedLevelController.dispose();
    _estimatedDurationController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _locationFocusNode.dispose();
    _recommendedLevelFocusNode.dispose();
    _estimatedDurationFocusNode.dispose();
    super.dispose();
  }

  void _populateFields() {
    final quest = _viewModel.quest;
    if (quest != null) {
      _titleController.text = quest.title.isNotEmpty ? quest.title : (widget.initialTitle ?? '');
      _descriptionController.text = quest.description.isNotEmpty ? quest.description : (widget.initialDescription ?? '');
      _locationController.text = quest.location ?? '';
      _recommendedLevelController.text =
          quest.recommendedLevel?.toString() ?? '';
      _estimatedDurationController.text =
          quest.estimatedDurationHours?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return ChangeNotifierProvider<EditQuestViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: _buildAppBar(context, C),
        body: SafeArea(
          top: false,
          child: Consumer<EditQuestViewModel>(
            builder: (context, vm, _) => _buildForm(context, vm),
          ),
        ),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, AppColorsExtension C) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        height: 48,
        color: C.bgPanel,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<EditQuestViewModel>(
                  builder: (_, vm, __) => Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        GestureDetector(
                          onTap: () => _handleBackNavigation(vm),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Icon(Icons.arrow_back, size: 18, color: C.textMid),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(width: 1, height: 18, color: C.border),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: C.amber.withValues(alpha: 0.18),
                          border: Border.all(color: C.amber.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Icon(Icons.assignment, size: 13, color: C.amber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vm.quest != null ? 'Quest bearbeiten' : 'Neue Quest',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: C.text),
                      ),
                      const Spacer(),
                      if (vm.hasUnsavedChanges)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: C.amber.withValues(alpha: 0.18),
                            border: Border.all(
                                color: C.amber.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 10, color: C.amber),
                              const SizedBox(width: 4),
                              Text('Bearbeitet',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: C.amber,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: vm.isLoading
                            ? null
                            : () => _handleSave(vm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: vm.isLoading
                                ? C.accent.withValues(alpha: 0.5)
                                : C.accent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: vm.isLoading
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, size: 13, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text('Speichern',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: C.border),
          ],
        ),
      ),
    );
  }

  // ── FORM ──────────────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context, EditQuestViewModel vm) {
    final C = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.errorMessage != null) ...[
              _ErrorBanner(message: vm.errorMessage!, C: C),
              const SizedBox(height: 12),
            ],
            _buildSection(
              C: C,
              title: 'Grundlegende Informationen',
              child: Column(
                children: [
                  _field(
                    context: context,
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    label: 'Titel *',
                    hint: 'z.B. Die Rettung vom Drachenhort',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Titel ist erforderlich';
                      if (v.trim().length < 2) return 'Mindestens 2 Zeichen';
                      return null;
                    },
                    onChanged: vm.updateTitle,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    context: context,
                    controller: _descriptionController,
                    focusNode: _descriptionFocusNode,
                    label: 'Beschreibung *',
                    hint: 'Beschreibe den Quest und seine Ziele…',
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Beschreibung ist erforderlich' : null,
                    onChanged: vm.updateDescription,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    context: context,
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    label: 'Ort',
                    hint: 'Wo findet der Quest statt?',
                    onChanged: vm.updateLocation,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSection(
              C: C,
              title: 'Quest-Details',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _dropdown<QuestStatus>(
                          context: context,
                          value: vm.quest?.status,
                          label: 'Status',
                          items: QuestStatus.values,
                          displayName: _statusLabel,
                          onChanged: (v) {
                            if (v != null) vm.updateStatus(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown<QuestType>(
                          context: context,
                          value: vm.quest?.questType,
                          label: 'Typ',
                          items: QuestType.values,
                          displayName: _typeLabel,
                          onChanged: (v) {
                            if (v != null) vm.updateQuestType(v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dropdown<QuestDifficulty>(
                          context: context,
                          value: vm.quest?.difficulty,
                          label: 'Schwierigkeit',
                          items: QuestDifficulty.values,
                          displayName: _difficultyLabel,
                          onChanged: (v) {
                            if (v != null) vm.updateDifficulty(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          context: context,
                          controller: _recommendedLevelController,
                          focusNode: _recommendedLevelFocusNode,
                          label: 'Level',
                          hint: '1–20',
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final l = int.tryParse(v);
                            if (l != null) vm.updateRecommendedLevel(l);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    context: context,
                    controller: _estimatedDurationController,
                    focusNode: _estimatedDurationFocusNode,
                    label: 'Dauer (Stunden)',
                    hint: 'z.B. 2.5',
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null) vm.updateEstimatedDuration(d);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildRewardsSection(context, vm, C),
            const SizedBox(height: 20),
            _buildBottomButtons(context, vm, C),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required AppColorsExtension C,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: C.textSoft,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRewardsSection(
      BuildContext context, EditQuestViewModel vm, AppColorsExtension C) {
    final rewards = vm.quest?.rewards ?? [];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BELOHNUNGEN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: C.textSoft,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddRewardDialog(vm),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: C.amber.withValues(alpha: 0.15),
                    border:
                        Border.all(color: C.amber.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 12, color: C.amber),
                      const SizedBox(width: 4),
                      Text('Belohnung',
                          style: TextStyle(
                              fontSize: 11,
                              color: C.amber,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rewards.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: C.bgHover,
                border: Border.all(color: C.border),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Column(
                children: [
                  Icon(Icons.card_giftcard_outlined,
                      size: 28, color: C.border),
                  const SizedBox(height: 8),
                  Text('Noch keine Belohnungen',
                      style: TextStyle(fontSize: 12, color: C.textSoft)),
                ],
              ),
            )
          else
            Column(
              children: rewards
                  .map((r) => _RewardRow(
                        reward: r,
                        C: C,
                        onDelete: () => _showDeleteRewardDialog(vm, r),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
      BuildContext context, EditQuestViewModel vm, AppColorsExtension C) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    vm.isLoading ? null : () => _handleCancel(vm),
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.textMid,
                  side: BorderSide(color: C.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Abbrechen',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: vm.isLoading ? null : () => _handleSave(vm),
                style: FilledButton.styleFrom(
                  backgroundColor: C.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: vm.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Speichern',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        if (vm.quest != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      vm.isLoading ? null : () => _handleDuplicate(vm),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.accent,
                    side: BorderSide(color: C.accent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Duplizieren',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      vm.isLoading ? null : () => _handleDelete(vm),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.red,
                    side: BorderSide(color: C.red.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Löschen',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── FIELD BUILDERS ────────────────────────────────────────────────────────────

  Widget _field({
    required BuildContext context,
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final C = context.appColors;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: C.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 12, color: C.textMid),
        hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
        filled: true,
        fillColor: C.bgHover,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.red),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _dropdown<T>({
    required BuildContext context,
    required T? value,
    required String label,
    required List<T> items,
    required String Function(T) displayName,
    required void Function(T?) onChanged,
  }) {
    final C = context.appColors;
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: C.bgPanel,
      style: TextStyle(fontSize: 13, color: C.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: C.textMid),
        filled: true,
        fillColor: C.bgHover,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.accent),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(displayName(item),
                    style: TextStyle(fontSize: 13, color: C.text)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ── LABEL HELPERS ─────────────────────────────────────────────────────────────

  String _statusLabel(QuestStatus s) => switch (s) {
        QuestStatus.active    => 'Aktiv',
        QuestStatus.completed => 'Abgeschlossen',
        QuestStatus.failed    => 'Fehlgeschlagen',
        QuestStatus.abandoned => 'Aufgegeben',
        QuestStatus.onHold    => 'Pausiert',
      };

  String _typeLabel(QuestType t) => switch (t) {
        QuestType.main     => 'Hauptquest',
        QuestType.side     => 'Nebenquest',
        QuestType.personal => 'Persönlich',
        QuestType.faction  => 'Fraktions-Quest',
      };

  String _difficultyLabel(QuestDifficulty d) => switch (d) {
        QuestDifficulty.easy      => 'Leicht',
        QuestDifficulty.medium    => 'Mittel',
        QuestDifficulty.hard      => 'Schwer',
        QuestDifficulty.deadly    => 'Tödlich',
        QuestDifficulty.epic      => 'Episch',
        QuestDifficulty.legendary => 'Legendär',
      };

  // ── DIALOGS ───────────────────────────────────────────────────────────────────

  void _showAddRewardDialog(EditQuestViewModel vm) {
    final descCtrl = TextEditingController();
    final goldCtrl = TextEditingController();
    final xpCtrl = TextEditingController();
    final C = context.appColors;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Belohnung hinzufügen',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: C.text)),
              const SizedBox(height: 14),
              _dialogField(ctx, descCtrl, 'Beschreibung', 'z.B. Magisches Schwert'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dialogField(ctx, goldCtrl, 'Gold (optional)', '0',
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dialogField(ctx, xpCtrl, 'EP (optional)', '0',
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Abbrechen',
                        style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final gold = int.tryParse(goldCtrl.text) ?? 0;
                      final xp = int.tryParse(xpCtrl.text) ?? 0;
                      if (descCtrl.text.trim().isNotEmpty ||
                          gold > 0 ||
                          xp > 0) {
                        vm.addReward(QuestReward(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          type: gold > 0
                              ? QuestRewardType.gold
                              : QuestRewardType.experience,
                          name: descCtrl.text.trim().isNotEmpty
                              ? descCtrl.text
                              : (gold > 0 ? 'Gold Belohnung' : 'EP Belohnung'),
                          description: descCtrl.text.trim().isNotEmpty
                              ? descCtrl.text
                              : null,
                          goldAmount: gold > 0 ? gold : null,
                          experiencePoints: xp > 0 ? xp : null,
                        ));
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: C.amber,
                        foregroundColor: Colors.black87),
                    child: const Text('Hinzufügen',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteRewardDialog(EditQuestViewModel vm, QuestReward reward) {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Belohnung löschen',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: C.text)),
              const SizedBox(height: 10),
              Text('"${reward.name}" wirklich löschen?',
                  style: TextStyle(fontSize: 13, color: C.textMid)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Abbrechen',
                        style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      vm.removeReward(reward);
                      Navigator.of(ctx).pop();
                    },
                    style: FilledButton.styleFrom(backgroundColor: C.red),
                    child: const Text('Löschen',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    BuildContext ctx,
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType? keyboardType,
  }) {
    final C = ctx.appColors;
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: C.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 12, color: C.textMid),
        hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
        filled: true,
        fillColor: C.bgHover,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.accent),
        ),
      ),
    );
  }

  // ── ACTIONS ───────────────────────────────────────────────────────────────────

  Future<void> _handleSave(EditQuestViewModel vm) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await vm.saveQuest();
      if (success && mounted) Navigator.of(context).pop(true);
    }
  }

  void _handleCancel(EditQuestViewModel vm) {
    if (vm.hasUnsavedChanges) {
      _showDiscardDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete(EditQuestViewModel vm) async {
    final confirmed = await _showConfirmDialog(
      title: 'Quest löschen',
      message:
          'Möchtest du diese Quest wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
      confirmLabel: 'Löschen',
      isDestructive: true,
    );
    if (confirmed == true) {
      final success = await vm.deleteQuest();
      if (success && mounted) Navigator.of(context).pop(true);
    }
  }

  void _handleDuplicate(EditQuestViewModel vm) {
    vm.duplicateQuest();
    _populateFields();
  }

  void _handleBackNavigation(EditQuestViewModel vm) {
    if (vm.hasUnsavedChanges) {
      _showDiscardDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showDiscardDialog() {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Änderungen verwerfen',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: C.text)),
              const SizedBox(height: 10),
              Text(
                  'Du hast ungespeicherte Änderungen. Wirklich verlassen?',
                  style: TextStyle(fontSize: 13, color: C.textMid)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Weiter bearbeiten',
                        style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(backgroundColor: C.accent),
                    child: const Text('Verlassen',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    final C = context.appColors;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: C.text)),
              const SizedBox(height: 10),
              Text(message,
                  style: TextStyle(fontSize: 13, color: C.textMid)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Abbrechen',
                        style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                        backgroundColor:
                            isDestructive ? C.red : C.accent),
                    child: Text(confirmLabel,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LOCAL WIDGETS ─────────────────────────────────────────────────────────────

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.reward,
    required this.C,
    required this.onDelete,
  });

  final QuestReward reward;
  final AppColorsExtension C;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(
            reward.goldAmount != null && reward.goldAmount! > 0
                ? Icons.monetization_on
                : reward.experiencePoints != null &&
                        reward.experiencePoints! > 0
                    ? Icons.auto_graph
                    : Icons.card_giftcard,
            size: 14,
            color: C.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: C.text)),
                if ((reward.goldAmount ?? 0) > 0 ||
                    (reward.experiencePoints ?? 0) > 0)
                  Row(
                    children: [
                      if ((reward.goldAmount ?? 0) > 0) ...[
                        Text('${reward.goldAmount} GP',
                            style:
                                TextStyle(fontSize: 11, color: C.amber)),
                        if ((reward.experiencePoints ?? 0) > 0)
                          const SizedBox(width: 8),
                      ],
                      if ((reward.experiencePoints ?? 0) > 0)
                        Text('${reward.experiencePoints} EP',
                            style: TextStyle(
                                fontSize: 11, color: C.accent)),
                    ],
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: C.red.withValues(alpha: 0.08),
                border: Border.all(color: C.red.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.delete_outline, size: 13, color: C.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.C});

  final String message;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: C.red.withValues(alpha: 0.08),
        border: Border.all(color: C.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: C.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12, color: C.red)),
          ),
        ],
      ),
    );
  }
}

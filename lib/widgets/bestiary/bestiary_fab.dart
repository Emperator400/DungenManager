import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';
import '../../screens/bestiary/edit_creature_screen.dart';

/// FloatingActionButton für das Bestiarum zum Erstellen neuer Kreaturen
class BestiaryFab extends StatelessWidget {
  final TabController tabController;
  final VoidCallback onDataChanged;

  const BestiaryFab({
    super.key,
    required this.tabController,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        // Zeige FAB nur auf den ersten drei Tabs
        if (tabController.index >= 3) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: C.green, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (ctx) => const EditCreatureScreen(),
                ),
              );
              if (result == true) {
                onDataChanged();
              }
            },
            backgroundColor: C.green,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Neue Kreatur'),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/proxy_models.dart';
import '../providers/app_state.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/custom_title_bar.dart';
import '../widgets/profile_card.dart';
import 'profile_editor_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          CustomTitleBar(),
          Expanded(child: _HomeBody()),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConnectionStatusCard(
                info: state.connection,
                onToggle: state.toggleConnection,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Profiles',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.profiles.isEmpty)
                _EmptyProfiles(onAdd: () => _openEditor(context))
              else
                ...state.profiles.map(
                  (profile) => ProfileCard(
                    profile: profile,
                    selected: state.selectedProfile?.id == profile.id,
                    onTap: () => state.selectProfile(profile),
                    onEdit: () => _openEditor(context, profile: profile),
                    onDelete: () => _confirmDelete(context, state, profile),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openEditor(BuildContext context, {ProxyProfile? profile}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileEditorSheet(profile: profile),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppState state,
    ProxyProfile profile,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Delete Profile'),
        content: Text('Remove "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              state.deleteProfile(profile);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  const _EmptyProfiles({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 36, color: AppTheme.textSecondary),
          const SizedBox(height: 10),
          Text(
            'No profiles yet',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }
}

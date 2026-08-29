import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/admin_ui.dart';
import '../../data/providers/database_usage_provider.dart';
import 'widgets/database_usage_card.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseUsageProvider>().fetchUsage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, 'Respaldo y Almacenamiento'),
      body: RefreshIndicator(
        onRefresh: () => context.read<DatabaseUsageProvider>().fetchUsage(),
        child: Consumer<DatabaseUsageProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                SyncStatusCard(usage: provider.usage),
                const SizedBox(height: 16),
                DatabaseUsageCard(
                  usage: provider.usage,
                  isLoading: provider.isLoading,
                  functionMissing: provider.functionMissing,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

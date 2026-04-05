import 'package:flutter/material.dart';
import '../services/post_migration_service.dart';

class MigrationTestPage extends StatefulWidget {
  const MigrationTestPage({super.key});

  @override
  State<MigrationTestPage> createState() => _MigrationTestPageState();
}

class _MigrationTestPageState extends State<MigrationTestPage> {
  bool _isRunning = false;
  String _resultText = '';

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _resultText = 'Migration läuft...';
    });

    final service = PostMigrationService();
    final result = await service.migrateExistingPosts();

    if (!mounted) return;

    setState(() {
      _isRunning = false;
      _resultText =
      'Fertig.\nGeprüft: ${result.checked}\nAktualisiert: ${result.updated}\nÜbersprungen: ${result.skipped}\nFehler: ${result.failed}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runMigration,
              child: Text(_isRunning ? 'Läuft...' : 'Migration starten'),
            ),
            const SizedBox(height: 20),
            Text(_resultText),
          ],
        ),
      ),
    );
  }
}
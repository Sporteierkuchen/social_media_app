import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PostMigrationResult {
  final int checked;
  final int updated;
  final int skipped;
  final int failed;

  const PostMigrationResult({
    required this.checked,
    required this.updated,
    required this.skipped,
    required this.failed,
  });

  @override
  String toString() {
    return 'PostMigrationResult(checked: $checked, updated: $updated, skipped: $skipped, failed: $failed)';
  }
}

class PostMigrationService {
  final FirebaseFirestore _firestore;

  PostMigrationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<PostMigrationResult> migrateExistingPosts() async {
    int checked = 0;
    int updated = 0;
    int skipped = 0;
    int failed = 0;

    try {
      final snapshot = await _firestore.collection('posts').get();

      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in snapshot.docs) {
        checked++;

        try {
          final data = doc.data();

          final String type =
          (data['type'] as String? ?? '').toLowerCase().trim();

          final String title = (data['title'] as String? ?? '').trim();
          final String vorname = (data['vorname'] as String? ?? '').trim();
          final String nachname = (data['nachname'] as String? ?? '').trim();
          final String benutzername =
          (data['benutzername'] as String? ?? '').trim();

          final List<String> categories = _toStringList(data['category']);

          final String mediaUrl = (data['mediaUrl'] as String? ?? '').trim();
          final String thumbnailUrl =
          (data['thumbnailUrl'] as String? ?? '').trim();

          final String existingPreviewUrl =
          (data['previewUrl'] as String? ?? '').trim();
          final String existingFullImageUrl =
          (data['fullImageUrl'] as String? ?? '').trim();
          final String existingTitleLower =
          (data['titleLower'] as String? ?? '').trim();
          final String existingFullNameLower =
          (data['fullNameLower'] as String? ?? '').trim();
          final String existingSearchText =
          (data['searchText'] as String? ?? '').trim();

          String computedPreviewUrl = existingPreviewUrl;
          String computedFullImageUrl = existingFullImageUrl;

          if (type == 'image') {
            if (computedPreviewUrl.isEmpty) {
              computedPreviewUrl = mediaUrl;
            }
            if (computedFullImageUrl.isEmpty) {
              computedFullImageUrl = mediaUrl;
            }
          } else {
            // video oder unbekannt -> wie video behandeln
            if (computedPreviewUrl.isEmpty) {
              computedPreviewUrl =
              thumbnailUrl.isNotEmpty ? thumbnailUrl : mediaUrl;
            }
            if (computedFullImageUrl.isEmpty) {
              computedFullImageUrl = '';
            }
          }

          final String computedTitleLower =
          existingTitleLower.isNotEmpty ? existingTitleLower : title.toLowerCase();

          final String computedFullNameLower = existingFullNameLower.isNotEmpty
              ? existingFullNameLower
              : '$vorname $nachname'.trim().toLowerCase();

          final String computedSearchText = existingSearchText.isNotEmpty
              ? existingSearchText
              : _buildSearchText(
            title: title,
            vorname: vorname,
            nachname: nachname,
            benutzername: benutzername,
            categories: categories,
          );

          final Map<String, dynamic> updateData = {
            'previewUrl': computedPreviewUrl,
            'fullImageUrl': computedFullImageUrl,
            'titleLower': computedTitleLower,
            'fullNameLower': computedFullNameLower,
            'searchText': computedSearchText,
          };

          final bool needsUpdate = _needsUpdate(
            oldPreviewUrl: existingPreviewUrl,
            oldFullImageUrl: existingFullImageUrl,
            oldTitleLower: existingTitleLower,
            oldFullNameLower: existingFullNameLower,
            oldSearchText: existingSearchText,
            newPreviewUrl: computedPreviewUrl,
            newFullImageUrl: computedFullImageUrl,
            newTitleLower: computedTitleLower,
            newFullNameLower: computedFullNameLower,
            newSearchText: computedSearchText,
          );

          if (!needsUpdate) {
            skipped++;
            continue;
          }

          batch.update(doc.reference, updateData);
          updated++;
          batchCount++;

          if (batchCount >= 400) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        } catch (e) {
          failed++;
          debugPrint(
            '[PostMigrationService] Fehler bei Dokument ${doc.id}: $e',
          );
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      final result = PostMigrationResult(
        checked: checked,
        updated: updated,
        skipped: skipped,
        failed: failed,
      );

      debugPrint('[PostMigrationService] Migration fertig: $result');
      return result;
    } catch (e) {
      debugPrint('[PostMigrationService] Gesamtfehler bei Migration: $e');

      return PostMigrationResult(
        checked: checked,
        updated: updated,
        skipped: skipped,
        failed: failed + 1,
      );
    }
  }

  bool _needsUpdate({
    required String oldPreviewUrl,
    required String oldFullImageUrl,
    required String oldTitleLower,
    required String oldFullNameLower,
    required String oldSearchText,
    required String newPreviewUrl,
    required String newFullImageUrl,
    required String newTitleLower,
    required String newFullNameLower,
    required String newSearchText,
  }) {
    return oldPreviewUrl != newPreviewUrl ||
        oldFullImageUrl != newFullImageUrl ||
        oldTitleLower != newTitleLower ||
        oldFullNameLower != newFullNameLower ||
        oldSearchText != newSearchText;
  }

  String _buildSearchText({
    required String title,
    required String vorname,
    required String nachname,
    required String benutzername,
    required List<String> categories,
  }) {
    return [
      title,
      vorname,
      nachname,
      '$vorname $nachname',
      benutzername,
      ...categories,
    ].join(' ').toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _toStringList(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    return const [];
  }
}
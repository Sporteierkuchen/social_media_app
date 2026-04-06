import 'package:flutter/material.dart';

import '../../../../widgets/Bestätigung.dart';
import '../../../models/Meldung.dart';
import '../../../repositories/post_repository.dart';
import '../../../util/HelperUtil.dart';

class CategoryOverviewSection extends StatefulWidget {
  final PostRepository postRepository;

  const CategoryOverviewSection({
    super.key,
    required this.postRepository,
  });

  @override
  State<CategoryOverviewSection> createState() =>
      _CategoryOverviewSectionState();
}

class _CategoryOverviewSectionState extends State<CategoryOverviewSection> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: widget.postRepository.categoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text(
              "Fehler beim Laden der Kategorien.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          );
        }

        final categories = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 40, bottom: 14),
              child: Text(
                "Kategorienübersicht",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (categories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Text(
                  "Keine Kategorien vorhanden.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((category) {
                  return _CategoryChipCard(
                    category: category,
                    onDelete: () async {
                      await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (dialogContext) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              dialogTheme: const DialogThemeData(
                                backgroundColor: Colors.black,
                              ),
                            ),
                            child: BestaetigungsDialog(
                              title: "Kategorie löschen",
                              message:
                              "Soll die Kategorie \"$category\" wirklich gelöscht werden?",
                              onConfirm: () async {
                                await _deleteCategory(category);
                              },
                              onCancel: () {},
                            ),
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(String categoryName) async {
    final name = categoryName.trim();
    if (name.isEmpty) return;

    try {
      await widget.postRepository.deleteCategoryByName(name);

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Kategorie erfolgreich gelöscht!",
        ),
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Löschen der Kategorie:\n$e",
        ),
      );
    }
  }
}

class _CategoryChipCard extends StatelessWidget {
  final String category;
  final VoidCallback onDelete;

  const _CategoryChipCard({
    required this.category,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 260,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sell_outlined,
            color: Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              softWrap: true,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
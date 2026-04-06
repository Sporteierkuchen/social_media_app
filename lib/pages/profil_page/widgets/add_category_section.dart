import 'package:flutter/material.dart';

import '../../../../widgets/TextInput.dart';
import '../../../models/Meldung.dart';
import '../../../repositories/post_repository.dart';
import '../../../util/HelperUtil.dart';

class AddCategorySection extends StatefulWidget {
  final PostRepository postRepository;

  const AddCategorySection({
    super.key,
    required this.postRepository,
  });

  @override
  State<AddCategorySection> createState() => _AddCategorySectionState();
}

class _AddCategorySectionState extends State<AddCategorySection> {
  final TextEditingController _categoryController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kategorie hinzufügen",
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          TextInput(
            label: "Neue Kategorie",
            obscureText: false,
            controller: _categoryController,
            prefixIcon: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: _isSaving
                ? const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : GestureDetector(
              onTap: _addCategory,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.orangeAccent,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.black,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Hinzufügen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await widget.postRepository.addCategory(categoryName);

      _categoryController.clear();

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Kategorie erfolgreich hinzugefügt!",
        ),
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Hinzufügen der Kategorie:\n$e",
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }
}
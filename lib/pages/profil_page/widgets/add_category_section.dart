
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: TextInput(
            label: "Kategorie",
            obscureText: false,
            controller: _categoryController,
            prefixIcon: const Icon(Icons.add),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
            child: GestureDetector(
              onTap: () async {
                await _addCategory();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.grey[800],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 30,
                      color: Colors.green,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Kategorie hinzufügen",
                      softWrap: true,
                      style: TextStyle(
                        height: 0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) return;

    try {
      await widget.postRepository.addCategory(categoryName);

      _categoryController.clear();

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Kategorie erfolgreich hinzugefügt!",
        )
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Hinzufügen der Kategorie:\n$e",
        )
      );
    }
  }

}

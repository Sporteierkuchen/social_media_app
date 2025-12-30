
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
  State<CategoryOverviewSection> createState() => _CategoryOverviewSectionState();
}

class _CategoryOverviewSectionState extends State<CategoryOverviewSection> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: widget.postRepository.categoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              "Keine Kategorien vorhanden.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          );
        }

        final categories = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 40, bottom: 20),
              child: Text(
                "Kategorienübersicht",
                style: TextStyle(
                  fontSize: 22,
                  height: 0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 0,
                right: 0,
                top: 0,
                bottom: 10,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 3.0,
                mainAxisSpacing: 3.0,
                childAspectRatio: 80 / 20,
              ),
              itemCount: categories?.length,
              itemBuilder: (context, index) {

                String? category = categories?[index];

                return Container(
                  padding: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    border: Border.all(),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: SingleChildScrollView(
                            child: Text(
                              category!,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 0,
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (BuildContext context) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  dialogTheme: DialogThemeData(backgroundColor: Colors.black),
                                ),
                                child: BestaetigungsDialog(
                                  title: "Kategorie löschen",
                                  message:
                                  "Soll die Kategorie \"$category\" wirklich gelöscht werden?",
                                  onConfirm: () async {
                                    await _deleteCategory(category);
                                  },
                                  onCancel: () {
                                    // optional: nix
                                  },
                                ),
                              );
                            },
                          );
                        },
                        child: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
        ), context: context,
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Löschen der Kategorie:\n$e",
        ), context: context,
      );
    }
  }

}

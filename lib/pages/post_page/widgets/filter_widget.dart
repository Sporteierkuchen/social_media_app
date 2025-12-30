import 'package:flutter/material.dart';

class CustomDialog extends StatefulWidget {
  final List<String> kategorien;
  final List<String> selectedCategories;
  final Function(List<String>) updateSelectedCategories;

  const CustomDialog({
    super.key,
    required this.kategorien,
    required this.updateSelectedCategories,
    required this.selectedCategories,
  });

  @override
  State<StatefulWidget> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  late List<String> _localSelected; // lokale Kopie, damit man abbrechen kann

  @override
  void initState() {
    super.initState();

    // Kategorien sortieren
    widget.kategorien
        .sort((a, b) => a.trim().toLowerCase().compareTo(b.trim().toLowerCase()));

    _localSelected = List<String>.from(widget.selectedCategories);
  }

  bool _isSelected(String category) => _localSelected.contains(category);

  void _toggleCategory(String category, bool isSelected) async {
    setState(() {
      if (isSelected) {
        _localSelected.add(category);
      } else {
        _localSelected.remove(category);
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      surfaceTintColor: Colors.black,
      shadowColor: Colors.orange.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.orange.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Kategorien',
            style: TextStyle(
              fontSize: 26,
              height: 1.1,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Wähle die Kategorien, nach denen gefiltert werden soll.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: media.size.width * 0.85,
        height: media.size.height * 0.55,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Scrollbar(
            thumbVisibility: true,
            radius: const Radius.circular(8),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.kategorien.length,
              itemBuilder: (context, index) {
                final category = widget.kategorien[index];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isSelected(category)
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSelected(category)
                          ? Colors.orange
                          : Colors.grey.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    dense: true,
                    title: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    activeColor: Colors.orange,
                    checkColor: Colors.black,
                    value: _isSelected(category),
                    onChanged: (val) {
                      if (val == null) return;
                      _toggleCategory(category, val);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Erste Zeile: Abbrechen + Zurücksetzen
              Row(
                children: [
                  // Abbrechen links
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // nichts übernehmen
                      },
                      child: const Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Zurücksetzen rechts
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _localSelected.clear();
                        });
                      },
                      child: const Text(
                        'Zurücksetzen',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Zweite Zeile: Übernehmen zentriert
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    widget.updateSelectedCategories(_localSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Übernehmen',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

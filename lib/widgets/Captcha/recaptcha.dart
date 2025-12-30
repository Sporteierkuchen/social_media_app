// lib/widgets/recaptcha.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../Toast.dart';

class Recaptcha extends StatefulWidget {
  final bool selected;
  final bool correct;
  final ValueChanged<bool> updateSelected;
  final ValueChanged<bool> updateCorrect;
  final List<String> okBilderList;
  final List<String> filterBilderList;
  final int gridSize;
  final String suchwort;

  const Recaptcha({
    super.key,
    required this.selected,
    required this.correct,
    required this.updateSelected,
    required this.updateCorrect,
    required this.okBilderList,
    required this.filterBilderList,
    required this.suchwort,
    this.gridSize = 3,
  });

  @override
  State<StatefulWidget> createState() => _RecaptchaState();
}

class _RecaptchaState extends State<Recaptcha> {
  final Random rnd = Random();

  bool canChange = true;

  late bool _selected;
  late bool _correct;
  late int _gridSize;

  final List<String> bilderList = <String>[];
  final List<String> randomBilderList = <String>[];

  @override
  void initState() {
    super.initState();

    _selected = widget.selected;
    _correct = widget.correct;
    _gridSize = widget.gridSize <= 0 ? 3 : widget.gridSize;

    for (final b in widget.filterBilderList) {
      if (!bilderList.contains(b)) {
        bilderList.add(b);
      }
    }
    for (final b in widget.okBilderList) {
      if (!bilderList.contains(b)) {
        bilderList.add(b);
      }
    }

    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            width: 1,
            color: Colors.black26,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.blueAccent,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(
                left: 5,
                right: 5,
                top: 5,
                bottom: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text links
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Klicke alle Bilder mit',
                        style: TextStyle(
                          fontSize: 16,
                          height: 0,
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        widget.suchwort,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Beispiel-Bild rechts
                  widget.filterBilderList.isNotEmpty
                      ? Image.asset(
                    widget.filterBilderList[0],
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                  )
                      : const SizedBox.shrink(),
                ],
              ),
            ),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize,
                mainAxisSpacing: 2.0,
                crossAxisSpacing: 2.0,
              ),
              padding: const EdgeInsets.only(
                left: 5,
                right: 5,
                top: 0,
                bottom: 5,
              ),
              itemCount: randomBilderList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      randomBilderList[index] =
                          _changeBild(randomBilderList[index]);
                    });
                  },
                  child: Image.asset(
                    randomBilderList[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),

            // Footer mit Buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border.symmetric(
                  horizontal: BorderSide(
                    width: 1,
                    color: Colors.black26,
                  ),
                ),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Links: Refresh + X
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _refresh();
                          });
                        },
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.grey,
                          size: 35,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            canChange = true;
                            _selected = false;
                            _correct = false;
                            widget.updateSelected(_selected);
                            widget.updateCorrect(_correct);
                          });

                          // Dialog schließen → false zurückgeben
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(false);
                          }
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 35,
                        ),
                      ),
                    ],
                  ),

                  // Rechts: Bestätigen
                  ElevatedButton(
                    onPressed: () async {
                      bool isCorrect = true;
                      for (final b in randomBilderList) {
                        if (widget.filterBilderList.contains(b)) {
                          isCorrect = false;
                          break;
                        }
                      }

                      setState(() {
                        _correct = isCorrect;
                        widget.updateCorrect(_correct);
                      });

                      if (!isCorrect) {
                        _refresh();
                        showWarning(
                          context,
                          "Die Captcha ist nicht korrekt!",
                        );
                      } else {
                        // korrekt – Eltern-Widget schließt Dialog
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: const Text(
                      'Bestätigen',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _refresh() {
    if (bilderList.isEmpty) return;

    randomBilderList.clear();
    const int min = 0;
    final int max = bilderList.length;

    final int anzahl = pow(_gridSize, 2).toInt();
    for (int i = 0; i < anzahl; i++) {
      final int r = min + rnd.nextInt(max - min);
      randomBilderList.add(bilderList[r]);
    }
  }

  String _changeBild(String bild) {
    if (bilderList.length < 2) {
      return bild;
    }

    final List<String> kopie = List<String>.from(bilderList);
    kopie.remove(bild);

    const int min = 0;
    final int max = kopie.length;
    final int r = min + rnd.nextInt(max - min);

    return kopie[r];
  }
}

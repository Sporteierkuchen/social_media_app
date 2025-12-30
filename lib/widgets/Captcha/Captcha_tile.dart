// lib/widgets/Captcha_tile.dart
import 'package:flutter/material.dart';
import 'recaptcha.dart';

class CaptchaTile extends StatefulWidget {
  final bool solved;
  final ValueChanged<bool> onSolvedChanged;

  final List<String> okBilderList;
  final List<String> filterBilderList;
  final String suchwort;
  final int gridSize;

  const CaptchaTile({
    super.key,
    required this.solved,
    required this.onSolvedChanged,
    required this.okBilderList,
    required this.filterBilderList,
    required this.suchwort,
    this.gridSize = 3,
  });

  @override
  State<CaptchaTile> createState() => _CaptchaTileState();
}

class _CaptchaTileState extends State<CaptchaTile> {
  late bool _solved;

  @override
  void initState() {
    super.initState();
    _solved = widget.solved;
  }

  @override
  void didUpdateWidget(covariant CaptchaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.solved != widget.solved) {
      _solved = widget.solved;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            width: 3,
            color: Colors.black,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.blueAccent,
          secondary: widget.filterBilderList.isNotEmpty
              ? Image.asset(
            widget.filterBilderList[0],
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.width * 0.2,
          )
              : const SizedBox.shrink(),
          title: Text(
            'Ich bin kein Roboter',
            style: TextStyle(
              fontSize: 20,
              height: 0,
              color: _solved ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          value: _solved,
          onChanged: _onCheckboxChanged,
        ),
      ),
    );
  }

  Future<void> _onCheckboxChanged(bool? value) async {
    if (value == null) return;

    // ✅ Wenn Captcha bereits gelöst wurde, nichts mehr machen.
    // Checkbox bleibt gesetzt und es geht kein Dialog mehr auf.
    if (_solved) {
      return;
    }

    if (value == false) {
      // explizites Abwählen, bevor gelöst wurde
      setState(() {
        _solved = false;
      });
      widget.onSolvedChanged(false);
      return;
    }

    // Checkbox wurde angeklickt → Dialog mit Recaptcha öffnen
    final bool ok = await _openCaptchaDialog() ?? false;
    if (!mounted) return;

    setState(() {
      _solved = ok;
    });
    widget.onSolvedChanged(ok);
  }

  Future<bool?> _openCaptchaDialog() async {
    bool dialogSelected = false;
    bool dialogCorrect = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width * 0.9,
              maxHeight: size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Recaptcha(
                selected: dialogSelected,
                correct: dialogCorrect,
                updateSelected: (val) {
                  dialogSelected = val;
                },
                updateCorrect: (val) {
                  dialogCorrect = val;
                  widget.onSolvedChanged(val);
                  if (val == true) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                okBilderList: widget.okBilderList,
                filterBilderList: widget.filterBilderList,
                suchwort: widget.suchwort,
                gridSize: widget.gridSize,
              ),
            ),
          ),
        );
      },
    );

    return result;
  }
}

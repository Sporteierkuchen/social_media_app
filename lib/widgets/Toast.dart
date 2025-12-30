import 'package:flutter/material.dart';

/// Interner Helfer, um Duplikate zu vermeiden
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _showSnack(
    BuildContext context, {
      required String text,
      required Color color,
      required IconData icon,
      Duration duration = const Duration(seconds: 3),
    }) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: Colors.black87, // 🔹 dunkler Hintergrund
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 5,
              right: 15,
              top: 5,
              bottom: 5,
            ),
            child: Icon(
              icon,
              color: color,
              size: 40,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  height: 0,
                  fontWeight: FontWeight.bold,
                  color: color, // 🔹 farbiger Text (Info/Success/Warning/Error)
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Öffentliche Funktionen – API bleibt wie bei dir
// ---------------------------------------------------------------------------

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showInfo(
    BuildContext context,
    String text,
    ) {
  return _showSnack(
    context,
    text: text,
    color: Colors.blue,
    icon: Icons.info_outlined,
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess(
    BuildContext context,
    String text,
    ) {
  return _showSnack(
    context,
    text: text,
    color: Colors.green,
    icon: Icons.check,
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showWarning(
    BuildContext context,
    String text,
    ) {
  return _showSnack(
    context,
    text: text,
    color: Colors.orange,
    icon: Icons.warning_outlined,
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(
    BuildContext context,
    String text,
    ) {
  return _showSnack(
    context,
    text: text,
    color: Colors.red,
    icon: Icons.error_outlined,
  );
}

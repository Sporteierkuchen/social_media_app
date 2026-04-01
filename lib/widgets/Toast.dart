import 'dart:async';
import 'package:flutter/material.dart';

import '../services/navigation_service.dart';

OverlayEntry? _currentToast;
Timer? _toastTimer;

Future<void> _showToast({
  required String title,
  required String message,
  required String symbol,
  required Color backgroundColor,
  required Color accentColor,
  required Color textColor,
  Duration duration = const Duration(milliseconds: 2400),
}) async {
  OverlayState? overlay;

  for (int i = 0; i < 8; i++) {
    overlay = NavigationService.navigatorKey.currentState?.overlay;
    if (overlay != null) break;
    await Future.delayed(const Duration(milliseconds: 60));
  }

  if (overlay == null) {
    debugPrint('[Toast] Kein Overlay verfügbar.');
    return;
  }

  _toastTimer?.cancel();
  _currentToast?.remove();
  _currentToast = null;

  _currentToast = OverlayEntry(
    builder: (context) {
      return _ToastOverlayWidget(
        title: title,
        message: message,
        symbol: symbol,
        backgroundColor: backgroundColor,
        accentColor: accentColor,
        textColor: textColor,
      );
    },
  );

  overlay.insert(_currentToast!);

  _toastTimer = Timer(duration, () {
    _currentToast?.remove();
    _currentToast = null;
  });
}

class _ToastOverlayWidget extends StatefulWidget {
  final String title;
  final String message;
  final String symbol;
  final Color backgroundColor;
  final Color accentColor;
  final Color textColor;

  const _ToastOverlayWidget({
    required this.title,
    required this.message,
    required this.symbol,
    required this.backgroundColor,
    required this.accentColor,
    required this.textColor,
  });

  @override
  State<_ToastOverlayWidget> createState() => _ToastOverlayWidgetState();
}

class _ToastOverlayWidgetState extends State<_ToastOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.985,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.34),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.backgroundColor.withOpacity(0.98),
                                widget.backgroundColor.withOpacity(0.92),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 5,
                                  color: widget.accentColor,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: widget.accentColor.withOpacity(0.16),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: widget.accentColor.withOpacity(0.36),
                                              width: 1.1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              widget.symbol,
                                              style: TextStyle(
                                                color: widget.accentColor,
                                                fontSize: 19,
                                                fontWeight: FontWeight.w700,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 13),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                widget.title,
                                                style: TextStyle(
                                                  color: widget.textColor,
                                                  fontSize: 15.6,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                widget.message,
                                                softWrap: true,
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: widget.textColor.withOpacity(0.92),
                                                  fontSize: 14.2,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showSuccess(String title, String message) {
  return _showToast(
    title: title,
    message: message,
    symbol: '✓',
    backgroundColor: const Color(0xFF0F1F16),
    accentColor: const Color(0xFF22C55E),
    textColor: Colors.white,
  );
}

Future<void> showInfo(String title, String message) {
  return _showToast(
    title: title,
    message: message,
    symbol: 'i',
    backgroundColor: const Color(0xFF111E33),
    accentColor: const Color(0xFF3B82F6),
    textColor: Colors.white,
  );
}

Future<void> showWarning(String title, String message) {
  return _showToast(
    title: title,
    message: message,
    symbol: '!',
    backgroundColor: const Color(0xFF2E220C),
    accentColor: const Color(0xFFF59E0B),
    textColor: Colors.white,
    duration: const Duration(milliseconds: 3000),
  );
}

Future<void> showError(String title, String message) {
  return _showToast(
    title: title,
    message: message,
    symbol: '×',
    backgroundColor: const Color(0xFF2A1111),
    accentColor: const Color(0xFFEF4444),
    textColor: Colors.white,
    duration: const Duration(milliseconds: 3200),
  );
}
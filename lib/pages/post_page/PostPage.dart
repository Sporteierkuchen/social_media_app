import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:social_media_app/pages/post_page/widgets/post_actions_bar.dart';
import 'package:social_media_app/pages/post_page/widgets/post_feed_section.dart';

import '../../models/Meldung.dart';
import '../../models/UserDto.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/user_repository.dart';
import '../../util/HelperUtil.dart';
import '../PostUploadScreen.dart';
import 'widgets/filter_widget.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage>
    with AutomaticKeepAliveClientMixin {
  final PostRepository _postRepository = PostRepository();
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();

  final TextEditingController fieldText = TextEditingController();

  bool isLoading = true;
  bool _showActionsBar = false;

  String _searchQuery = "";
  List<String> _categories = [];
  List<String> _selectedCategories = [];
  PostMediaFilter _mediaFilter = PostMediaFilter.all;

  late final String? userID;

  int warningCounter = 0;
  static const int maxWarnings = 3;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    userID = _authRepository.currentUserId;
    initialize();
  }

  @override
  void dispose() {
    fieldText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (userID == null) {
      return const Center(
        child: Text(
          "Kein Benutzer gefunden.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<UserDto?>(
      stream: _userRepository.userStream(userID!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Fehler beim Laden des Benutzers",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final userData = snapshot.data;
        final String userrole = userData?.role ?? "MELKER";

        return Container(
          color: Colors.black,
          child: Column(
            children: [
              _PostTopPanel(
                expanded: _showActionsBar,
                onToggle: () {
                  setState(() {
                    _showActionsBar = !_showActionsBar;
                  });
                },
                child: PostActionsBar(
                  userRole: userrole,
                  categories: _categories,
                  selectedCategories: _selectedCategories,
                  searchController: fieldText,
                  onFilterTapped: () async {
                    await showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (_) => Theme(
                        data: Theme.of(context).copyWith(
                          dialogTheme: const DialogThemeData(
                            backgroundColor: Colors.black,
                          ),
                        ),
                        child: CustomDialog(
                          kategorien: _categories,
                          selectedCategories: _selectedCategories,
                          updateSelectedCategories: (selected) {
                            setState(() => _selectedCategories = selected);
                            _updateSearchQuery(fieldText.text);
                          },
                        ),
                      ),
                    );
                  },
                  onUploadTapped: () async {
                    if (userrole == "RESTRICTED-USER") {
                      HelperUtil.getToast(
                        meldung: Meldung(
                          meldungsart: Meldungsart.WARNING,
                          text: "Du darfst keine Beiträge hochladen!",
                        ),
                      );
                      _handleWarning();
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PostUploadScreen(),
                        ),
                      );
                      _updateSearchQuery(fieldText.text);
                    }
                  },
                  onSearchChanged: _updateSearchQuery,
                  onSearchSubmitted: _updateSearchQuery,
                  onSearchClear: () {
                    fieldText.clear();
                    _updateSearchQuery("");
                  },
                  mediaFilter: _mediaFilter,
                  onMediaFilterChanged: (filter) {
                    setState(() => _mediaFilter = filter);
                  },
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                        : PostFeedSection(
                      postRepository: _postRepository,
                      userRole: userrole,
                      currentUserId: userID!,
                      search: _searchQuery,
                      selectedCategories: _selectedCategories,
                      mediaFilter: _mediaFilter,
                      pageSize: 20,
                    ),

                    /// 🔥 Floating Filter Button (nur wenn eingeklappt)
                    if (!_showActionsBar)
                      Positioned(
                        top: 12,
                        right: 14,
                        child: _FloatingFilterButton(
                          onTap: () {
                            setState(() {
                              _showActionsBar = true;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> initialize() async {
    try {
      await _fetchCategories();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _postRepository.fetchCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Laden der Kategorien: $e",
        ),
      );
    }
  }

  void _handleWarning() {
    warningCounter =
    warningCounter < maxWarnings ? warningCounter + 1 : 0;
  }

  void _updateSearchQuery(String query) {
    final normalized = query.toLowerCase().trim();
    if (_searchQuery == normalized) return;
    setState(() => _searchQuery = normalized);
  }
}

class _PostTopPanel extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _PostTopPanel({
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          firstChild: child,
          secondChild: const SizedBox(),
          crossFadeState:
          expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),

        /// 👇 Nur anzeigen wenn offen
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.tune_rounded, color: Colors.orange, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "Filter ausblenden",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FloatingFilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingFilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color: Colors.orange.withOpacity(0.82),
          borderRadius: BorderRadius.circular(999),
          elevation: 8,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Filter",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:social_media_app/pages/post_page/widgets/post_actions_bar.dart';
import 'package:social_media_app/pages/post_page/widgets/post_feed_section.dart';
import '../../models/Meldung.dart';
import '../../models/UserDto.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/post_repository.dart';
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
          key: const PageStorageKey<String>('post_page'),
          color: Colors.black,
          child: Column(
            children: [
              PostActionsBar(
                userRole: userrole,
                categories: _categories,
                selectedCategories: _selectedCategories,
                searchController: fieldText,
                onFilterTapped: () async {
                  await showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (BuildContext context) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          dialogTheme: const DialogThemeData(
                            backgroundColor: Colors.black,
                          ),
                        ),
                        child: CustomDialog(
                          kategorien: _categories,
                          selectedCategories: _selectedCategories,
                          updateSelectedCategories: (selected) async {
                            setState(() => _selectedCategories = selected);
                            _updateSearchQuery(fieldText.text);
                          },
                        ),
                      );
                    },
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
                onSearchChanged: (value) {
                  _updateSearchQuery(value);
                },
                onSearchSubmitted: (value) {
                  _updateSearchQuery(value);
                },
                onSearchClear: () {
                  fieldText.clear();
                  _updateSearchQuery("");
                },
                mediaFilter: _mediaFilter,
                onMediaFilterChanged: (filter) {
                  setState(() => _mediaFilter = filter);
                },
              ),

              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : PostFeedSection(
                  key: const PageStorageKey<String>('post_feed_section'),
                  postRepository: _postRepository,
                  userRole: userrole,
                  currentUserId: userID!,
                  search: _searchQuery,
                  selectedCategories: _selectedCategories,
                  mediaFilter: _mediaFilter,
                  pageSize: 20,
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
    if (warningCounter < maxWarnings) {
      warningCounter++;
    } else {
      warningCounter = 0;
    }
  }

  void _updateSearchQuery(String query) {
    final normalized = query.toLowerCase().trim();

    if (_searchQuery == normalized) return;

    setState(() {
      _searchQuery = normalized;
    });
  }
}

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

class _PostPageState extends State<PostPage> {

  final PostRepository _postRepository = PostRepository(); // für delete/like etc.
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();

  final fieldText = TextEditingController();

  bool isLoading = true;

  String _searchQuery = "";
  List<String> _categories = [];
  List<String> _selectedCategories = [];
  PostMediaFilter _mediaFilter = PostMediaFilter.all;

  late final String? userID;

  // Anzahl der bisherigen Fehler (Captcha oder Eingaben)
  int warningCounter = 0;

  // Max. Anzahl Warnungen bevor Bestrafung
  static const int maxWarnings = 3;

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: StreamBuilder<UserDto?>(
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

                  // 1) Aktionen (Filter / Hochladen / Suche)
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
                                dialogTheme: DialogThemeData(
                                  backgroundColor: Colors.black,
                                ),
                              ),
                              child: CustomDialog(
                                kategorien: _categories,
                                selectedCategories: _selectedCategories,
                                updateSelectedCategories: (selected) async {
                                  setState(() => _selectedCategories = selected);
                                  await _updateSearchQuery(fieldText.text);
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
                          ), context: context,
                        );
                        _handleWarning();
                      } else {
                        // ✅ Hier später: PostUploadScreen (Video oder Bild)
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PostUploadScreen()),
                        );

                        // danach Query neu anwenden
                        await _updateSearchQuery(fieldText.text);
                      }
                    },

                    onSearchChanged: (value) {
                      // wie bei dir: nur wenn nicht leer
                      if (value.trim().isNotEmpty) {
                        _updateSearchQuery(value);
                      }
                    },
                    onSearchSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _updateSearchQuery(value);
                      }
                    },
                    onSearchClear: () {
                      fieldText.clear();
                      _updateSearchQuery("");
                    },
                    mediaFilter: _mediaFilter,
                    onMediaFilterChanged: (filter) async {
                      setState(() => _mediaFilter = filter);
                    },
                  ),

                  // 2) Feed
                  Expanded(
                    child: PostFeedSection(
                      postRepository: _postRepository,
                      userRole: userrole,
                      currentUserId: userID!,
                      search: _searchQuery,
                      selectedCategories: _selectedCategories,
                      mediaFilter: _mediaFilter, // ✅ neu
                      pageSize: 20,
                    ),
                  ),


                ],
              ),
            );
          },
        ),
      ),
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
      // du hast das aktuell im VideoRepository -> kannst du später in PostRepository verschieben
      final categories = await _postRepository.fetchCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Laden der Kategorien: $e",
        ), context: context,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Warnlogik
  // ---------------------------------------------------------------------------
  void _handleWarning() {
    if (warningCounter < maxWarnings) {
      warningCounter++;
    } else {
      warningCounter = 0;
    }
  }

  // ✅ Suche/Filter ändern -> nur State updaten
  Future<void> _updateSearchQuery(String query) async {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
    });

  }

}

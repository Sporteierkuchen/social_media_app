import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:social_media_app/pages/post/widgets/post_besitzer_widget.dart';
import 'package:social_media_app/pages/post/widgets/post_comments_section.dart';
import 'package:social_media_app/pages/post/widgets/post_header_section.dart';

import '../../models/Meldung.dart';
import '../../models/PostDto.dart';
import '../../models/UserDto.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/post_repository.dart';
import '../../services/content_state_service.dart';
import '../../util/HelperUtil.dart';

class PostDetailPage extends StatefulWidget {
  static const String routeName = "post_detail_page";

  final PostDto post;
  final String userId;
  final String? initialCommentId;
  final String? initialReplyId;
  final bool initialOpenComments;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.userId,
    this.initialCommentId,
    this.initialReplyId,
    this.initialOpenComments = false,
  });

  @override
  State<StatefulWidget> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  bool _activeContextSet = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? chewieController;

  bool isLiked = false;
  bool isDisliked = false;
  bool canInteract = true;

  bool playerReady = false;
  bool isLoading = true;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    debugPrint("[PostDetail] initState() PostID=${widget.post.id}");

    ContentStateService.currentOpenPostId = widget.post.id;
    initialize();
  }

  @override
  void dispose() {
    debugPrint("[PostDetail] dispose() PostID=${widget.post.id}");
    _clearActivePostContext();
    _videoPlayerController?.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: StreamBuilder<UserDto?>(
            stream: _userRepository.userStream(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "Fehler beim Laden des Benutzers",
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text(
                    "Benutzer nicht gefunden",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final userData = snapshot.data!;

              return Column(
                children: [
                  PostHeaderSection(
                    postStream: _postRepository.getPostStream(widget.post.id),
                    playerReady: playerReady,
                    chewieController: chewieController,
                    canInteract: canInteract,
                    isLiked: isLiked,
                    isDisliked: isDisliked,
                    onLike: _likePost,
                    onDislike: _dislikePost,
                  ),
                  PostBesitzerWidget(
                    post: widget.post,
                    viewerData: userData,
                    onTapped: _pauseVideo,
                    ownerStream: _userRepository.userStream(widget.post.userid),
                    ownerVideoCountStream: _postRepository.userVideoCountStream(
                      widget.post.userid,
                    ),
                    ownerImageCountStream: _postRepository.userImageCountStream(
                      widget.post.userid,
                    ),
                    ownerSubscriberCountStream:
                    _userRepository.subscribersCountStream(widget.post.userid),
                    isSubscribedStream: _userRepository.isSubscribedStream(
                      viewerId: widget.userId,
                      targetId: widget.post.userid,
                    ),
                    userRepository: _userRepository,
                  ),
                  Container(
                    key: _commentsSectionKey,
                    child: PostCommentsSection(
                      post: widget.post,
                      currentUser: userData,
                      onPauseVideo: _pauseVideo,
                      commentsQuery: _postRepository.commentsQuery(widget.post.id),
                      commentsCountStream: _postRepository.commentsCountStream(widget.post.id),
                      postRepository: _postRepository,
                      initialCommentId: widget.initialCommentId,
                      initialReplyId: widget.initialReplyId,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> initialize() async {
    debugPrint("[PostDetail] initialize() gestartet");

    if (widget.post.type == PostType.video) {
      await _initializeVideoPlayer();
    }

    await _incrementViewCount();
    await _checkUserLikeDislikeStatus();
    await _setActivePostContext();

    if (mounted) setState(() => isLoading = false);

    await _scrollToCommentsSectionIfNeeded();

    debugPrint("[PostDetail] initialize() fertig");
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final url = widget.post.mediaUrl;
      if (url.isEmpty) {
        await HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.ERROR,
            text: "Für dieses Video ist keine URL vorhanden.",
          ),
        );
        return;
      }

      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();

      chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: 16 / 9,
        autoPlay: false,
        looping: false,
      );

      if (mounted) {
        setState(() => playerReady = true);
      }
    } catch (e) {
      debugPrint("[PostDetail] Fehler VideoPlayer: $e");
      await HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Initialisieren des Video-Players:\n$e",
        ),
      );
    }
  }

  Future<void> _pauseVideo() async {
    try {
      await _videoPlayerController?.pause();
    } catch (e) {
      debugPrint("[PostDetail] Fehler beim Pausieren: $e");
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      await _postRepository.incrementViewCount(widget.post.id);
      debugPrint("[PostPage] ViewCount für PostID=${widget.post.id} erhöht");
    } catch (error) {
      debugPrint("[PostPage] Fehler beim Erhöhen der Aufrufzahl: $error");
      await HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Erhöhen der Aufrufzahl:\n$error",
        ),
      );
    }
  }

  Future<void> _checkUserLikeDislikeStatus() async {
    try {
      final status = await _postRepository.getUserLikeDislikeStatus(
        postId: widget.post.id,
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        isLiked = status['liked'] ?? false;
        isDisliked = status['disliked'] ?? false;
      });

      debugPrint(
        "[PostPage] Like/Dislike-Status: liked=$isLiked, disliked=$isDisliked",
      );
    } catch (e) {
      debugPrint("[PostPage] Fehler beim Abrufen des Like/Dislike-Status: $e");
      await HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Abrufen des Like/Dislike-Status:\n$e",
        ),
      );
    }
  }

  Future<void> _likePost() async {
    if (!canInteract) return;

    if (mounted) {
      setState(() {
        canInteract = false;
      });
    }

    try {
      await _postRepository.toggleLike(
        postId: widget.post.id,
        userId: widget.userId,
        isLiked: isLiked,
        isDisliked: isDisliked,
      );

      if (mounted) {
        setState(() {
          isLiked = !isLiked;
          if (isLiked) {
            isDisliked = false;
          }
        });
      }
    } catch (e) {
      debugPrint("[PostPage] Fehler beim Liken des Post: $e");
      await HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Liken des Post:\n$e",
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          canInteract = true;
        });
      }
    }
  }

  Future<void> _dislikePost() async {
    if (!canInteract) return;

    if (mounted) {
      setState(() {
        canInteract = false;
      });
    }

    try {
      await _postRepository.toggleDislike(
        postId: widget.post.id,
        userId: widget.userId,
        isLiked: isLiked,
        isDisliked: isDisliked,
      );

      if (mounted) {
        setState(() {
          isDisliked = !isDisliked;
          if (isDisliked) {
            isLiked = false;
          }
        });
      }
    } catch (e) {
      debugPrint("[PostPage] Fehler beim Disliken des Post: $e");
      await HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Disliken des Post:\n$e",
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          canInteract = true;
        });
      }
    }
  }

  Future<void> _setActivePostContext() async {
    if (_activeContextSet) return;

    if (widget.userId.isEmpty) return;

    try {
      await _userRepository.setActivePost(
        userId: widget.userId,
        postId: widget.post.id,
      );
      _activeContextSet = true;
      debugPrint("[PostDetail] activePostId gesetzt: ${widget.post.id}");
    } catch (e) {
      debugPrint("[PostDetail] Fehler beim Setzen von activePostId: $e");
    }
  }

  Future<void> _clearActivePostContext() async {
    if (!_activeContextSet) return;
    if (widget.userId.isEmpty) return;

    try {
      await _userRepository.clearActivePostContext(
        userId: widget.userId,
      );
      debugPrint("[PostDetail] activePostId/activeCommentId gelöscht");
    } catch (e) {
      debugPrint("[PostDetail] Fehler beim Löschen des aktiven Post-Kontexts: $e");
    }
  }

  Future<void> _scrollToCommentsSectionIfNeeded() async {
    if (!widget.initialOpenComments) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 400));

      final context = _commentsSectionKey.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
  }

}
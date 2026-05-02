import 'dart:io';
import 'dart:typed_data' as typed;
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../models/Meldung.dart';
import '../repositories/auth_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';
import '../util/HelperUtil.dart';
import '../widgets/TextInput.dart';

class PostUploadScreen extends StatefulWidget {
  const PostUploadScreen({super.key});

  @override
  State<PostUploadScreen> createState() => _PostUploadScreenState();
}

class _PostUploadScreenState extends State<PostUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  final PostRepository _postRepo = PostRepository();
  final UserRepository _userRepo = UserRepository();
  final AuthRepository _authRepo = AuthRepository();

  final TextEditingController titelController = TextEditingController();

  UploadType _type = UploadType.video;

  bool _playerReady = false;
  bool _isPickingMedia = false;
  bool isUploading = false;
  bool canPop = true;

  String errorMessage = "";

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  File? _videoFile;
  File? _imageFile;

  List<String> _selectedCategories = [];
  List<String> _categories = [];

  double _uploadProgress = 0.0;
  String _uploadStatusText = "";

  @override
  void dispose() {
    titelController.dispose();
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    _videoPlayerController = null;
    _chewieController = null;
    _playerReady = false;
  }

  Future<void> _initializeVideoPlayer(File videoFile) async {
    _disposeVideoControllers();

    _videoPlayerController = VideoPlayerController.file(videoFile);

    try {
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: 16 / 9,
        autoPlay: false,
        looping: false,
      );

      if (!mounted) return;

      setState(() {
        _playerReady = true;
      });
    } catch (e) {
      debugPrint("Fehler beim Initialisieren des VideoPlayers: $e");

      if (!mounted) return;

      setState(() {
        _playerReady = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _postRepo.fetchCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Laden der Kategorien: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    setState(() {
      _isPickingMedia = true;
    });

    try {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);

      if (picked == null) return;

      final file = File(picked.path);

      setState(() {
        _videoFile = file;
        _imageFile = null;
      });

      await _fetchCategories();
      await _initializeVideoPlayer(file);
    } catch (e) {
      debugPrint("Fehler beim Auswählen des Videos: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPickingMedia = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isPickingMedia = true;
    });

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 98,
      );

      if (picked == null) return;

      final file = File(picked.path);

      setState(() {
        _imageFile = file;
        _videoFile = null;
      });

      await _fetchCategories();
      _disposeVideoControllers();
    } catch (e) {
      debugPrint("Fehler beim Auswählen des Bildes: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPickingMedia = false;
        });
      }
    }
  }

  bool _hasSelectedMedia() {
    if (_type == UploadType.video) {
      return _videoFile != null;
    }

    return _imageFile != null;
  }

  bool _checkUserInput() {
    errorMessage = "";

    if (titelController.text.trim().isEmpty) {
      errorMessage += "Gebe einen Titel ein!\n";
    }

    if (_type == UploadType.video && _videoFile == null) {
      errorMessage += "Wähle ein Video aus!\n";
    }

    if (_type == UploadType.image && _imageFile == null) {
      errorMessage += "Wähle ein Bild aus!\n";
    }

    return errorMessage.isEmpty;
  }

  Future<String> _generateThumbnail(String videoPath) async {
    final info = await VideoCompress.getFileThumbnail(
      videoPath,
      quality: 75,
    );

    return info.path;
  }

  Future<typed.Uint8List?> _createImagePreviewBytes(File imageFile) async {
    try {
      final bytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 900,
        minHeight: 900,
        quality: 72,
        format: CompressFormat.jpeg,
      );

      if (bytes == null) return null;

      return typed.Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint("Fehler beim Erzeugen des Bild-Previews: $e");
      return null;
    }
  }

  Future<bool> _uploadPost() async {
    if (!_checkUserInput()) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: errorMessage,
        ),
      );
      return false;
    }

    setState(() {
      isUploading = true;
      canPop = false;
      _uploadProgress = 0.0;
      _uploadStatusText = "Upload wird vorbereitet...";
    });

    try {
      final userId = _authRepo.currentUserId;

      if (userId == null) {
        throw Exception("Kein eingeloggter Benutzer gefunden.");
      }

      _setUploadProgress(
        progress: 0.03,
        text: "Benutzerdaten werden geladen...",
      );

      final user = await _userRepo.getUserDetailsDto(userId);

      if (user == null) {
        throw Exception("Benutzerdaten konnten nicht geladen werden.");
      }

      final String title = titelController.text.trim();

      String mediaUrl = "";
      String thumbnailUrl = "";
      String previewUrl = "";
      String fullImageUrl = "";

      if (_type == UploadType.video) {
        _setUploadProgress(
          progress: 0.08,
          text: "Video wird hochgeladen...",
        );

        mediaUrl = await _postRepo.uploadFileToStorage(
          file: _videoFile!,
          rootFolder: "videos",
          userId: userId,
          onProgress: (p) {
            _setUploadProgress(
              progress: 0.08 + (p * 0.62),
              text: "Video wird hochgeladen... ${(p * 100).toStringAsFixed(0)}%",
            );
          },
        );

        _setUploadProgress(
          progress: 0.72,
          text: "Thumbnail wird erstellt...",
        );

        final thumbPath = await _generateThumbnail(_videoFile!.path);
        final thumbFile = File(thumbPath);

        _setUploadProgress(
          progress: 0.76,
          text: "Thumbnail wird hochgeladen...",
        );

        thumbnailUrl = await _postRepo.uploadFileToStorage(
          file: thumbFile,
          rootFolder: "thumbnails",
          userId: userId,
          onProgress: (p) {
            _setUploadProgress(
              progress: 0.76 + (p * 0.14),
              text: "Thumbnail wird hochgeladen... ${(p * 100).toStringAsFixed(0)}%",
            );
          },
        );

        previewUrl = thumbnailUrl;
        fullImageUrl = "";
      } else {
        _setUploadProgress(
          progress: 0.08,
          text: "Bild wird hochgeladen...",
        );

        fullImageUrl = await _postRepo.uploadFileToStorage(
          file: _imageFile!,
          rootFolder: "images",
          userId: userId,
          onProgress: (p) {
            _setUploadProgress(
              progress: 0.08 + (p * 0.58),
              text: "Bild wird hochgeladen... ${(p * 100).toStringAsFixed(0)}%",
            );
          },
        );

        _setUploadProgress(
          progress: 0.70,
          text: "Vorschau wird erstellt...",
        );

        final previewBytes = await _createImagePreviewBytes(_imageFile!);

        if (previewBytes != null) {
          _setUploadProgress(
            progress: 0.76,
            text: "Vorschau wird hochgeladen...",
          );

          previewUrl = await _postRepo.uploadBytesToStorage(
            bytes: previewBytes,
            rootFolder: "image_previews",
            userId: userId,
            extension: "jpg",
            onProgress: (p) {
              _setUploadProgress(
                progress: 0.76 + (p * 0.14),
                text: "Vorschau wird hochgeladen... ${(p * 100).toStringAsFixed(0)}%",
              );
            },
          );
        } else {
          previewUrl = fullImageUrl;
        }

        mediaUrl = fullImageUrl;
        thumbnailUrl = "";
      }

      _setUploadProgress(
        progress: 0.93,
        text: "Beitrag wird gespeichert...",
      );

      await _postRepo.createPost(
        type: _type == UploadType.video ? "video" : "image",
        title: title,
        categories: _selectedCategories,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        previewUrl: previewUrl,
        fullImageUrl: fullImageUrl,
        user: user,
      );

      _setUploadProgress(
        progress: 1.0,
        text: "Upload abgeschlossen",
      );

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: _type == UploadType.video
              ? "Das Video wurde erfolgreich hochgeladen!"
              : "Das Bild wurde erfolgreich hochgeladen!",
        ),
      );

      return true;
    } catch (e) {
      debugPrint("Fehler beim Upload: $e");

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Upload: ${e.toString()}",
        ),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
          canPop = true;
        });
      }
    }
  }

  void _changeType(UploadType type) {
    setState(() {
      _type = type;
      _selectedCategories = [];

      if (type == UploadType.video) {
        _imageFile = null;
      } else {
        _videoFile = null;
        _disposeVideoControllers();
      }
    });
  }

  Future<void> _selectMedia() async {
    if (_type == UploadType.video) {
      await _pickVideo();
    } else {
      await _pickImage();
    }
  }

  void _setUploadProgress({
    required double progress,
    required String text,
  }) {
    if (!mounted) return;

    setState(() {
      _uploadProgress = progress.clamp(0.0, 1.0);
      _uploadStatusText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),

              _UploadTypeSelector(
                type: _type,
                onVideoTap: () => _changeType(UploadType.video),
                onImageTap: () => _changeType(UploadType.image),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    children: [
                      if (!_isPickingMedia && !_hasSelectedMedia())
                        _MediaPickerCard(
                          type: _type,
                          onTap: _selectMedia,
                        ),

                      if (_isPickingMedia)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),

                      if (_hasSelectedMedia())
                        _SelectedMediaPreview(
                          type: _type,
                          imageFile: _imageFile,
                          videoFile: _videoFile,
                          playerReady: _playerReady,
                          chewieController: _chewieController,
                          onChangeMedia: _selectMedia,
                        ),

                      if (_hasSelectedMedia() &&
                          (_type == UploadType.image ||
                              (_type == UploadType.video && _playerReady)))
                        _UploadFormCard(
                          titleController: titelController,
                          categories: _categories,
                          selectedCategories: _selectedCategories,
                          isUploading: isUploading,
                          uploadProgress: _uploadProgress,
                          uploadStatusText: _uploadStatusText,
                          onCategoriesChanged: (values) {
                            setState(() {
                              _selectedCategories = values;
                            });
                          },
                          onUpload: () async {
                            final ok = await _uploadPost();

                            if (ok && mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTypeSelector extends StatelessWidget {
  final UploadType type;
  final VoidCallback onVideoTap;
  final VoidCallback onImageTap;

  const _UploadTypeSelector({
    required this.type,
    required this.onVideoTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: "Video",
              icon: Icons.videocam_rounded,
              selected: type == UploadType.video,
              onTap: onVideoTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeButton(
              label: "Bild",
              icon: Icons.image_rounded,
              selected: type == UploadType.image,
              onTap: onImageTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? Colors.orange : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? Colors.black : Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaPickerCard extends StatelessWidget {
  final UploadType type;
  final VoidCallback onTap;

  const _MediaPickerCard({
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = type == UploadType.video;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 20, 14, 12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                isVideo
                    ? Icons.video_collection_rounded
                    : Icons.add_photo_alternate_rounded,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isVideo ? "Video auswählen" : "Bild auswählen",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVideo
                  ? "Wähle ein Video aus deiner Galerie aus."
                  : "Wähle ein Bild aus deiner Galerie aus.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isVideo ? "Video öffnen" : "Bild öffnen",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedMediaPreview extends StatelessWidget {
  final UploadType type;
  final File? imageFile;
  final File? videoFile;
  final bool playerReady;
  final ChewieController? chewieController;
  final VoidCallback onChangeMedia;

  const _SelectedMediaPreview({
    required this.type,
    required this.imageFile,
    required this.videoFile,
    required this.playerReady,
    required this.chewieController,
    required this.onChangeMedia,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = type == UploadType.video;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade800),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(
                  isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isVideo ? "Ausgewähltes Video" : "Ausgewähltes Bild",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onChangeMedia,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text("Ändern"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          if (type == UploadType.video && videoFile != null)
            playerReady && chewieController != null
                ? AspectRatio(
              aspectRatio: 16 / 9,
              child: Chewie(controller: chewieController!),
            )
                : const Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          if (type == UploadType.image && imageFile != null)
            Image.file(
              imageFile!,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }
}

class _UploadFormCard extends StatelessWidget {
  final TextEditingController titleController;
  final List<String> categories;
  final List<String> selectedCategories;
  final bool isUploading;
  final ValueChanged<List<String>> onCategoriesChanged;
  final VoidCallback onUpload;
  final double uploadProgress;
  final String uploadStatusText;

  const _UploadFormCard({
    required this.titleController,
    required this.categories,
    required this.selectedCategories,
    required this.isUploading,
    required this.onCategoriesChanged,
    required this.onUpload,
    required this.uploadProgress,
    required this.uploadStatusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          TextInput(
            label: "Titel",
            obscureText: false,
            controller: titleController,
            prefixIcon: const Icon(Icons.title_rounded),
          ),

          const SizedBox(height: 18),

          MultiSelectDialogField<String>(
            initialValue: selectedCategories,
            items: categories
                .map((c) => MultiSelectItem<String>(c, c))
                .toList(),
            title: const Text(
              "Kategorien",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 24,
              ),
            ),
            selectedColor: Colors.orange,
            unselectedColor: Colors.grey,
            backgroundColor: Colors.grey,
            checkColor: Colors.white,
            itemsTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 17,
            ),
            selectedItemsTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 17,
            ),
            cancelText: const Text(
              "Abbrechen",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            confirmText: const Text(
              "Bestätigen",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.shade700,
                width: 1.4,
              ),
            ),
            buttonIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
              size: 28,
            ),
            buttonText: const Text(
              "Kategorien auswählen",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            chipDisplay: MultiSelectChipDisplay(
              chipColor: Colors.grey.shade800,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            onConfirm: (results) {
              onCategoriesChanged(results.cast<String>());
            },
          ),

          const SizedBox(height: 26),

          if (!isUploading)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text("Hochladen"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            _UploadProgressBox(
              progress: uploadProgress,
              text: uploadStatusText,
            ),
        ],
      ),
    );
  }
}

class _UploadProgressBox extends StatelessWidget {
  final double progress;
  final String text;

  const _UploadProgressBox({
    required this.progress,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.isEmpty ? "Upload läuft..." : text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress <= 0 ? null : progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade800,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "$percent %",
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
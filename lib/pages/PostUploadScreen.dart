import 'dart:io';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../models/Meldung.dart';
import '../util/HelperUtil.dart';
import '../widgets/TextInput.dart';

class PostUploadScreen extends StatefulWidget {
  const PostUploadScreen({super.key});

  @override
  State<PostUploadScreen> createState() => _PostUploadScreenState();
}

class _PostUploadScreenState extends State<PostUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  UploadType _type = UploadType.video;

  bool _playerReady = false;
  bool _isPickingMedia = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  File? _videoFile;

  File? _imageFile;

  final TextEditingController titelController = TextEditingController();
  List<String> _selectedCategories = [];
  List<String> _categories = [];

  bool isUploading = false;
  bool canPop = true;
  String errorMessage = "";

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
      setState(() => _playerReady = false);
    }
  }

  Future<void> _fetchCategories() async {
    _categories.clear();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('categorie')
          .get();

      for (final doc in snapshot.docs) {
        _categories.add(doc['categorie'] as String);
      }
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
    setState(() => _isPickingMedia = true);

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
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingMedia = true);

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
        setState(() => _isPickingMedia = false);
      }
    }
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

  Future<Uint8List?> _createImagePreviewBytes(File imageFile) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 900,
        minHeight: 900,
        quality: 72,
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      debugPrint("Fehler beim Erzeugen des Bild-Previews: $e");
      return null;
    }
  }

  Future<String> _uploadFileToStorage({
    required File file,
    required String rootFolder,
    required String userId,
    String? fileName,
  }) async {
    final uniqueId = fileName ?? const Uuid().v4();

    final ref = FirebaseStorage.instance
        .ref()
        .child(rootFolder)
        .child(userId)
        .child(uniqueId);

    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> _uploadBytesToStorage({
    required Uint8List bytes,
    required String rootFolder,
    required String userId,
    required String extension,
  }) async {
    final uniqueId = "${const Uuid().v4()}.$extension";

    final ref = FirebaseStorage.instance
        .ref()
        .child(rootFolder)
        .child(userId)
        .child(uniqueId);

    final metadata = SettableMetadata(
      contentType: extension == 'jpg' || extension == 'jpeg'
          ? 'image/jpeg'
          : 'application/octet-stream',
    );

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  String _buildSearchText({
    required String title,
    required String vorname,
    required String nachname,
    required String benutzername,
    required List<String> categories,
  }) {
    return [
      title,
      vorname,
      nachname,
      "$vorname $nachname",
      benutzername,
      ...categories,
    ].join(" ").toLowerCase().trim();
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
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userSnap.data() ?? {};

      final String title = titelController.text.trim();
      final String vorname = (userData["vorname"] ?? "").toString();
      final String nachname = (userData["nachname"] ?? "").toString();
      final String benutzername = (userData["benutzername"] ?? "").toString();

      String mediaUrl = "";
      String thumbnailUrl = "";
      String previewUrl = "";
      String fullImageUrl = "";

      if (_type == UploadType.video) {
        mediaUrl = await _uploadFileToStorage(
          file: _videoFile!,
          rootFolder: 'videos',
          userId: userId,
        );

        final thumbPath = await _generateThumbnail(_videoFile!.path);
        final thumbFile = File(thumbPath);

        thumbnailUrl = await _uploadFileToStorage(
          file: thumbFile,
          rootFolder: 'thumbnails',
          userId: userId,
        );

        previewUrl = thumbnailUrl;
        fullImageUrl = "";
      } else {
        fullImageUrl = await _uploadFileToStorage(
          file: _imageFile!,
          rootFolder: 'images',
          userId: userId,
        );

        final previewBytes = await _createImagePreviewBytes(_imageFile!);

        if (previewBytes != null) {
          previewUrl = await _uploadBytesToStorage(
            bytes: previewBytes,
            rootFolder: 'image_previews',
            userId: userId,
            extension: 'jpg',
          );
        } else {
          previewUrl = fullImageUrl;
        }

        mediaUrl = fullImageUrl;
        thumbnailUrl = "";
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'type': _type == UploadType.video ? 'video' : 'image',
        'title': title,
        'titleLower': title.toLowerCase().trim(),
        'fullNameLower': "$vorname $nachname".toLowerCase().trim(),
        'searchText': _buildSearchText(
          title: title,
          vorname: vorname,
          nachname: nachname,
          benutzername: benutzername,
          categories: _selectedCategories,
        ),
        'category': _selectedCategories,

        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'previewUrl': previewUrl,
        'fullImageUrl': fullImageUrl,

        'timestamp': Timestamp.now(),
        'views': 0,
        'likes': 0,
        'dislikes': 0,

        'userid': userId,
        'benutzername': benutzername,
        'vorname': vorname,
        'nachname': nachname,
        'profilePictureUrl': userData["profilePictureUrl"] ?? "",
        'role': userData["role"] ?? "USER",
      });

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

  @override
  Widget build(BuildContext context) {
    const headerTitle = "Beitrag hochladen";

    return PopScope(
      canPop: canPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 15,
                    bottom: 15,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            "assets/images/page/upload.png",
                            fit: BoxFit.scaleDown,
                            height: MediaQuery.of(context).size.height * 0.08,
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 6,
                        child: Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Text(
                            headerTitle,
                            style: TextStyle(
                              fontSize: 35,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: "Video",
                          selected: _type == UploadType.video,
                          onTap: () {
                            setState(() {
                              _type = UploadType.video;
                              _imageFile = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeButton(
                          label: "Bild",
                          selected: _type == UploadType.image,
                          onTap: () {
                            setState(() {
                              _type = UploadType.image;
                              _disposeVideoControllers();
                              _videoFile = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        if (!_isPickingMedia && !_hasSelectedMedia())
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: GestureDetector(
                              onTap: () async {
                                if (_type == UploadType.video) {
                                  await _pickVideo();
                                } else {
                                  await _pickImage();
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.orange,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _type == UploadType.video
                                          ? Icons.video_collection
                                          : Icons.image,
                                      size: 30,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _type == UploadType.video
                                          ? "Video auswählen"
                                          : "Bild auswählen",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        if (_isPickingMedia)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),

                        if (_type == UploadType.video && _videoFile != null)
                          Container(
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 20,
                            ),
                            child: _playerReady && _chewieController != null
                                ? AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Chewie(
                                controller: _chewieController!,
                              ),
                            )
                                : const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),

                        if (_type == UploadType.image && _imageFile != null)
                          Container(
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 20,
                            ),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.contain,
                              width: MediaQuery.of(context).size.width * 0.9,
                            ),
                          ),

                        if (_hasSelectedMedia() &&
                            (_type == UploadType.image ||
                                (_type == UploadType.video && _playerReady)))
                          Column(
                            children: [
                              Container(
                                margin:
                                const EdgeInsets.symmetric(horizontal: 15),
                                child: TextInput(
                                  label: "Titel",
                                  obscureText: false,
                                  controller: titelController,
                                  prefixIcon:
                                  const Icon(Icons.title_outlined),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 20,
                                ),
                                child: MultiSelectDialogField(
                                  items: _categories
                                      .map((c) => MultiSelectItem<String>(c, c))
                                      .toList(),
                                  title: const Text(
                                    "Kategorien",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 25,
                                    ),
                                  ),
                                  selectedColor: Colors.orange,
                                  unselectedColor: Colors.amberAccent,
                                  backgroundColor: Colors.grey,
                                  checkColor: Colors.white,
                                  itemsTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  selectedItemsTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  cancelText: const Text(
                                    "Abbrechen",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 15,
                                    ),
                                  ),
                                  confirmText: const Text(
                                    "Bestätigen",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 15,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  buttonIcon: const Icon(
                                    Icons.arrow_drop_down_circle,
                                    color: Colors.white,
                                    size: 30,
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
                                    chipColor: Colors.grey[800],
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  onConfirm: (results) {
                                    setState(() {
                                      _selectedCategories =
                                          results.cast<String>();
                                    });
                                  },
                                ),
                              ),

                              if (!isUploading)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40,
                                    horizontal: 15,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final ok = await _uploadPost();
                                      if (ok && mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        15,
                                        20,
                                        15,
                                      ),
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      "Hochladen",
                                      style: TextStyle(
                                        fontSize: 25,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40,
                                    horizontal: 15,
                                  ),
                                  child: SizedBox(
                                    width:
                                    MediaQuery.of(context).size.width * 0.2,
                                    height:
                                    MediaQuery.of(context).size.width * 0.2,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
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
    );
  }

  bool _hasSelectedMedia() {
    if (_type == UploadType.video) return _videoFile != null;
    return _imageFile != null;
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.orange : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
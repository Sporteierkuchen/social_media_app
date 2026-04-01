
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';

class ProfileHeaderSection extends StatefulWidget {
  final UserDto userdata;
  final UserRepository userRepository;

  const ProfileHeaderSection({
    super.key,
    required this.userdata,
    required this.userRepository,
  });

  @override
  State<ProfileHeaderSection> createState() => _ProfileHeaderSectionState();
}

class _ProfileHeaderSectionState extends State<ProfileHeaderSection> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      height: MediaQuery.of(context).size.height * .50,
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 40),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/page/background.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileImage(),
          const SizedBox(height: 10),
          _buildProfileImageButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(120),
        child: widget.userdata.profilePictureUrl != null
            ? Image.network(
          widget.userdata.profilePictureUrl!,
          fit: BoxFit.cover,
          width: 240,
          height: 240,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              "assets/images/page/empty.png",
              fit: BoxFit.cover,
              width: 240,
              height: 240,
            );
          },
        )
            : Image.asset(
          "assets/images/page/empty.png",
          fit: BoxFit.cover,
          width: 240,
          height: 240,
        ),
      ),
    );
  }

  Widget _buildProfileImageButtons() {
    if (isLoading) {
      return

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
            padding: EdgeInsets.only(top: 10),
            child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 3),
            ),
          ],
        );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Galerie-Button
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 20),
          child: GestureDetector(
            onTap: () async => _pickAndUpload(widget.userdata.userid!, ImageSource.gallery),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.orange),
                  SizedBox(width: 4),
                  Icon(Icons.image_outlined, color: Colors.orange),
                ],
              ),
            ),
          ),
        ),

        // Kamera-Button
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: GestureDetector(
            onTap: () async => _pickAndUpload(widget.userdata.userid!, ImageSource.camera),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.orange),
                  SizedBox(width: 4),
                  Icon(Icons.camera_alt_outlined, color: Colors.orange),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  Future<void> _pickAndUpload(String userId, ImageSource source) async {
    if (isLoading) return;

    final srcName = source == ImageSource.camera ? "Kamera" : "Galerie";
    debugPrint("[ProfileHeaderSection] Start Bild-Upload via $srcName (userId=$userId)");

    setState(() => isLoading = true);

    try {
      final file = await pickImage(source);

      if (file == null) {
        debugPrint("[ProfileHeaderSection] Upload abgebrochen (kein Bild gewählt / crop abgebrochen).");
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.INFO,
            text: "Abgebrochen – kein Bild ausgewählt.",
          ),

        );
        return;
      }

      final ok = await widget.userRepository.uploadProfileImage(file, userId);

      if (!mounted) return;

      if (ok) {
        debugPrint("[ProfileHeaderSection] Upload erfolgreich ✅");
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.SUCCESS,
            text: "Profilbild erfolgreich aktualisiert!",
          ),

        );
      } else {
        debugPrint("[ProfileHeaderSection] Upload fehlgeschlagen ❌ (repo returned false)");
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.ERROR,
            text: "Fehler beim Hochladen des Profilbilds.",
          ),

        );
      }
    } on PlatformException catch (e) {
      debugPrint("[ProfileHeaderSection] PlatformException: $e");
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Zugriff auf $srcName:\n$e",
        ),

      );
    } catch (e) {
      debugPrint("[ProfileHeaderSection] Unerwarteter Fehler: $e");
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Unerwarteter Fehler beim Upload:\n$e",
        ),

      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("[ProfileHeaderSection] Upload-Flow beendet.");
    }
  }

  Future pickImage(ImageSource source) async {
    try {
      debugPrint("[ProfileHeaderSection] pickImage() start (source=$source)");
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) {
        debugPrint("[ProfileHeaderSection] pickImage() -> null (user cancelled)");
        return null;
      }

      final croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile == null) {
        debugPrint("[ProfileHeaderSection] cropImage() -> null (user cancelled)");
        return null;
      }

      debugPrint("[ProfileHeaderSection] Bild gewählt + gecropped ✅");
      return croppedFile;
    } on PlatformException catch (e) {
      debugPrint("[ProfileHeaderSection] Failed to pick image: $e");
      rethrow;
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath) async {
    return ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Zuschneiden',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(minimumAspectRatio: 1.0),
      ],
    );
  }

}

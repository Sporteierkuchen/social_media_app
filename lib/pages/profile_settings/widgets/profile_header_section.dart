import 'package:cached_network_image/cached_network_image.dart';
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
  bool isProfileImageLoading = false;
  bool isBackgroundImageLoading = false;

  bool get _isBusy => isProfileImageLoading || isBackgroundImageLoading;

  String get _backgroundUrl =>
      (widget.userdata.backgroundImageUrl ?? '').trim();

  String get _profileUrl =>
      (widget.userdata.profilePictureUrl ?? '').trim();

  @override
  Widget build(BuildContext context) {
    final double headerHeight = MediaQuery.of(context).size.height * 0.48;
    final double avatarSize = 250;

    return Container(
      color: Colors.black,
      child: SizedBox(
        width: double.infinity,
        height: headerHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: _backgroundUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: _backgroundUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Image.asset(
                  "assets/images/page/background.png",
                  fit: BoxFit.cover,
                ),
                errorWidget: (context, url, error) => Image.asset(
                  "assets/images/page/background.png",
                  fit: BoxFit.cover,
                ),
              )
                  : Image.asset(
                "assets/images/page/background.png",
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.38),
                    ],
                  ),
                ),
              ),
            ),

            // Hintergrundbild-Buttons oben rechts
            Positioned(
              top: 14,
              right: 14,
              child: isBackgroundImageLoading
                  ? Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                    strokeWidth: 2.5,
                  ),
                ),
              )
                  : Wrap(
                spacing: 8,
                children: [
                  _HeaderActionButton(
                    icon: Icons.image_outlined,
                    onTap: _isBusy
                        ? null
                        : () async {
                      await _pickAndUploadBackground(
                        widget.userdata.userid!,
                        ImageSource.gallery,
                      );
                    },
                  ),
                  _HeaderActionButton(
                    icon: Icons.camera_alt_outlined,
                    onTap: _isBusy
                        ? null
                        : () async {
                      await _pickAndUploadBackground(
                        widget.userdata.userid!,
                        ImageSource.camera,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Profilbild + Buttons mittig
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _profileUrl.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: _profileUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Image.asset(
                          "assets/images/page/empty.png",
                          fit: BoxFit.cover,
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          "assets/images/page/empty.png",
                          fit: BoxFit.cover,
                        ),
                      )
                          : Image.asset(
                        "assets/images/page/empty.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (isProfileImageLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeaderActionButton(
                          icon: Icons.image_outlined,
                          onTap: _isBusy
                              ? null
                              : () async => _pickAndUploadProfile(
                            widget.userdata.userid!,
                            ImageSource.gallery,
                          ),
                        ),
                        _HeaderActionButton(
                          icon: Icons.camera_alt_outlined,
                          onTap: _isBusy
                              ? null
                              : () async => _pickAndUploadProfile(
                            widget.userdata.userid!,
                            ImageSource.camera,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadProfile(String userId, ImageSource source) async {
    if (_isBusy) return;

    final srcName = source == ImageSource.camera ? "Kamera" : "Galerie";
    setState(() => isProfileImageLoading = true);

    try {
      final file = await _pickImage(
        source: source,
        cropMode: _CropMode.profile,
      );

      if (file == null) {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.INFO,
            text: "Abgebrochen – kein Bild ausgewählt.",
          ),
        );
        return;
      }

      final ok = await widget.userRepository.uploadProfileImage(file, userId);

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: ok ? Meldungsart.SUCCESS : Meldungsart.ERROR,
          text: ok
              ? "Profilbild erfolgreich aktualisiert!"
              : "Fehler beim Hochladen des Profilbilds.",
        ),
      );
    } on PlatformException catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Zugriff auf $srcName:\n$e",
        ),
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Unerwarteter Fehler beim Upload:\n$e",
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => isProfileImageLoading = false);
    }
  }

  Future<void> _pickAndUploadBackground(
      String userId,
      ImageSource source,
      ) async {
    if (_isBusy) return;

    final srcName = source == ImageSource.camera ? "Kamera" : "Galerie";
    setState(() => isBackgroundImageLoading = true);

    try {
      final file = await _pickImage(
        source: source,
        cropMode: _CropMode.background,
      );

      if (file == null) {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.INFO,
            text: "Abgebrochen – kein Bild ausgewählt.",
          ),
        );
        return;
      }

      final ok =
      await widget.userRepository.uploadBackgroundImage(file, userId);

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: ok ? Meldungsart.SUCCESS : Meldungsart.ERROR,
          text: ok
              ? "Hintergrundbild erfolgreich aktualisiert!"
              : "Fehler beim Hochladen des Hintergrundbilds.",
        ),
      );
    } on PlatformException catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Zugriff auf $srcName:\n$e",
        ),
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Unerwarteter Fehler beim Upload:\n$e",
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => isBackgroundImageLoading = false);
    }
  }

  Future<CroppedFile?> _pickImage({
    required ImageSource source,
    required _CropMode cropMode,
  }) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return null;

    return _cropImage(
      pickedFile.path,
      cropMode: cropMode,
    );
  }

  Future<CroppedFile?> _cropImage(
      String imagePath, {
        required _CropMode cropMode,
      }) async {
    final isProfile = cropMode == _CropMode.profile;

    return ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: isProfile
          ? const CropAspectRatio(ratioX: 1, ratioY: 1)
          : const CropAspectRatio(ratioX: 16, ratioY: 9),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: isProfile
              ? 'Profilbild zuschneiden'
              : 'Hintergrund zuschneiden',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: isProfile
              ? CropAspectRatioPreset.square
              : CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: isProfile
              ? 'Profilbild zuschneiden'
              : 'Hintergrund zuschneiden',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
  }
}

enum _CropMode { profile, background }

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Icon(
            icon,
            color: Colors.orange,
            size: 20,
          ),
        ),
      ),
    );
  }
}
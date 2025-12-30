import 'package:flutter/material.dart';
import '../../../models/UserDto.dart';
import '../../../util/FormatUtil.dart';

class ProfileInfoSection extends StatelessWidget {
  final UserDto userData;

  const ProfileInfoSection({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {

    final timestamp = userData.timestamp;
    final mitgliedSeit = timestamp?.toDate();

    return

      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Benutzername",
              style: TextStyle(fontSize: 16, height: 0, color: Colors.white),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 0),
              child: Text(
                userData.benutzername ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  height: 0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: Text(
                mitgliedSeit != null
                    ? "Mitglied seit ${FormatUtil.formatDate(mitgliedSeit)}"
                    : "",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 0, color: Colors.white),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              "Über ${userData.vorname ?? ''} ${userData.nachname ?? ''}",
              style: const TextStyle(
                fontSize: 20,
                height: 0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 25),
            child: Text(
              userData.beschreibung ?? "",
              style: const TextStyle(fontSize: 16, height: 0, color: Colors.white),
            ),
          ),

          if (userData.strase?.toString().trim().isNotEmpty ?? false)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Text(
                    "Straße:",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 16,
                      height: 0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${userData.strase ?? ''} ${userData.hausnummer ?? ''}",
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 0,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

          (userData.stadt?.toString().trim().isNotEmpty ?? false)
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Text(
                  "Stadt:",
                  style: TextStyle(
                    fontSize: 16,
                    height: 0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  "${userData.plz ?? ''} ${userData.stadt ?? ''}",
                  style: const TextStyle(fontSize: 16, height: 0, color: Colors.white),
                ),
              ),
            ],
          )
              : const SizedBox.shrink(),
        ],
      );

  }

}

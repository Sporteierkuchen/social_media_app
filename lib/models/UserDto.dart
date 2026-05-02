import 'package:cloud_firestore/cloud_firestore.dart';

class UserDto {
  final String? userid;
  final String? benutzername;
  final String? vorname;
  final String? nachname;
  final String? email;
  final String? role;
  final String? beschreibung;
  final String? strase;
  final String? hausnummer;
  final String? plz;
  final String? stadt;
  final String? profilePictureUrl;
  final String? backgroundImageUrl;
  final Timestamp? timestamp;

  // Für Online-Status / Chat-Anzeige
  final bool? isOnline;
  final Timestamp? lastActiveAt;

  UserDto({
    this.userid,
    this.benutzername,
    this.vorname,
    this.nachname,
    this.email,
    this.role,
    this.beschreibung,
    this.strase,
    this.hausnummer,
    this.plz,
    this.stadt,
    this.profilePictureUrl,
    this.backgroundImageUrl,
    this.timestamp,
    this.isOnline,
    this.lastActiveAt,
  });

  factory UserDto.fromMap(Map<String, dynamic> map, {String? id}) {
    return UserDto(
      userid: id ?? map['uid'] as String?,
      benutzername: map['benutzername'] as String?,
      vorname: map['vorname'] as String?,
      nachname: map['nachname'] as String?,
      email: map['email'] as String?,
      role: map['role'] as String?,
      beschreibung: map['beschreibung'] as String?,
      strase: map['strase'] as String?,
      hausnummer: map['hausnummer'] as String?,
      plz: map['plz'] as String?,
      stadt: map['stadt'] as String?,
      profilePictureUrl: map['profilePictureUrl'] as String?,
      backgroundImageUrl: map['backgroundImageUrl'] as String?,
      timestamp: map['timestamp'] as Timestamp?,
      isOnline: map['isOnline'] as bool?,
      lastActiveAt: map['lastActiveAt'] as Timestamp?,
    );
  }

  factory UserDto.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snap,
      ) {
    final data = snap.data() ?? <String, dynamic>{};
    return UserDto.fromMap(data, id: snap.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': userid,
      'benutzername': benutzername,
      'vorname': vorname,
      'nachname': nachname,
      'email': email,
      'role': role,
      'beschreibung': beschreibung,
      'strase': strase,
      'hausnummer': hausnummer,
      'plz': plz,
      'stadt': stadt,
      'profilePictureUrl': profilePictureUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'timestamp': timestamp,
      'isOnline': isOnline,
      'lastActiveAt': lastActiveAt,
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/Meldung.dart';
import '../widgets/Toast.dart';

class HelperUtil {
  HelperUtil._();

  static String formatDateTime(DateTime datetime) {
    return DateFormat('dd.MM.yyyy').format(datetime);
  }

  static int getDifferenceDates(String date) {
    final DateTime now = DateTime.now();
    final DateTime datum = DateTime.parse(date);

    final DateTime nowFormated = DateTime(now.year, now.month, now.day);
    final DateTime datumFormated = DateTime(datum.year, datum.month, datum.day);

    final int difference =
    (nowFormated.difference(datumFormated).inHours / 24).round();

    return difference;
  }

  static String calculateLikePercentage({
    required int likes,
    required int dislikes,
  }) {
    if (likes + dislikes == 0) return '0%';
    final int totalVotes = likes + dislikes;
    final double likePercentage = (likes / totalVotes) * 100;
    return '${likePercentage.toStringAsFixed(1)}%';
  }

  static String getTimeAgo(Timestamp timestamp) {
    timeago.setLocaleMessages('de', timeago.DeMessages());
    final DateTime videoDate = timestamp.toDate();
    return timeago.format(videoDate, locale: 'de');
  }

  static Future<void> getToast({
    required Meldung meldung,
  }) async {
    switch (meldung.meldungsart) {
      case Meldungsart.SUCCESS:
        await showSuccess(
          "Erfolgreich",
          meldung.text,
        );
        break;

      case Meldungsart.INFO:
        await showInfo(
          "Hinweis",
          meldung.text,
        );
        break;

      case Meldungsart.WARNING:
        await showWarning(
          "Eingabe prüfen",
          meldung.text,
        );
        break;

      case Meldungsart.ERROR:
        await showError(
          "Fehler",
          meldung.text,
        );
        break;
    }
  }

  static Widget getUserIcon(String role) {
    if (role.isEmpty) {
      return Container();
    }

    switch (role) {
      case "USER":
        return const Icon(
          Icons.person,
          color: Colors.grey,
          size: 15,
        );
      case "ADMIN":
        return const Icon(
          Icons.check_circle,
          color: Colors.blue,
          size: 25,
        );
      case "OWNER":
        return const Icon(
          Icons.star,
          color: Colors.yellow,
          size: 25,
        );
      case "RESTRICTED-USER":
        return const Icon(
          Icons.warning,
          color: Colors.red,
          size: 20,
        );
      case "MELKER":
        return const Icon(
          Icons.delete,
          color: Colors.pinkAccent,
          size: 20,
        );
      default:
        return Container();
    }
  }
}

enum PostMediaFilter { all, videos, images }

enum UploadType { video, image }
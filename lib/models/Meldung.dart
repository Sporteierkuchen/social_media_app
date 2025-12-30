class Meldung {
  final Meldungsart meldungsart;
  final String text;

  const Meldung({
    required this.meldungsart,
    required this.text,
  });
}

enum Meldungsart {
  INFO,
  SUCCESS,
  WARNING,
  ERROR,
}

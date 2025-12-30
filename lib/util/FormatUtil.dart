import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class FormatUtil {
  static String formatCurrency(Decimal decimal) {
    NumberFormat numberFormat = NumberFormat("#,##0.00", "de_DE");
    return numberFormat.format(decimal.toDouble());
  }

  static String formatDate(DateTime datetime) {
    return DateFormat('dd.MM.yyy').format(datetime);
  }

  static String formatDateTime(DateTime datetime) {

    return DateFormat('dd.MM.yyy HH:mm').format(datetime);
  }

  static String forceSign(num value) {
    if (value > 0) {
      return "+$value";
    } else {
      return "$value";
    }
  }


}

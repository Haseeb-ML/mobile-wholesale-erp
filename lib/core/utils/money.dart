import 'package:intl/intl.dart';

/// Class for exact integer paisa arithmetic and currency display
/// 1 PKR = 100 Paisa
class Money {
  final int paisa;

  const Money(this.paisa);

  static const Money zero = Money(0);

  /// From PKR (double or int)
  factory Money.fromPkr(num pkr) {
    return Money((pkr * 100).round());
  }

  /// To PKR as double
  double get toPkr => paisa / 100.0;

  Money operator +(Money other) => Money(paisa + other.paisa);
  Money operator -(Money other) => Money(paisa - other.paisa);
  Money operator *(num factor) => Money((paisa * factor).round());
  Money operator /(num divisor) => Money((paisa / divisor).round());

  bool operator >(Money other) => paisa > other.paisa;
  bool operator <(Money other) => paisa < other.paisa;
  bool operator >=(Money other) => paisa >= other.paisa;
  bool operator <=(Money other) => paisa <= other.paisa;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && runtimeType == other.runtimeType && paisa == other.paisa;

  @override
  int get hashCode => paisa.hashCode;

  /// Formatted PKR string e.g. "PKR 12,500" or "PKR 12,500.50"
  String format({bool includeSymbol = true, bool forceDecimals = false}) {
    final absPaisa = paisa.abs();
    final isNegative = paisa < 0;
    final pkrVal = absPaisa / 100.0;

    final formatter = NumberFormat("#,##0" + (forceDecimals || absPaisa % 100 != 0 ? ".00" : ""), "en_US");
    final formattedNumber = formatter.format(pkrVal);

    final prefix = isNegative ? "-" : "";
    if (includeSymbol) {
      return "$prefix PKR $formattedNumber".trim();
    }
    return "$prefix$formattedNumber";
  }

  /// Compact formatting e.g. "PKR 1.2M", "PKR 450K"
  String formatCompact() {
    final pkr = toPkr;
    if (pkr.abs() >= 1000000) {
      return "PKR ${(pkr / 1000000).toStringAsFixed(1)}M";
    } else if (pkr.abs() >= 1000) {
      return "PKR ${(pkr / 1000).toStringAsFixed(1)}K";
    }
    return format();
  }

  @override
  String toString() => format();
}

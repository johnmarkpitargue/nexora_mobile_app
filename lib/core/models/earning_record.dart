enum TransactionType { deliveryFee, tip, bonus, cashOut }

class EarningTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime timestamp;
  final TransactionType type;
  final String? relatedOrderId;

  const EarningTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.timestamp,
    required this.type,
    this.relatedOrderId,
  });
}

class DayEarnings {
  final String dayName;
  final double amount;
  final int ordersCount;
  final double hoursWorked;
  final double tipsAmount;
  final String dateLabel;
  final bool isCurrent;

  const DayEarnings({
    required this.dayName,
    required this.amount,
    required this.ordersCount,
    this.hoursWorked = 5.0,
    this.tipsAmount = 80.0,
    this.dateLabel = '',
    this.isCurrent = false,
  });

  double get avgPerHour => hoursWorked > 0 ? (amount / hoursWorked) : 0.0;
}

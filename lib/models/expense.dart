import 'package:im_caxsery/models/expence_category.dart';

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
  });

  final String id;
  final String title;
  final int amount;
  final ExpenseCategory category;

  Expense copyWith({String? title, int? amount, ExpenseCategory? category}) {
    return Expense(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
    );
  }
}

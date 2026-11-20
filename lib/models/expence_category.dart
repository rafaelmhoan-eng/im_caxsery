enum ExpenseCategory {
  food('Սնունդ', '🍔'),
  transport('Տրանսպորտ', '🚌'),
  entertainment('Զվարճանք', '🎮'),
  other('Այլ', '📦');

  const ExpenseCategory(this.label, this.emoji);

  final String label;
  final String emoji;
}

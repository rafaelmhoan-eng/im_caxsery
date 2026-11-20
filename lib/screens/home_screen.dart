import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_caxsery/models/expence_category.dart';

import '../data/expense_data.dart';
import '../models/expense.dart';
import '../widgets/category_filter.dart';
import '../widgets/expense_tile.dart';
import 'edit_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late final List<Expense> _expenses;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _expenses = List<Expense>.from(initialExpenses);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<Expense> get _filteredExpenses {
    if (_selectedCategory == null) return _expenses;
    return _expenses
        .where((expense) => expense.category == _selectedCategory)
        .toList();
  }

  int get _visibleTotal => _filteredExpenses.fold<int>(
    0,
    (total, expense) => total + expense.amount,
  );

  void _addExpense() {
    final title = _titleController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Մուտքագրեք անվանում և դրական ամբողջ գումար։'),
        ),
      );
      return;
    }

    setState(() {
      _expenses.insert(
        0,
        Expense(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          amount: amount,
          category: _selectedCategory ?? ExpenseCategory.food,
        ),
      );
    });
    _titleController.clear();
    _amountController.clear();
    FocusScope.of(context).unfocus();
  }

  void _deleteExpense(Expense expense, int originalIndex) {
    setState(() => _expenses.removeWhere((item) => item.id == expense.id));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${expense.title}» ծախսը ջնջվեց։'),
        action: SnackBarAction(
          label: 'Վերադարձնել',
          onPressed: () {
            setState(() {
              final safeIndex = originalIndex.clamp(0, _expenses.length);
              _expenses.insert(safeIndex, expense);
            });
          },
        ),
      ),
    );
  }

  Future<void> _openEditPage(Expense expense) async {
    final updatedAmount = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => EditExpenseScreen(expense: expense)),
    );

    if (updatedAmount == null || !mounted) return;
    setState(() {
      final index = _expenses.indexWhere((item) => item.id == expense.id);
      if (index != -1) {
        _expenses[index] = _expenses[index].copyWith(amount: updatedAmount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleExpenses = _filteredExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ընդամենը՝ $_visibleTotal դր.'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Անվանում',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Գումար',
                      suffixText: 'դր.',
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: ExpenseCategory.values.map((category) {
                        final selected =
                            (_selectedCategory ?? ExpenseCategory.food) ==
                            category;
                        return ChoiceChip(
                          label: Text('${category.emoji} ${category.label}'),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addExpense,
                      icon: const Icon(Icons.add),
                      label: const Text('Ավելացնել'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: CategoryFilter(
                selectedCategory: _selectedCategory,
                onSelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
            ),
            Expanded(
              child: visibleExpenses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedCategory == null
                                  ? 'Դեռ ծախսեր չկան։ Ավելացրեք առաջինը։'
                                  : 'Այս բաժնում ծախսեր չկան։',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: visibleExpenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final expense = visibleExpenses[index];
                        final originalIndex = _expenses.indexWhere(
                          (item) => item.id == expense.id,
                        );

                        return Dismissible(
                          key: ValueKey(expense.id),
                          direction: DismissDirection.horizontal,
                          background: _dismissBackground(
                            Alignment.centerLeft,
                            Icons.delete_outline,
                          ),
                          secondaryBackground: _dismissBackground(
                            Alignment.centerRight,
                            Icons.delete_outline,
                          ),
                          onDismissed: (_) =>
                              _deleteExpense(expense, originalIndex),
                          child: ExpenseTile(
                            expense: expense,
                            onTap: () => _openEditPage(expense),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dismissBackground(Alignment alignment, IconData icon) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.red.shade800),
    );
  }
}

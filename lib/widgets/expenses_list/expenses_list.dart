import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/expenses_list/expense_item.dart';
import 'package:flutter/material.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList({
    super.key,
    required this.expenses,
    required this.onRemoveExpense,
    required this.onEditExpenseTap,
  });

  final List<Expense> expenses;
  final void Function(Expense expense) onRemoveExpense;
  final void Function(Expense expense, int index) onEditExpenseTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (ctx, index) {
        return Dismissible(
          key: ValueKey(expenses[index].id),
          direction: DismissDirection.horizontal,
          background: Container(
            color: Colors.blueAccent,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.edit, color: Colors.white, size: 40),
          ),
          secondaryBackground: Container(
            color: Theme.of(context).colorScheme.error.withOpacity(0.75),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 40),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              onEditExpenseTap(expenses[index], index);
              return false;
            } else if (direction == DismissDirection.endToStart) {
              return true;
            }
            return false;
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              onRemoveExpense(expenses[index]);
            }
          },
          child: ExpenseItem(expenses[index]),
        );
      },
    );
  }
}

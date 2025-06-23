import 'dart:convert';
import 'package:expense_tracker/widgets/chart/chart.dart';
import 'package:expense_tracker/widgets/expenses_list/expenses_list.dart';
import 'package:expense_tracker/widgets/new_expense.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  List<Expense> _registeredExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpensesFromStorage();
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(onAddExpense: _addExpense),
    );
  }

  void _openEditExpenseOverlay(Expense expense, int index) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder:
          (ctx) => NewExpense(
            existingExpense: expense,
            existingIndex: index,
            onAddExpense: _addExpense,
            onEditExpense: _editExpense,
          ),
    );
  }

  void _addExpense(Expense expense) async {
    setState(() {
      _registeredExpenses.add(expense);
    });
    await _saveExpensesToStorage();
  }

  void _editExpense(Expense updatedExpense, int index) async {
    setState(() {
      _registeredExpenses[index] = updatedExpense;
    });
    await _saveExpensesToStorage();
  }

  void _removeExpense(Expense expense) async {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    setState(() {
      _registeredExpenses.remove(expense);
    });
    await _saveExpensesToStorage();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Expense deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            setState(() {
              _registeredExpenses.insert(expenseIndex, expense);
            });
            await _saveExpensesToStorage();
          },
        ),
      ),
    );
  }

  Future<void> _saveExpensesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedExpenses =
        _registeredExpenses.map((expense) {
          return jsonEncode({
            'id': expense.id, // now storing id
            'title': expense.title,
            'amount': expense.amount,
            'date': expense.date.toIso8601String(),
            'category': expense.category.name,
          });
        }).toList();
    await prefs.setStringList('expenses', encodedExpenses);
  }

  Future<void> _loadExpensesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encodedExpenses = prefs.getStringList('expenses');
    if (encodedExpenses != null) {
      setState(() {
        _registeredExpenses =
            encodedExpenses.map((str) {
              final json = jsonDecode(str);
              return Expense(
                id: json['id'], // load id
                title: json['title'],
                amount: json['amount'],
                date: DateTime.parse(json['date']),
                category: Category.values.firstWhere(
                  (e) => e.name == json['category'],
                ),
              );
            }).toList();
      });
    }
  }

  double get _totalExpense {
    return _registeredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    Widget mainContent = const Center(child: Text('No expenses found.'));
    if (_registeredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _registeredExpenses,
        onRemoveExpense: _removeExpense,
        onEditExpenseTap: _openEditExpenseOverlay, // pass edit callback
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      body:
          width < 600
              ? Column(
                children: [
                  Chart(expenses: _registeredExpenses),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Total: \$${_totalExpense.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: mainContent),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Chart(expenses: _registeredExpenses),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Total: \$${_totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: mainContent),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseOverlay,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

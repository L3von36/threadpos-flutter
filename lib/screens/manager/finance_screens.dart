import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

// ---------------------------------------------------------------------------
// Expenses
// ---------------------------------------------------------------------------

const List<String> expenseCategories = <String>[
  'Rent',
  'Salaries',
  'Utilities',
  'Supplies',
  'Marketing',
  'Maintenance',
  'Packaging',
  'Delivery',
  'Bank fees',
  'Taxes & licenses',
  'Equipment',
  'Other',
];

IconData expenseCategoryIcon(String category) => switch (category) {
      'Rent' => Icons.storefront,
      'Salaries' => Icons.badge_outlined,
      'Utilities' => Icons.bolt,
      'Supplies' => Icons.inventory_2_outlined,
      'Marketing' => Icons.campaign_outlined,
      'Maintenance' => Icons.handyman_outlined,
      'Packaging' => Icons.redeem_outlined,
      'Delivery' => Icons.local_shipping_outlined,
      'Bank fees' => Icons.account_balance_outlined,
      'Taxes & licenses' => Icons.receipt_long_outlined,
      'Equipment' => Icons.weekend_outlined,
      _ => Icons.category_outlined,
    };

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<Expense> all = store.expenses;
    final List<Expense> visible = _category == null
        ? all
        : all.where((Expense e) => e.category == _category).toList();
    final double total = visible.fold(0.0, (double s, Expense e) => s + e.amount);
    final double monthTotal =
        store.expensesTotalFor(SalesRange.d30);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseSheet(context),
        backgroundColor: pal.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Log expense',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: StaggerIn(
              index: 0,
              dy: 8,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: pal.bannerBg,
                  borderRadius: BorderRadius.circular(AppTheme.rLg),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('SPENT · LAST 30 DAYS',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w700,
                                  color: pal.bannerSub)),
                          const SizedBox(height: 4),
                          CountUpText(
                            monthTotal,
                            style: TextStyle(
                                fontSize: 21,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                                color: pal.bannerText),
                            formatter: money,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${all.length} entries',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: pal.bannerText)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                _catChip(context, null, 'All'),
                for (final String c in expenseCategories)
                  _catChip(context, c, c),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nothing logged',
                    subtitle:
                        'No expenses match this view yet.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      final Expense e = visible[i];
                      return StaggerIn(
                        index: i,
                        child: PressableScale(
                          onTap: () => _showDetail(context, e),
                          pressedScale: 0.97,
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: pal.surface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.rMd),
                              border: Border.all(color: pal.border),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: pal.accent
                                        .withValues(alpha: 0.11),
                                    borderRadius:
                                        BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                      expenseCategoryIcon(e.category),
                                      size: 16,
                                      color: pal.accent),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(e.title,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight:
                                                  FontWeight.w700,
                                              color: pal.ink)),
                                      Text(
                                          '${e.category} · ${e.branch}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: pal.muted)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text('-${money(e.amount)}',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: pal.danger)),
                                    Text(shortDate(e.time),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: pal.muted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _catChip(BuildContext context, String? value, String label) {
    final Pal pal = Pal.of(context);
    final bool selected = _category == value;
    return PressableScale(
      onTap: () => setState(() => _category = value),
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? pal.accent : pal.surface,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: selected ? pal.accent : pal.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : pal.ink)),
      ),
    );
  }

  void _showDetail(BuildContext context, Expense e) {
    final Pal pal = Pal.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: pal.accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(expenseCategoryIcon(e.category),
                        size: 17, color: pal.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: pal.ink)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _row(context, 'Category', e.category),
              _row(context, 'Amount', money(e.amount)),
              _row(context, 'Branch', e.branch),
              _row(context, 'Date', shortDate(e.time)),
              if (e.note.isNotEmpty) _row(context, 'Note', e.note),
              const SizedBox(height: 14),
              PressableScale(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: pal.danger.withValues(alpha: 0.6)),
                    foregroundColor: pal.danger,
                  ),
                  onPressed: () {
                    context.read<Store>().removeExpense(e.id);
                    Navigator.of(sheetContext).pop();
                    showSnack(context, 'Expense deleted');
                  },
                  child: const Text('Delete entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final Pal pal = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
              width: 84,
              child: Text(label,
                  style: TextStyle(fontSize: 12, color: pal.muted))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: pal.ink)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-expense sheet
// ---------------------------------------------------------------------------

void _showExpenseSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: const _ExpenseFormSheet(),
    ),
  );
}

class _ExpenseFormSheet extends StatefulWidget {
  const _ExpenseFormSheet();

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String _category = expenseCategories.first;
  String _branch = Store.locations.first;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Store store = context.read<Store>();
    store.addExpense(Expense(
      id: 'x${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      category: _category,
      amount: double.tryParse(_amount.text.trim()) ?? 0,
      time: DateTime.now(),
      branch: _branch,
      note: _note.text.trim(),
      recordedBy: store.email.isEmpty ? 'manager' : store.email,
    ));
    Navigator.of(context).pop();
    showSnack(context, 'Expense logged');
  }

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text('Log an expense',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: pal.ink)),
                  const Spacer(),
                  PressableScale(
                    onTap: () => Navigator.of(context).pop(),
                    pressedScale: 0.85,
                    child:
                        Icon(Icons.close, size: 18, color: pal.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: AppTheme.input(context, 'What was paid for?',
                    icon: Icons.receipt_long,
                    hint: 'e.g. December store rent'),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Enter a description'
                        : null,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: AppTheme.input(context, 'Amount (ETB)',
                          icon: Icons.payments_outlined),
                      validator: (String? v) {
                        final double? p = double.tryParse(v ?? '');
                        if (p == null || p <= 0) {
                          return 'Enter an amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _branch,
                      decoration: AppTheme.input(context, 'Branch',
                          icon: Icons.store_outlined),
                      items: Store.locations
                          .map((String l) => DropdownMenuItem<String>(
                              value: l,
                              child: Text(l,
                                  style: TextStyle(fontSize: 12.5))))
                          .toList(),
                      onChanged: (String? v) =>
                          setState(() => _branch = v ?? _branch),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Category',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: pal.ink)),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: expenseCategories
                    .map((String c) => ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (bool _) =>
                              setState(() => _category = c),
                          selectedColor: pal.accent,
                          backgroundColor: pal.surface,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                              color: _category == c
                                  ? Colors.white
                                  : pal.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(color: pal.border),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _note,
                decoration: AppTheme.input(context, 'Note (optional)',
                    icon: Icons.notes),
              ),
              const SizedBox(height: 16),
              PressableScale(
                child: FilledButton(
                  style: AppTheme.primaryButton(context),
                  onPressed: _submit,
                  child: const Text('Save expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Income
// ---------------------------------------------------------------------------

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  SalesRange _range = SalesRange.today;

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final double salesRevenue =
        store.revenueFor(store.salesForRange(_range));
    final double otherIncome = store.otherIncomeFor(_range);
    final double totalIncome = salesRevenue + otherIncome;
    final double expenses = store.expensesTotalFor(_range);
    final double net = totalIncome - expenses;
    final List<IncomeEntry> entries = store.incomes;

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIncomeSheet(context),
        backgroundColor: pal.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add income',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('P&L snapshot',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: pal.ink)),
              _IncomeRangeTabs(
                value: _range,
                onChanged: (SalesRange r) => setState(() => _range = r),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StaggerIn(
            index: 0,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: pal.bannerBg,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('TOTAL INCOME · ${_range.label.toUpperCase()}',
                      style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: pal.bannerSub)),
                  const SizedBox(height: 5),
                  CountUpText(
                    totalIncome,
                    style: TextStyle(
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: pal.bannerText),
                    formatter: money,
                  ),
                  const SizedBox(height: 6),
                  Text(
                      'POS sales ${money(salesRevenue)} · other ${money(otherIncome)}',
                      style: TextStyle(
                          fontSize: 11.5, color: pal.bannerSub)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          StaggerIn(
            index: 1,
            dy: 8,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                      label: 'POS sales',
                      value: money(salesRevenue),
                      icon: Icons.point_of_sale),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Other income',
                      value: money(otherIncome),
                      icon: Icons.savings_outlined,
                      color: pal.sage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          StaggerIn(
            index: 2,
            dy: 8,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                      label: 'Expenses',
                      value: '-${money(expenses)}',
                      icon: Icons.receipt_long,
                      color: pal.danger),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Net ${_range.label.toLowerCase()}',
                      value: money(net),
                      icon: net >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: net >= 0 ? pal.sage : pal.danger),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Other income entries'),
          if (entries.isEmpty)
            Text(
                'Alterations, consignment payouts and wholesale orders go here.',
                style: TextStyle(fontSize: 12, color: pal.muted))
          else
            ...entries
                .asMap()
                .entries
                .map((MapEntry<int, IncomeEntry> entry) {
              final IncomeEntry e = entry.value;
              return StaggerIn(
                index: 3 + entry.key,
                dy: 6,
                child: PressableScale(
                  onTap: () {
                    context.read<Store>().removeIncome(e.id);
                    showSnack(context, 'Entry removed');
                  },
                  pressedScale: 0.97,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: pal.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(color: pal.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                pal.sage.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(Icons.savings_outlined,
                              size: 16, color: pal.sage),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: pal.ink)),
                              Text(
                                  '${e.source} · ${e.branch} · ${shortDate(e.time)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: pal.muted)),
                            ],
                          ),
                        ),
                        Text('+${money(e.amount)}',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: pal.sage)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Tap an entry to remove it.',
                  style: TextStyle(fontSize: 10.5, color: pal.muted)),
            ),
        ],
      ),
    );
  }
}

void _showIncomeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: const _IncomeFormSheet(),
    ),
  );
}

class _IncomeFormSheet extends StatefulWidget {
  const _IncomeFormSheet();

  @override
  State<_IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<_IncomeFormSheet> {
  static const List<String> _sources = <String>[
    'Alterations',
    'Consignment',
    'Wholesale',
    'Gift cards',
    'Online orders',
    'Pop-up events',
    'Other',
  ];

  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  String _source = _sources.first;
  String _branch = Store.locations.first;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Store store = context.read<Store>();
    store.addIncome(IncomeEntry(
      id: 'i${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      source: _source,
      amount: double.tryParse(_amount.text.trim()) ?? 0,
      time: DateTime.now(),
      branch: _branch,
      recordedBy: store.email.isEmpty ? 'manager' : store.email,
    ));
    Navigator.of(context).pop();
    showSnack(context, 'Income recorded');
  }

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text('Record other income',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: pal.ink)),
                  const Spacer(),
                  PressableScale(
                    onTap: () => Navigator.of(context).pop(),
                    pressedScale: 0.85,
                    child:
                        Icon(Icons.close, size: 18, color: pal.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: AppTheme.input(context, 'Description',
                    icon: Icons.savings_outlined,
                    hint: 'e.g. Bridal party alterations'),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Enter a description'
                        : null,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: AppTheme.input(context, 'Amount (ETB)',
                          icon: Icons.payments_outlined),
                      validator: (String? v) {
                        final double? p = double.tryParse(v ?? '');
                        if (p == null || p <= 0) {
                          return 'Enter an amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _branch,
                      decoration: AppTheme.input(context, 'Branch',
                          icon: Icons.store_outlined),
                      items: Store.locations
                          .map((String l) => DropdownMenuItem<String>(
                              value: l,
                              child: Text(l,
                                  style: TextStyle(fontSize: 12.5))))
                          .toList(),
                      onChanged: (String? v) =>
                          setState(() => _branch = v ?? _branch),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Source',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: pal.ink)),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: _sources
                    .map((String s) => ChoiceChip(
                          label: Text(s),
                          selected: _source == s,
                          onSelected: (bool _) =>
                              setState(() => _source = s),
                          selectedColor: pal.accent,
                          backgroundColor: pal.surface,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                              color: _source == s
                                  ? Colors.white
                                  : pal.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(color: pal.border),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              PressableScale(
                child: FilledButton(
                  style: AppTheme.primaryButton(context),
                  onPressed: _submit,
                  child: const Text('Save income'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeRangeTabs extends StatelessWidget {
  const _IncomeRangeTabs({required this.value, required this.onChanged});

  final SalesRange value;
  final ValueChanged<SalesRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: pal.surfaceAlt.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SalesRange.values
            .map((SalesRange r) => PressableScale(
                  onTap: () => onChanged(r),
                  pressedScale: 0.94,
                  child: AnimatedContainer(
                    duration: Motion.base,
                    curve: Motion.out,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: value == r ? pal.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(r.label,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: value == r
                                ? Colors.white
                                : pal.muted)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

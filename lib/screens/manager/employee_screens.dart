import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

// ---------------------------------------------------------------------------
// Employees — full roster management
// ---------------------------------------------------------------------------

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _query = '';
  EmployeeStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);

    final List<Employee> roster = store.employees
        .where((Employee e) =>
            _filter == null || e.status == _filter)
        .where((Employee e) =>
            _query.isEmpty ||
            e.name.toLowerCase().contains(_query) ||
            e.title.toLowerCase().contains(_query) ||
            e.branch.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEmployeeForm(context),
        backgroundColor: pal.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt, size: 18),
        label: const Text('Add employee',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              onChanged: (String v) => setState(() => _query = v.toLowerCase()),
              decoration: AppTheme.input(context, 'Search team',
                  icon: Icons.search, hint: 'Name, role or branch'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                _filterChip(context, null, 'All'),
                _filterChip(context, EmployeeStatus.active, 'Active'),
                _filterChip(context, EmployeeStatus.onLeave, 'On leave'),
                _filterChip(context, EmployeeStatus.inactive, 'Inactive'),
              ],
            ),
          ),
          Expanded(
            child: roster.isEmpty
                ? const EmptyState(
                    icon: Icons.group_off_outlined,
                    title: 'No one found',
                    subtitle:
                        'Try a different search or filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: roster.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      final Employee e = roster[i];
                      return StaggerIn(
                        index: i,
                        child: PressableScale(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    EmployeeDetailScreen(employeeId: e.id)),
                          ),
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
                                PopIn(
                                  begin: 0.6,
                                  duration: Motion.base,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: pal.accent
                                            .withValues(alpha: 0.12),
                                        child: Text(
                                            e.initial.toUpperCase(),
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: pal.accent)),
                                      ),
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: e.status ==
                                                    EmployeeStatus.active
                                                ? pal.sage
                                                : (e.status ==
                                                        EmployeeStatus.onLeave
                                                    ? pal.amber
                                                    : pal.muted),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: pal.surface,
                                                width: 1.4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(e.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                              color: pal.ink)),
                                      Text(
                                          '${e.title} · ${e.branch}',
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              color: pal.muted)),
                                      const SizedBox(height: 2),
                                      Text(e.shift,
                                          style: TextStyle(
                                              fontSize: 10.5,
                                              color: pal.muted)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(money(e.todaySales),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: pal.ink)),
                                    Text('${e.orders} orders',
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            color: pal.sage)),
                                    const SizedBox(height: 3),
                                    StockBadge(
                                      label: employeeStatusLabel(e.status),
                                      color: e.status ==
                                              EmployeeStatus.active
                                          ? pal.sage
                                          : (e.status ==
                                                  EmployeeStatus.onLeave
                                              ? pal.amber
                                              : pal.muted),
                                    ),
                                  ],
                                ),
                                Icon(Icons.chevron_right,
                                    size: 17, color: pal.muted),
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

  Widget _filterChip(BuildContext context, EmployeeStatus? value, String label) {
    final Pal pal = Pal.of(context);
    final bool selected = _filter == value;
    return PressableScale(
      onTap: () => setState(() => _filter = value),
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? pal.accent : pal.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? pal.accent : pal.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : pal.ink)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / edit form — used by both the roster FAB and the detail screen
// ---------------------------------------------------------------------------

Future<void> showEmployeeForm(BuildContext context, {Employee? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _EmployeeFormSheet(existing: existing),
    ),
  );
}

class _EmployeeFormSheet extends StatefulWidget {
  const _EmployeeFormSheet({this.existing});

  final Employee? existing;

  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? 'Stylist');
  late final TextEditingController _shift = TextEditingController(
      text: widget.existing?.shift ?? 'Mon - Fri · 9:00 - 17:00');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _pin =
      TextEditingController(text: widget.existing?.pin ?? '1234');
  late String _branch =
      widget.existing?.branch ?? Store.locations.first;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _shift.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Store store = context.read<Store>();
    final bool editing = widget.existing != null;
    final Employee employee = (editing
            ? widget.existing!
            : Employee(
                id: 'e${DateTime.now().millisecondsSinceEpoch}',
                name: '',
                title: '',
                branch: '',
                shift: '',
                todaySales: 0,
              ))
        .copyWith(
      name: _name.text.trim(),
      title: _title.text.trim(),
      branch: _branch,
      shift: _shift.text.trim(),
      phone: _phone.text.trim(),
      pin: _pin.text.trim(),
    );
    if (editing) {
      store.updateEmployee(employee);
    } else {
      store.addEmployee(employee);
    }
    Navigator.of(context).pop();
    showSnack(context,
        '${employee.name} ${editing ? 'updated' : 'added to the team'}');
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
                  Text(
                      widget.existing == null
                          ? 'Add employee'
                          : 'Edit ${widget.existing!.name.split(' ').first}',
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
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration:
                    AppTheme.input(context, 'Full name', icon: Icons.person),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                decoration: AppTheme.input(context, 'Role title',
                    icon: Icons.badge_outlined),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a role' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _branch,
                decoration: AppTheme.input(context, 'Branch',
                    icon: Icons.store_outlined),
                items: Store.locations
                    .map((String l) => DropdownMenuItem<String>(
                        value: l, child: Text(l, style: TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (String? v) =>
                    setState(() => _branch = v ?? _branch),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _shift,
                decoration: AppTheme.input(context, 'Shift',
                    icon: Icons.schedule, hint: 'Mon - Fri · 9:00 - 17:00'),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: AppTheme.input(context, 'Phone',
                          icon: Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 108,
                    child: TextFormField(
                      controller: _pin,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration:
                          AppTheme.input(context, 'PIN', icon: Icons.pin),
                      validator: (String? v) =>
                          (v == null || v.trim().length != 4)
                              ? '4 digits'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PressableScale(
                child: FilledButton(
                  style: AppTheme.primaryButton(context),
                  onPressed: _submit,
                  child: Text(widget.existing == null
                      ? 'Add to team'
                      : 'Save changes'),
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
// Employee detail — profile, live stats, commission, management actions
// ---------------------------------------------------------------------------

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key, required this.employeeId});

  final String employeeId;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  double _rate = 3;
  bool _rateInit = false;

  static const List<double> _rates = <double>[3, 5, 7, 10];

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    if (!_rateInit) {
      _rate = store.commissionRate;
      _rateInit = true;
    }
    final Employee? maybe = store.employeeById(widget.employeeId);
    if (maybe == null) {
      // Roster entry was removed while the detail screen was open.
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Employee removed',
          subtitle: 'This team member is no longer on the roster.',
        ),
      );
    }
    final Employee e = maybe;
    final List<Sale> recent =
        store.salesForSeller(e.firstName, SalesRange.today);
    final double liveRevenue = store.revenueFor(recent);

    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          StaggerIn(
            index: 0,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surface,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                border: Border.all(color: pal.border),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      PopIn(
                        begin: 0.6,
                        duration: Motion.base,
                        child: CircleAvatar(
                          radius: 21,
                          backgroundColor:
                              pal.accent.withValues(alpha: 0.12),
                          child: Text(e.initial.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: pal.accent)),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(e.title,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: pal.ink)),
                            Text('${e.branch} · ${e.shift}',
                                style: TextStyle(
                                    fontSize: 11, color: pal.muted)),
                            if (e.phone.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(e.phone,
                                  style: TextStyle(
                                      fontSize: 11, color: pal.muted)),
                            ],
                          ],
                        ),
                      ),
                      StockBadge(
                        label: employeeStatusLabel(e.status),
                        color: e.status == EmployeeStatus.active
                            ? pal.sage
                            : (e.status == EmployeeStatus.onLeave
                                ? pal.amber
                                : pal.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: PressableScale(
                          onTap: () => showEmployeeForm(context,
                              existing: e),
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: pal.softAccent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('Edit profile',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: pal.accent)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PressableScale(
                          onTap: () => _confirmRemove(context, e),
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color:
                                      pal.danger.withValues(alpha: 0.5)),
                            ),
                            child: Text('Remove',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: pal.danger)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Status'),
          StaggerIn(
            index: 1,
            dy: 8,
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: EmployeeStatus.values
                  .map((EmployeeStatus s) => PressableScale(
                        onTap: () => store.updateEmployee(
                            e.copyWith(status: s)),
                        pressedScale: 0.92,
                        child: AnimatedContainer(
                          duration: Motion.base,
                          curve: Motion.out,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 6),
                          decoration: BoxDecoration(
                            color: e.status == s
                                ? pal.accent
                                : pal.surfaceAlt.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(employeeStatusLabel(s),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: e.status == s
                                      ? Colors.white
                                      : pal.ink)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SectionHeader(title: 'Today at a glance'),
          StaggerIn(
            index: 2,
            dy: 8,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                      label: 'Recorded sales',
                      value: money(e.todaySales),
                      icon: Icons.payments_outlined),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Orders',
                      value: '${e.orders}',
                      icon: Icons.receipt_long,
                      color: pal.sage),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Conversion',
                      value: '${e.conversion}%',
                      icon: Icons.percent,
                      color: pal.amber),
                ),
              ],
            ),
          ),
          if (recent.isNotEmpty) ...<Widget>[
            const SectionHeader(title: 'Live sales today'),
            StaggerIn(
              index: 3,
              dy: 8,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pal.surfaceAlt.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.bolt, size: 16, color: pal.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          '${recent.length} sales closed · ${money(liveRevenue)} live',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SectionHeader(title: 'Commission calculator'),
          StaggerIn(
            index: 4,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surface,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                border: Border.all(color: pal.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Commission rate',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: pal.ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _rates
                        .map((double r) => PressableScale(
                              onTap: () {
                                setState(() => _rate = r);
                                context
                                    .read<Store>()
                                    .setCommissionRate(r);
                              },
                              pressedScale: 0.92,
                              child: AnimatedContainer(
                                duration: Motion.base,
                                curve: Motion.out,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _rate == r
                                      ? pal.accent
                                      : pal.surfaceAlt
                                          .withValues(alpha: 0.5),
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: Text('${r.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _rate == r
                                            ? Colors.white
                                            : pal.ink)),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('${_rate.toStringAsFixed(0)}% of net sales',
                          style: TextStyle(
                              fontSize: 12, color: pal.muted)),
                      CountUpText(
                        e.commissionAt(_rate),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: pal.sage),
                        formatter: money,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Team at a glance'),
          ...store.employees
              .where((Employee other) => other.id != e.id)
              .toList()
              .asMap()
              .entries
              .map((MapEntry<int, Employee> entry) => StaggerIn(
                    index: 5 + entry.key,
                    dy: 6,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: pal.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.rMd),
                        border: Border.all(color: pal.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: pal.surfaceAlt,
                            child: Text(
                                entry.value.initial.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: pal.ink)),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(entry.value.name,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: pal.ink)),
                          ),
                          Text(money(entry.value.todaySales),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: pal.muted)),
                        ],
                      ),
                    ),
                  )),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, Employee e) {
    final Pal pal = Pal.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.rLg)),
        title: Text('Remove ${e.name.split(' ').first}?',
            style: const TextStyle(fontSize: 16)),
        content: Text(
            'They will lose register access. Their sales history stays in the log.',
            style: TextStyle(fontSize: 12.5, color: pal.muted)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: pal.danger,
                foregroundColor: Colors.white),
            onPressed: () {
              context.read<Store>().removeEmployee(e.id);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
              showSnack(context, '${e.name} removed from the roster');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

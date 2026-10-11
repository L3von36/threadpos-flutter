import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// Comprehensive Visual Analytics screen for Manager dashboard.
/// Features interactive Bar Charts for daily sales revenue and top-selling items.
class VisualAnalyticsScreen extends StatefulWidget {
  const VisualAnalyticsScreen({super.key});

  @override
  State<VisualAnalyticsScreen> createState() => _VisualAnalyticsScreenState();
}

enum _AnalyticsRange {
  today('Today', 1),
  d7('7 Days', 7),
  d14('14 Days', 14),
  d30('30 Days', 30),
  custom('Custom', 0);

  const _AnalyticsRange(this.label, this.days);
  final String label;
  final int days;
}

enum _TopMetric {
  units('Units Sold'),
  revenue('Revenue (ETB)');

  const _TopMetric(this.label);
  final String label;
}

class _VisualAnalyticsScreenState extends State<VisualAnalyticsScreen> {
  _AnalyticsRange _range = _AnalyticsRange.d7;
  _TopMetric _topMetric = _TopMetric.revenue;
  DateTimeRange? _customDateRange;
  int? _touchedRevenueBarIndex;
  int? _touchedTopProductBarIndex;

  Future<void> _pickCustomRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          ),
      builder: (BuildContext context, Widget? child) {
        final Pal pal = Pal.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: pal.accent,
              onPrimary: Colors.white,
              surface: pal.surface,
              onSurface: pal.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _range = _AnalyticsRange.custom;
        _customDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);

    // Filter sales for the selected timeframe
    final List<Sale> selectedSales = _getSalesForRange(store);
    final double totalRevenue = store.revenueFor(selectedSales);
    final int totalUnits = store.itemsFor(selectedSales);
    final int totalOrders = selectedSales.length;

    // Daily breakdown for revenue bar chart
    final List<DailySalesStat> dailyStats = _computeDailyStats(store);
    final double maxRevenue = dailyStats.isEmpty
        ? 1000
        : dailyStats.map((DailySalesStat e) => e.revenue).reduce(
            (double a, double b) => a > b ? a : b);
    final double avgDailyRevenue = dailyStats.isEmpty
        ? 0
        : totalRevenue / dailyStats.length;

    // Top selling items
    final List<TopProduct> topProducts = store.topProductsByMetric(
      selectedSales,
      byRevenue: _topMetric == _TopMetric.revenue,
      limit: 6,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Analytics'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Date range picker',
            icon: const Icon(Icons.date_range_outlined, size: 20),
            onPressed: () => _pickCustomRange(context),
          ),
          IconButton(
            tooltip: 'Refresh analytics',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              store.syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics updated')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: <Widget>[
          // Header description
          Text(
            'MANAGER CONTROL · VISUAL REVENUE & PRODUCTS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: pal.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Performance Dashboard',
            style: AppTheme.pageTitle(context),
          ),
          const SizedBox(height: 10),

          // Time Range Selector Pill Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final _AnalyticsRange r in _AnalyticsRange.values)
                  if (r != _AnalyticsRange.custom || _customDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          r == _AnalyticsRange.custom && _customDateRange != null
                              ? '${_customDateRange!.start.month}/${_customDateRange!.start.day} - ${_customDateRange!.end.month}/${_customDateRange!.end.day}'
                              : r.label,
                        ),
                        selected: _range == r,
                        onSelected: (bool selected) {
                          if (selected) {
                            if (r == _AnalyticsRange.custom) {
                              _pickCustomRange(context);
                            } else {
                              setState(() {
                                _range = r;
                                _customDateRange = null;
                              });
                            }
                          }
                        },
                        selectedColor: pal.accent,
                        backgroundColor: pal.surface,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: _range == r ? Colors.white : pal.ink,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: _range == r ? pal.accent : pal.border,
                          ),
                        ),
                      ),
                    ),
                if (_customDateRange == null)
                  ActionChip(
                    avatar: Icon(Icons.calendar_today_outlined,
                        size: 14, color: pal.accent),
                    label: const Text('Custom...'),
                    onPressed: () => _pickCustomRange(context),
                    backgroundColor: pal.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(color: pal.border),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      color: pal.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Key metrics 4-pack cards
          StaggerIn(
            index: 0,
            dy: 8,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    label: 'Period Revenue',
                    value: money(totalRevenue),
                    icon: Icons.payments_outlined,
                    color: pal.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Daily Average',
                    value: money(avgDailyRevenue),
                    icon: Icons.trending_up_rounded,
                    color: pal.sage,
                  ),
                ),
              ],
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
                    label: 'Units Sold',
                    value: '$totalUnits items',
                    icon: Icons.shopping_bag_outlined,
                    color: pal.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Total Orders',
                    value: '$totalOrders sales',
                    icon: Icons.receipt_long_outlined,
                    color: pal.accentDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // -----------------------------------------------------------------
          // CHART 1: DAILY SALES REVENUE (BAR CHART)
          // -----------------------------------------------------------------
          StaggerIn(
            index: 2,
            dy: 10,
            child: _buildDailyRevenueBarChartCard(
              context,
              pal: pal,
              dailyStats: dailyStats,
              maxRevenue: maxRevenue,
              avgDailyRevenue: avgDailyRevenue,
            ),
          ),
          const SizedBox(height: 18),

          // -----------------------------------------------------------------
          // CHART 2: TOP-SELLING ITEMS (BAR CHART)
          // -----------------------------------------------------------------
          StaggerIn(
            index: 3,
            dy: 10,
            child: _buildTopProductsBarChartCard(
              context,
              pal: pal,
              topProducts: topProducts,
            ),
          ),
          const SizedBox(height: 18),

          // -----------------------------------------------------------------
          // PAYMENT METHOD DISTRIBUTION BREAKDOWN
          // -----------------------------------------------------------------
          StaggerIn(
            index: 4,
            dy: 10,
            child: _buildPaymentMixCard(context, pal, store, selectedSales),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helper: Retrieve sales matching current range selection
  // -------------------------------------------------------------------------
  List<Sale> _getSalesForRange(Store store) {
    if (_range == _AnalyticsRange.custom && _customDateRange != null) {
      final DateTime start = _customDateRange!.start;
      final DateTime end = _customDateRange!.end.add(const Duration(days: 1));
      return store.sales.where((Sale s) {
        return s.time.isAfter(start) && s.time.isBefore(end);
      }).toList();
    }
    if (_range == _AnalyticsRange.today) {
      return store.todaySales;
    }
    return store.salesForRange(switch (_range) {
      _AnalyticsRange.d7 => SalesRange.d7,
      _AnalyticsRange.d14 => SalesRange.d14,
      _AnalyticsRange.d30 => SalesRange.d30,
      _ => SalesRange.d7,
    });
  }

  List<DailySalesStat> _computeDailyStats(Store store) {
    if (_range == _AnalyticsRange.today) {
      // Return hourly buckets for today (9 AM to 8 PM)
      final List<double> hourly = store.revenueByHour;
      final DateTime now = DateTime.now();
      return List<DailySalesStat>.generate(12, (int i) {
        final int hour = i + 9;
        final double rev = hourly[i];
        final int orders = store.todaySales.where((Sale s) => s.time.hour == hour).length;
        final int units = store.todaySales
            .where((Sale s) => s.time.hour == hour)
            .fold(0, (int sum, Sale s) => sum + s.lines.fold(0, (int s2, SaleLine l) => s2 + l.qty));
        return DailySalesStat(
          date: DateTime(now.year, now.month, now.day, hour),
          revenue: rev,
          orders: orders,
          units: units,
          label: '$hour:00',
        );
      });
    }

    if (_range == _AnalyticsRange.custom && _customDateRange != null) {
      final DateTime start = _customDateRange!.start;
      final DateTime end = _customDateRange!.end;
      final int diff = end.difference(start).inDays + 1;
      final int totalDays = diff < 1 ? 1 : (diff > 60 ? 60 : diff);
      final List<DailySalesStat> stats = <DailySalesStat>[];

      for (int i = 0; i < totalDays; i++) {
        final DateTime targetDate = DateTime(start.year, start.month, start.day).add(Duration(days: i));
        double rev = 0;
        int orders = 0;
        int units = 0;

        for (final Sale s in store.sales) {
          final DateTime sDate = DateTime(s.time.year, s.time.month, s.time.day);
          if (sDate.year == targetDate.year &&
              sDate.month == targetDate.month &&
              sDate.day == targetDate.day) {
            rev += s.total;
            orders++;
            for (final SaleLine l in s.lines) {
              units += l.qty;
            }
          }
        }

        stats.add(DailySalesStat(
          date: targetDate,
          revenue: rev,
          orders: orders,
          units: units,
          label: '${targetDate.month}/${targetDate.day}',
        ));
      }
      return stats;
    }

    // Default: use store days helper
    final int days = _range.days;
    return store.getDailySalesStats(days);
  }

  // -------------------------------------------------------------------------
  // Widget: Daily Sales Revenue Bar Chart Card
  // -------------------------------------------------------------------------
  Widget _buildDailyRevenueBarChartCard(
    BuildContext context, {
    required Pal pal,
    required List<DailySalesStat> dailyStats,
    required double maxRevenue,
    required double avgDailyRevenue,
  }) {
    final double maxY = maxRevenue <= 0 ? 10000 : maxRevenue * 1.25;

    // Find peak and lowest days
    DailySalesStat? peakStat;
    DailySalesStat? lowStat;
    for (final DailySalesStat s in dailyStats) {
      if (peakStat == null || s.revenue > peakStat.revenue) peakStat = s;
      if (lowStat == null || (s.revenue < lowStat.revenue && s.revenue > 0)) {
        lowStat = s;
      }
    }

    final double rodWidth = switch (dailyStats.length) {
      <= 7 => 18.0,
      <= 14 => 11.0,
      <= 21 => 8.0,
      _ => 6.0,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _range == _AnalyticsRange.today
                        ? 'Hourly Sales Revenue'
                        : 'Daily Sales Revenue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: pal.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bar chart revenue distribution',
                    style: TextStyle(fontSize: 11, color: pal.muted),
                  ),
                ],
              ),
              if (peakStat != null && peakStat.revenue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pal.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: pal.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.star_rounded, size: 13, color: pal.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Peak: ${peakStat.label} (${money(peakStat.revenue)})',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: pal.amber,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Bar Chart Canvas
          SizedBox(
            height: 195,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => pal.surfaceAlt,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (
                      BarChartGroupData group,
                      int groupIndex,
                      BarChartRodData rod,
                      int rodIndex,
                    ) {
                      final DailySalesStat stat = dailyStats[group.x];
                      return BarTooltipItem(
                        '${stat.label}\n',
                        TextStyle(
                          color: pal.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${money(stat.revenue)}\n',
                            style: TextStyle(
                              color: pal.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: '${stat.orders} orders · ${stat.units} units',
                            style: TextStyle(
                              color: pal.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        _touchedRevenueBarIndex = null;
                        return;
                      }
                      _touchedRevenueBarIndex =
                          response.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == 0) return const Text('');
                        final String text = value >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}k'
                            : '${value.toInt()}';
                        return Text(
                          text,
                          style: TextStyle(fontSize: 9, color: pal.muted),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= dailyStats.length) {
                          return const Text('');
                        }
                        // Skip labels if there are too many bars
                        if (dailyStats.length > 14 &&
                            index % (dailyStats.length ~/ 6 + 1) != 0) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            dailyStats[index].label,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: index == _touchedRevenueBarIndex
                                  ? pal.accent
                                  : pal.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (double value) => FlLine(
                    color: pal.border.withValues(alpha: 0.6),
                    strokeWidth: 0.9,
                    dashArray: const <int>[4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List<BarChartGroupData>.generate(
                  dailyStats.length,
                  (int i) {
                    final DailySalesStat stat = dailyStats[i];
                    final bool isPeak = peakStat != null &&
                        stat.date == peakStat.date &&
                        stat.revenue > 0;
                    final bool isTouched = i == _touchedRevenueBarIndex;

                    final Color barColor = isTouched
                        ? pal.accent
                        : isPeak
                            ? pal.amber
                            : stat.revenue > avgDailyRevenue
                                ? pal.accent
                                : pal.accent.withValues(alpha: 0.65);

                    return BarChartGroupData(
                      x: i,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: stat.revenue,
                          color: barColor,
                          width: rodWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: pal.surfaceAlt.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Benchmark footnote
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: pal.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('Daily Revenue',
                      style: TextStyle(fontSize: 10.5, color: pal.muted)),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: pal.amber,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('Peak Day',
                      style: TextStyle(fontSize: 10.5, color: pal.muted)),
                ],
              ),
              Text(
                'Avg: ${money(avgDailyRevenue)}/day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: pal.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Widget: Top-Selling Items Bar Chart Card
  // -------------------------------------------------------------------------
  Widget _buildTopProductsBarChartCard(
    BuildContext context, {
    required Pal pal,
    required List<TopProduct> topProducts,
  }) {
    if (topProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          border: Border.all(color: pal.border),
        ),
        child: Center(
          child: Text(
            'No item sales recorded in this timeframe.',
            style: TextStyle(fontSize: 12, color: pal.muted),
          ),
        ),
      );
    }

    final double maxMetricVal = _topMetric == _TopMetric.revenue
        ? topProducts.map((TopProduct p) => p.revenue).reduce((double a, double b) => a > b ? a : b)
        : topProducts.map((TopProduct p) => p.qty.toDouble()).reduce((double a, double b) => a > b ? a : b);

    final double maxY = maxMetricVal <= 0 ? 10 : maxMetricVal * 1.25;

    // Distinct rank colors
    final List<Color> rankColors = <Color>[
      pal.accent,
      pal.amber,
      pal.sage,
      pal.accentDeep,
      Colors.indigo.shade400,
      pal.muted,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Top-Selling Items',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: pal.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Best performing catalog pieces',
                    style: TextStyle(fontSize: 11, color: pal.muted),
                  ),
                ],
              ),

              // Metric toggle: By Revenue vs By Units
              Container(
                decoration: BoxDecoration(
                  color: pal.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _metricToggleBtn('Revenue', _TopMetric.revenue, pal),
                    _metricToggleBtn('Units', _TopMetric.units, pal),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Top Items Bar Chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => pal.surfaceAlt,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (
                      BarChartGroupData group,
                      int groupIndex,
                      BarChartRodData rod,
                      int rodIndex,
                    ) {
                      final TopProduct tp = topProducts[group.x];
                      return BarTooltipItem(
                        '#${group.x + 1} ${tp.product.name}\n',
                        TextStyle(
                          color: pal.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${money(tp.revenue)} total\n',
                            style: TextStyle(
                              color: pal.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: '${tp.qty} units sold · ${tp.product.category}',
                            style: TextStyle(
                              color: pal.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        _touchedTopProductBarIndex = null;
                        return;
                      }
                      _touchedTopProductBarIndex =
                          response.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == 0) return const Text('');
                        if (_topMetric == _TopMetric.revenue) {
                          final String text = value >= 1000
                              ? '${(value / 1000).toStringAsFixed(0)}k'
                              : '${value.toInt()}';
                          return Text(text,
                              style: TextStyle(fontSize: 9, color: pal.muted));
                        } else {
                          return Text('${value.toInt()}',
                              style: TextStyle(fontSize: 9, color: pal.muted));
                        }
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= topProducts.length) {
                          return const Text('');
                        }
                        final String shortName = topProducts[index].product.name;
                        final String label = shortName.length > 7
                            ? '${shortName.substring(0, 6)}…'
                            : shortName;

                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: index == _touchedTopProductBarIndex
                                  ? pal.accent
                                  : pal.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (double value) => FlLine(
                    color: pal.border.withValues(alpha: 0.6),
                    strokeWidth: 0.9,
                    dashArray: const <int>[4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List<BarChartGroupData>.generate(
                  topProducts.length,
                  (int i) {
                    final TopProduct tp = topProducts[i];
                    final double val = _topMetric == _TopMetric.revenue
                        ? tp.revenue
                        : tp.qty.toDouble();
                    final Color color = rankColors[i % rankColors.length];

                    return BarChartGroupData(
                      x: i,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: val,
                          color: color,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: pal.surfaceAlt.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Detailed Table / Cards of Top Selling Items
          Text(
            'DETAILED BREAKDOWN BY RANK',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: pal.accent,
            ),
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int i) {
              final TopProduct tp = topProducts[i];
              final double ratio = maxMetricVal <= 0
                  ? 0
                  : (_topMetric == _TopMetric.revenue
                          ? tp.revenue
                          : tp.qty.toDouble()) /
                      maxMetricVal;
              final Color rankColor = rankColors[i % rankColors.length];

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pal.surfaceAlt.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: pal.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rankColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '#${i + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                tp.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: pal.ink,
                                ),
                              ),
                              Text(
                                'Barcode: ${tp.product.barcode} · ${tp.product.category}',
                                style: TextStyle(
                                    fontSize: 10.5, color: pal.muted),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              money(tp.revenue),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: pal.ink,
                              ),
                            ),
                            Text(
                              '${tp.qty} units sold',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: pal.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(
                      value: ratio,
                      height: 5,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metricToggleBtn(String label, _TopMetric metric, Pal pal) {
    final bool active = _topMetric == metric;
    return GestureDetector(
      onTap: () => setState(() => _topMetric = metric),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? pal.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : pal.muted,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Widget: Payment Mix Breakdown
  // -------------------------------------------------------------------------
  Widget _buildPaymentMixCard(
    BuildContext context,
    Pal pal,
    Store store,
    List<Sale> sales,
  ) {
    final Map<PaymentMethod, double> mix = store.paymentMixFor(sales);
    final double total = store.revenueFor(sales);
    final double cash = mix[PaymentMethod.cash] ?? 0;
    final double card = mix[PaymentMethod.card] ?? 0;
    final double mobile = mix[PaymentMethod.mobile] ?? 0;

    final double cashPct = total <= 0 ? 0 : (cash / total * 100);
    final double cardPct = total <= 0 ? 0 : (card / total * 100);
    final double mobilePct = total <= 0 ? 0 : (mobile / total * 100);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Payment Method Mix',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: pal.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tender distribution across transactions',
            style: TextStyle(fontSize: 11, color: pal.muted),
          ),
          const SizedBox(height: 12),

          // Horizontal Segment Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: <Widget>[
                  if (cashPct > 0)
                    Expanded(
                      flex: (cashPct * 10).toInt().clamp(1, 1000),
                      child: Container(color: pal.accent),
                    ),
                  if (cardPct > 0)
                    Expanded(
                      flex: (cardPct * 10).toInt().clamp(1, 1000),
                      child: Container(color: pal.sage),
                    ),
                  if (mobilePct > 0)
                    Expanded(
                      flex: (mobilePct * 10).toInt().clamp(1, 1000),
                      child: Container(color: pal.amber),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _payMixLegend('Cash', money(cash), cashPct, pal.accent),
              _payMixLegend('Card', money(card), cardPct, pal.sage),
              _payMixLegend('Mobile', money(mobile), mobilePct, pal.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payMixLegend(String label, String amount, double pct, Color color) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text('${pct.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        Text(amount,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

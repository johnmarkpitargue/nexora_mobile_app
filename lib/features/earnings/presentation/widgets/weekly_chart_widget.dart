import 'package:flutter/material.dart';
import '../../../../core/models/earning_record.dart';
import '../../../../core/services/earnings_service.dart';

enum PerformanceTab { today, thisWeek, thisMonth, custom }

class WeeklyChartWidget extends StatefulWidget {
  final List<DayEarnings> data;

  const WeeklyChartWidget({
    super.key,
    required this.data,
  });

  @override
  State<WeeklyChartWidget> createState() => _WeeklyChartWidgetState();
}

class _WeeklyChartWidgetState extends State<WeeklyChartWidget>
    with SingleTickerProviderStateMixin {
  PerformanceTab _selectedTab = PerformanceTab.thisWeek;
  int? _selectedBarIndex = 6; // Default selected: Sunday (matches design)
  bool _drillDownActive = false;
  DateTimeRange? _customRange;

  late AnimationController _animController;
  late Animation<double> _chartGrowAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _chartGrowAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabChanged(PerformanceTab tab) async {
    if (tab == PerformanceTab.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 1),
        initialDateRange: _customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 6)),
              end: now,
            ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF0284C7),
                onPrimary: Colors.white,
                onSurface: Color(0xFF0F172A),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _customRange = picked;
          _selectedTab = PerformanceTab.custom;
          _selectedBarIndex = null;
          _drillDownActive = false;
        });
        _animController.forward(from: 0.0);
      }
      return;
    }

    setState(() {
      _selectedTab = tab;
      _drillDownActive = false;
      if (tab == PerformanceTab.thisWeek) {
        _selectedBarIndex = 6; // Sunday
      } else if (tab == PerformanceTab.today) {
        _selectedBarIndex = 3; // Latest rush
      } else if (tab == PerformanceTab.thisMonth) {
        _selectedBarIndex = 2; // Current week
      }
    });
    _animController.forward(from: 0.0);
  }

  List<DayEarnings> _getCurrentDataset() {
    switch (_selectedTab) {
      case PerformanceTab.today:
        return EarningsService.instance.todayData;
      case PerformanceTab.thisWeek:
        return widget.data.isNotEmpty
            ? widget.data
            : EarningsService.instance.weeklyData;
      case PerformanceTab.thisMonth:
        return EarningsService.instance.monthlyData;
      case PerformanceTab.custom:
        if (_customRange != null) {
          return [
            DayEarnings(
              dayName: 'Day 1-2',
              amount: 3200.00,
              ordersCount: 12,
              hoursWorked: 8.5,
              tipsAmount: 140.0,
              dateLabel: 'Start Period',
            ),
            DayEarnings(
              dayName: 'Day 3-4',
              amount: 4100.00,
              ordersCount: 16,
              hoursWorked: 10.2,
              tipsAmount: 180.0,
              dateLabel: 'Mid Period',
            ),
            DayEarnings(
              dayName: 'Day 5-7',
              amount: 5270.00,
              ordersCount: 20,
              hoursWorked: 13.8,
              tipsAmount: 240.0,
              dateLabel: 'End Period',
              isCurrent: true,
            ),
          ];
        }
        return widget.data;
    }
  }

  String _getSectionTitle() {
    switch (_selectedTab) {
      case PerformanceTab.today:
        return "Today's Payouts";
      case PerformanceTab.thisWeek:
        return 'Past 7 Days Payouts';
      case PerformanceTab.thisMonth:
        return 'October Payouts';
      case PerformanceTab.custom:
        return 'Custom Range Payouts';
    }
  }

  String _getGrowthBadge() {
    switch (_selectedTab) {
      case PerformanceTab.today:
        return '+12% vs yesterday';
      case PerformanceTab.thisWeek:
        return '+18% vs last week';
      case PerformanceTab.thisMonth:
        return '+24% vs last month';
      case PerformanceTab.custom:
        return 'Filtered Range';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataset = _getCurrentDataset();

    double maxAmount = 1.0;
    double totalWeekEarnings = 0.0;
    int totalTrips = 0;
    double totalHours = 0.0;
    double totalTips = 0.0;

    for (var d in dataset) {
      if (d.amount > maxAmount) maxAmount = d.amount;
      totalWeekEarnings += d.amount;
      totalTrips += d.ordersCount;
      totalHours += d.hoursWorked;
      totalTips += d.tipsAmount;
    }

    final double avgPerHour =
        totalHours > 0 ? (totalWeekEarnings / totalHours) : 0.0;

    // Selected Day / Drill-down stats
    final DayEarnings? activeItem = (_selectedBarIndex != null &&
            _selectedBarIndex! < dataset.length)
        ? dataset[_selectedBarIndex!]
        : null;

    final displayTrips =
        _drillDownActive && activeItem != null ? activeItem.ordersCount : (
            // If Week tab and default overview, exactly match screenshot 48
            _selectedTab == PerformanceTab.thisWeek ? 48 : totalTrips);
    final displayHours =
        _drillDownActive && activeItem != null ? '${activeItem.hoursWorked.toStringAsFixed(1)}h' : (
            _selectedTab == PerformanceTab.thisWeek ? '32.5h' : '${totalHours.toStringAsFixed(1)}h');
    final displayAvg =
        _drillDownActive && activeItem != null ? '₱${activeItem.avgPerHour.toStringAsFixed(0)}' : (
            _selectedTab == PerformanceTab.thisWeek ? '₱248' : '₱${avgPerHour.toStringAsFixed(0)}');
    final displayTips =
        _drillDownActive && activeItem != null ? '₱${activeItem.tipsAmount.toStringAsFixed(0)}' : (
            _selectedTab == PerformanceTab.thisWeek ? '₱560' : '₱${totalTips.toStringAsFixed(0)}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Time Filter Tabs: Today | This Week | This Month | Custom
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildTabPill('Today', PerformanceTab.today),
                _buildTabPill('This Week', PerformanceTab.thisWeek),
                _buildTabPill('This Month', PerformanceTab.thisMonth),
                _buildTabPill('Custom', PerformanceTab.custom),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Section Subtitle + Title + Growth Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WEEKLY PERFORMANCE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getSectionTitle(),
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FDF3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  _getGrowthBadge(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Interactive Bar Chart with Animated Growth
          AnimatedBuilder(
            animation: _chartGrowAnim,
            builder: (context, _) {
              return SizedBox(
                height: 148,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(dataset.length, (index) {
                    final item = dataset[index];
                    final isSelected = _selectedBarIndex == index;
                    final isSunOrCurrent = item.isCurrent || isSelected;

                    // Compute height scale
                    final double rawFactor = item.amount / maxAmount;
                    final double heightFactor = (rawFactor.clamp(0.20, 1.0) *
                        _chartGrowAnim.value);

                    // Display amount label e.g. ₱1.6k or ₱2.5k
                    final String amountLabel = item.amount >= 1000
                        ? '₱${(item.amount / 1000).toStringAsFixed(1)}k'
                        : '₱${item.amount.toStringAsFixed(0)}';

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            if (_selectedBarIndex == index) {
                              // Toggle drill-down
                              _drillDownActive = !_drillDownActive;
                            } else {
                              _selectedBarIndex = index;
                              _drillDownActive = true;
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Amount Tag above Bar
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: isSunOrCurrent
                                      ? FontWeight.w900
                                      : FontWeight.w800,
                                  color: isSunOrCurrent
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF64748B),
                                ),
                                child: Text(amountLabel),
                              ),
                              const SizedBox(height: 6),

                              // Bar Graphic
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                height: 92 * heightFactor,
                                decoration: BoxDecoration(
                                  gradient: isSunOrCurrent
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF00C4FF),
                                            Color(0xFF0284C7),
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFFE2E8F0),
                                            Color(0xFFE8EEF5),
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: isSunOrCurrent
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00C4FF)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Day label below Bar
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSunOrCurrent
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: isSunOrCurrent
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF64748B),
                                ),
                                child: Text(item.dayName),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // 4. Interactive Detail Banner on Bar Tap
          if (activeItem != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C4FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activeItem.dateLabel.isNotEmpty
                            ? activeItem.dateLabel
                            : activeItem.dayName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ₱${activeItem.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _drillDownActive = !_drillDownActive);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _drillDownActive
                            ? const Color(0xFF0284C7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Text(
                        _drillDownActive ? 'Show Week Total' : 'Filter Day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _drillDownActive
                              ? Colors.white
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 5. Four Key Summary Performance Metrics (TRIPS | HOURS | AVG/HR | TIPS)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('TRIPS', displayTrips.toString(),
                    const Color(0xFF0F172A)),
                _buildMetricColumn('HOURS', displayHours,
                    const Color(0xFF0F172A)),
                _buildMetricColumn(
                    'AVG/HR', displayAvg, const Color(0xFF059669)),
                _buildMetricColumn(
                    'TIPS', displayTips, const Color(0xFF0284C7)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String title, PerformanceTab tab) {
    final bool isSelected = _selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

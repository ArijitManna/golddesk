import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/repositories/dashboard_repository.dart';

class LiveGoldRateCard extends StatefulWidget {
  const LiveGoldRateCard({super.key});

  @override
  State<LiveGoldRateCard> createState() => _LiveGoldRateCardState();
}

class _LiveGoldRateCardState extends State<LiveGoldRateCard> {
  GoldRateData? _rate;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rate = await getIt<DashboardRepository>().getGoldRate();
      if (!mounted) return;
      setState(() {
        _rate = rate;
        _loading = false;
        if (!rate.available) _error = 'Rate unavailable';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load gold rate';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inr = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldLight,
            AppColors.gold,
            AppColors.goldBronze,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Live Gold Rate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Refresh',
              ),
            ],
          ),
          Text(
            _rate?.source?.isNotEmpty == true
                ? _rate!.source!
                : 'India market rates (24K / 22K)',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (_error != null || _rate == null || !_rate!.available)
            Text(
              _error ?? 'Rate unavailable',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _rateTile(
                    '24K',
                    inr.format(_rate!.rate24k),
                    change: _rate!.changePercent24k,
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: Colors.white24,
                ),
                Expanded(
                  child: _rateTile(
                    '22K',
                    inr.format(_rate!.rate22k),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _rateTile(String label, String value, {double? change}) {
    final up = change != null && change >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value / g',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  up ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: up ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
                const SizedBox(width: 2),
                Text(
                  '${change.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: up ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

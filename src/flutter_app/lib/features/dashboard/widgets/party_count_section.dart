import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/dashboard_models.dart';

class PartyCountSection extends StatefulWidget {
  final String title;
  final String searchHint;
  final String emptyMessage;
  final IconData icon;
  final List<BusinessOrderCount> parties;
  final ValueChanged<BusinessOrderCount> onTap;

  const PartyCountSection({
    super.key,
    required this.title,
    required this.searchHint,
    required this.emptyMessage,
    required this.icon,
    required this.parties,
    required this.onTap,
  });

  @override
  State<PartyCountSection> createState() => _PartyCountSectionState();
}

class _PartyCountSectionState extends State<PartyCountSection> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _searchThreshold = 4;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BusinessOrderCount> get _visible {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.parties;
    return widget.parties
        .where(
          (party) =>
              party.businessName.toLowerCase().contains(query) ||
              (party.code?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = widget.parties.length >= _searchThreshold;
    final visible = _visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        if (showSearch) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (widget.parties.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                widget.emptyMessage,
                style: const TextStyle(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No match found',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        else
          ...visible.map(_buildCard),
      ],
    );
  }

  Widget _buildCard(BusinessOrderCount party) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withValues(alpha: 0.12),
          child: Icon(widget.icon, color: AppColors.gold),
        ),
        title: Text(
          party.businessName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: party.code == null || party.code!.isEmpty
            ? const Text('Open orders')
            : Text(party.code!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${party.orderCount}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
        onTap: () => widget.onTap(party),
      ),
    );
  }
}

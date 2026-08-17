import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/role_navigation.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/models/connection_models.dart';
import '../../../data/repositories/connection_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _searchController = TextEditingController();
  List<BusinessConnection> _connections = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _connections = await getIt<ConnectionRepository>().getConnections();
    } catch (e) {
      _error = 'Could not load connections.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _searchAndRequest() async {
    final code = _searchController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showMessage('Enter a GoldDesk ID to search.', error: true);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final business = await getIt<ConnectionRepository>().searchBusiness(code);
      if (!mounted) return;
      await _showConnectionConfirmation(business);
    } catch (_) {
      if (mounted)
        _showMessage(
          'No active business found with that GoldDesk ID.',
          error: true,
        );
    }
    if (mounted) setState(() => _isSearching = false);
  }

  Future<void> _showConnectionConfirmation(BusinessSummary business) async {
    final notes = TextEditingController();
    final request = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connect Business',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _businessCard(business),
            const SizedBox(height: 16),
            GoldDeskTextField(
              label: 'Message (Optional)',
              hint: 'Introduce your business',
              controller: notes,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            GoldDeskButton(
              text: 'SEND CONNECTION REQUEST',
              onPressed: () => Navigator.pop(sheetContext, true),
            ),
          ],
        ),
      ),
    );

    if (request != true || !mounted) return;
    try {
      await getIt<ConnectionRepository>().requestConnection(
        business.goldDeskId,
        notes: notes.text.trim(),
      );
      _searchController.clear();
      _showMessage('Connection request sent to ${business.name}.');
      await _load();
    } catch (e) {
      if (mounted)
        _showMessage('Could not send connection request.', error: true);
    }
  }

  Future<void> _respond(BusinessConnection connection, bool accept) async {
    try {
      await getIt<ConnectionRepository>().respondToRequest(
        connection.id,
        accept: accept,
      );
      _showMessage(
        accept ? 'Connection accepted.' : 'Connection request rejected.',
      );
      await _load();
    } catch (_) {
      if (mounted) {
        _showMessage('Could not update connection request.', error: true);
      }
    }
  }

  Future<void> _block(BusinessConnection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block connection?'),
        content: Text(
          '${connection.counterpartyName} will no longer be able to send connection requests to your business.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await getIt<ConnectionRepository>().blockConnection(connection.id);
      _showMessage('${connection.counterpartyName} was blocked.');
      await _load();
    } catch (_) {
      if (mounted) {
        _showMessage('Could not block this connection.', error: true);
      }
    }
  }

  Future<void> _cancelRequest(BusinessConnection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel connection request?'),
        content: Text(
          'The request to ${connection.counterpartyName} will be removed. You can send a new request later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await getIt<ConnectionRepository>().cancelConnectionRequest(
        connection.id,
      );
      _showMessage('Connection request cancelled.');
      await _load();
    } catch (_) {
      if (mounted) {
        _showMessage('Could not cancel this connection request.', error: true);
      }
    }
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final incoming = _connections
        .where((item) => item.status == 'Pending' && item.isIncoming)
        .toList();
    final accepted = _connections
        .where((item) => item.status == 'Accepted')
        .toList();
    final sent = _connections
        .where((item) => item.status == 'Pending' && !item.isIncoming)
        .toList();
    final blocked = _connections
        .where((item) => item.status == 'Blocked')
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(homePathForUser(user)),
        ),
        title: const Text('Connections'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _myGoldDeskCard(user),
                  const SizedBox(height: 20),
                  Text(
                    'Connect a Business',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a GoldDesk ID to send a private connection request.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'e.g. GD-SHOP-0001',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (_) => _searchAndRequest(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _searchAndRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.white,
                          ),
                          child: _isSearching
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('CONNECT'),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _errorCard(),
                  ],
                  if (incoming.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _sectionTitle('Connection Requests', incoming.length),
                    const SizedBox(height: 8),
                    ...incoming.map(_incomingCard),
                  ],
                  const SizedBox(height: 28),
                  _sectionTitle(_connectedTitle(user), accepted.length),
                  const SizedBox(height: 8),
                  if (accepted.isEmpty)
                    _emptyCard('No connected businesses yet.')
                  else
                    ...accepted.map(_connectionCard),
                  if (sent.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _sectionTitle('Sent Requests', sent.length),
                    const SizedBox(height: 8),
                    ...sent.map(_sentRequestCard),
                  ],
                  if (blocked.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _sectionTitle('Blocked', blocked.length),
                    const SizedBox(height: 8),
                    ...blocked.map(_blockedConnectionCard),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }

  Widget _myGoldDeskCard(UserInfo? user) {
    final businessType = user?.businessType ?? 'Business';
    final id = user?.goldDeskId ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_2, color: AppColors.gold, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My GoldDesk ID',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 4),
                Text(
                  id.isEmpty ? 'Available after next login' : id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  businessType,
                  style: const TextStyle(color: AppColors.gold, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Show QR code',
                icon: const Icon(Icons.qr_code, color: Colors.white),
                onPressed: id.isEmpty
                    ? null
                    : () => _showQrCode(id, businessType),
              ),
              IconButton(
                tooltip: 'Copy ID',
                icon: const Icon(Icons.copy_outlined, color: Colors.white),
                onPressed: id.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: id));
                        if (mounted) _showMessage('GoldDesk ID copied.');
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQrCode(String id, String businessType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My GoldDesk QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: id,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(id, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              businessType,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code so another GoldDesk business can connect with you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _businessCard(BusinessSummary business) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: _businessIcon(business.businessType),
        title: Text(
          business.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${business.businessType} • ${business.goldDeskId}'),
      ),
    );
  }

  Widget _incomingCard(BusinessConnection connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _connectionIdentity(connection),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(connection, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(connection, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ACCEPT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectionCard(BusinessConnection connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _businessIcon(connection.counterpartyBusinessType),
        title: Text(
          connection.counterpartyName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${connection.counterpartyBusinessType} • ${connection.counterpartyGoldDeskId}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'block') _block(connection);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'block', child: Text('Block connection')),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Widget _blockedConnectionCard(BusinessConnection connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      child: ListTile(
        leading: Icon(Icons.block_outlined, color: AppColors.error),
        title: Text(
          connection.counterpartyName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${connection.counterpartyBusinessType} • ${connection.counterpartyGoldDeskId}',
        ),
        trailing: const Text(
          'BLOCKED',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _sentRequestCard(BusinessConnection connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _businessIcon(connection.counterpartyBusinessType),
        title: Text(
          connection.counterpartyName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${connection.counterpartyBusinessType} • ${connection.counterpartyGoldDeskId}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PENDING',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            IconButton(
              tooltip: 'Cancel request',
              onPressed: () => _cancelRequest(connection),
              icon: const Icon(Icons.close_outlined, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectionIdentity(BusinessConnection connection) {
    return Row(
      children: [
        _businessIcon(connection.counterpartyBusinessType),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                connection.counterpartyName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${connection.counterpartyBusinessType} • ${connection.counterpartyGoldDeskId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _businessIcon(String type) {
    final icon = switch (type) {
      'Showroom' => Icons.storefront_outlined,
      'Karigar' => Icons.handyman_outlined,
      _ => Icons.store_outlined,
    };
    return CircleAvatar(
      backgroundColor: AppColors.gold.withValues(alpha: 0.12),
      child: Icon(icon, color: AppColors.gold),
    );
  }

  Widget _sectionTitle(String title, int count) => Row(
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(width: 8),
      if (count > 0)
        CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.primaryDark,
          child: Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
    ],
  );

  Widget _emptyCard(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.divider),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );

  Widget _errorCard() => _emptyCard(_error!);

  String _connectedTitle(UserInfo? user) => switch (user?.businessType) {
    'Showroom' => 'My Shops',
    'Karigar' => 'My Shops',
    'Shop' => 'My Connections',
    _ => 'Connected Businesses',
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/features/addition/data/modals/addition_model.dart';
import '../providers/addition_providers.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final additionsAsync = ref.watch(additionsListProvider);
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () => ref.refresh(additionsListProvider.future),
          child: additionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
            error: (error, _) => _ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(additionsListProvider),
            ),
            data: (additions) => _HomeContent(
              additions: additions,
              userInitial: user?.nom.isNotEmpty == true ? user!.nom[0].toUpperCase() : '?',
              userNom: user?.nom,
              userEmail: user?.email,
              ref: ref,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<AdditionModel> additions;
  final String userInitial;
  final String? userNom;
  final String? userEmail;
  final WidgetRef ref;

  const _HomeContent({
    required this.additions,
    required this.userInitial,
    required this.userNom,
    required this.userEmail,
    required this.ref,
  });

  double get _pendingPayout {
    return additions
        .where((a) => a.statut != StatutAddition.cloturee && a.statut != StatutAddition.annulee)
        .fold(0.0, (sum, a) => sum + a.montantTotal);
  }

  double get _thisMonthTotal {
    final now = DateTime.now();
    return additions
        .where((a) => a.createdAt.year == now.year && a.createdAt.month == now.month)
        .fold(0.0, (sum, a) => sum + a.montantTotal);
  }

  int get _splitsCount => additions.length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildPendingPayoutCard(),
          const SizedBox(height: 20),
          _buildScanButton(context),
          const SizedBox(height: 28),
          _buildRecentSplitsHeader(context),
          const SizedBox(height: 12),
          if (additions.isEmpty)
            _EmptyState(onScan: () => context.push('/scan-receipt'))
          else
            ...additions.take(5).map((a) => _AdditionCard(addition: a)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.actionGradient.createShader(bounds),
          child: Text('YallaSplit', style: AppTextStyles.h1.copyWith(color: Colors.white)),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.muted, size: 22),
              onPressed: () => ref.invalidate(additionsListProvider),
            ),
            const SizedBox(width: 4),
            _buildProfileMenu(context),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'password':
            context.push('/change-password');
            break;
          case 'logout':
            _confirmLogout(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userNom ?? '',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(userEmail ?? '', style: AppTextStyles.caption),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'password',
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
              const SizedBox(width: 10),
              Text('Changer le mot de passe', style: AppTextStyles.body),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppColors.danger),
              const SizedBox(width: 10),
              Text('Se déconnecter', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
        child: Center(
          child: Text(
            userInitial,
            style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Se déconnecter ?', style: AppTextStyles.h2),
        content: Text(
          'Tu devras te reconnecter pour accéder à ton compte.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Déconnexion', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Widget _buildPendingPayoutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PENDING PAYOUT', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(
            'AED ${_pendingPayout.toStringAsFixed(2)}',
            style: AppTextStyles.display.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn('This month', 'AED ${_thisMonthTotal.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _buildStatColumn('Splits', '$_splitsCount'),
              ),
              OutlinedButton(
                onPressed: () {
                  // TODO: brancher le flow "Cash out" (module Wallet, pas encore prêt)
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.muted),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text('Cash out', style: AppTextStyles.body),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h2),
      ],
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.actionGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/scan-receipt'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Scan a receipt', style: AppTextStyles.h2.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSplitsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Recent splits', style: AppTextStyles.h2),
        GestureDetector(
          onTap: () => context.push('/additions'),
          child: Text(
            'See all',
            style: AppTextStyles.caption.copyWith(color: AppColors.blue),
          ),
        ),
      ],
    );
  }
}

class _AdditionCard extends StatelessWidget {
  final AdditionModel addition;

  const _AdditionCard({required this.addition});

  Color get _statusColor {
    switch (addition.statut) {
      case StatutAddition.cloturee:
        return AppColors.moneyGreen;
      case StatutAddition.annulee:
        return AppColors.danger;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/addition/${addition.id}'),
        borderRadius: BorderRadius.circular(16),
        hoverColor: AppColors.surface.withValues(alpha: 0.5),
        splashColor: AppColors.violet.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.violet, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Addition du ${_formatDate(addition.dateScan)}',
                      style: AppTextStyles.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('${addition.articles.length} articles', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'AED ${addition.montantTotal.toStringAsFixed(2)}',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addition.statusLabel,
                    style: AppTextStyles.caption.copyWith(color: _statusColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;

  const _EmptyState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.muted, size: 48),
          const SizedBox(height: 16),
          Text('Aucune addition pour le moment', style: AppTextStyles.bodyMuted),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onScan,
            child: Text('Scanner ton premier reçu',
                style: AppTextStyles.body.copyWith(color: AppColors.violet)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text('Réessayer', style: AppTextStyles.body.copyWith(color: AppColors.violet)),
            ),
          ],
        ),
      ),
    );
  }
}
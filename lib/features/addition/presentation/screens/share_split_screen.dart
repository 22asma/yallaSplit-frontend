import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import '../../data/modals/participant_model.dart';
import '../providers/addition_providers.dart';

class ShareSplitScreen extends ConsumerWidget {
  final String additionId;
  final double? montantTotal; // passé depuis review_items_screen pour affichage immédiat

  const ShareSplitScreen({super.key, required this.additionId, this.montantTotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lienAsync = ref.watch(lienPaiementProvider(additionId));
    final participantsAsync = ref.watch(participantsProvider(additionId));

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: lienAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
          error: (error, _) => Center(
            child: Text('Erreur : $error', style: AppTextStyles.bodyMuted),
          ),
          data: (lien) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildSuccessHeader(),
                const SizedBox(height: 28),
                _buildLinkCard(context, lien.urlSecurisee),
                const SizedBox(height: 16),
                _buildWhatsAppButton(lien.urlSecurisee),
                const SizedBox(height: 12),
                _buildQuickActions(context, lien.urlSecurisee),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    montantTotal != null
                        ? 'Splitting AED ${montantTotal!.toStringAsFixed(2)}'
                        : 'Participants',
                    style: AppTextStyles.h2,
                  ),
                ),
                const SizedBox(height: 12),
                participantsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.violet),
                  ),
                  error: (e, _) => Text('$e', style: AppTextStyles.bodyMuted),
                  data: (participants) => participants.isEmpty
                      ? _buildEmptyParticipants()
                      : Column(
                          children: participants
                              .map((p) => _ParticipantTile(participant: p))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text('Retour à l\'accueil',
                      style: AppTextStyles.body.copyWith(color: AppColors.violet)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.moneyGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: AppColors.moneyGreen, size: 32),
        ),
        const SizedBox(height: 16),
        Text('Your split is ready', style: AppTextStyles.display.copyWith(fontSize: 22)),
        const SizedBox(height: 8),
        Text(
          'Send one link to the whole table.\nFriends pay their part — no app, no account.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildLinkCard(BuildContext context, String url) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHARE LINK', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Text(
                  _shortUrl(url),
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _copyLink(context, url),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.muted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Copy', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  String _shortUrl(String url) {
    // Enlève le http(s):// pour un affichage plus propre, comme sur la maquette.
    return url.replaceFirst(RegExp(r'^https?://'), '');
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien copié')),
      );
    }
  }

  Widget _buildWhatsAppButton(String url) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.whatsapp,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openWhatsApp(url),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Send on WhatsApp',
                  style: AppTextStyles.h2.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String url) async {
    final message = Uri.encodeComponent(
      'Voici le lien pour payer ta part sur YallaSplit : $url',
    );
    final whatsappUri = Uri.parse('https://wa.me/?text=$message');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildQuickActions(BuildContext context, String url) {
    return Row(
      children: [
        Expanded(child: _actionButton(icon: Icons.sms_outlined, label: 'SMS', onTap: () => _openSms(url))),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.link,
            label: 'Copy',
            onTap: () => _copyLink(context, url),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.qr_code,
            label: 'QR',
            onTap: () => _showQrDialog(context, url),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.more_horiz,
            label: 'More',
            onTap: () => Share.share('Paye ta part sur YallaSplit : $url'),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.text, size: 20),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Future<void> _openSms(String url) async {
    final uri = Uri(scheme: 'sms', queryParameters: {'body': 'Paye ta part sur YallaSplit : $url'});
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showQrDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scanne pour payer', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer', style: AppTextStyles.body.copyWith(color: AppColors.violet)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyParticipants() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.people_outline, color: AppColors.muted, size: 32),
          const SizedBox(height: 12),
          Text(
            'Personne n\'a encore rejoint. Partage le lien pour commencer.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;

  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    final paye = participant.aPaye;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.violet,
            child: Text(
              participant.nom.isNotEmpty ? participant.nom[0].toUpperCase() : '?',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participant.nom, style: AppTextStyles.body),
                if (participant.montant != null)
                  Text('AED ${participant.montant!.toStringAsFixed(2)}',
                      style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (paye ? AppColors.moneyGreen : AppColors.gold).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              paye ? 'Paid' : 'Pending',
              style: AppTextStyles.caption.copyWith(color: paye ? AppColors.moneyGreen : AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}
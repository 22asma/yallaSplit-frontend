import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/core/widgets/gradient_button.dart';
import '../providers/addition_providers.dart';

class PaymentResultScreen extends ConsumerStatefulWidget {
  final bool success;
  final String? sessionId;
  final String? token;

  const PaymentResultScreen({
    super.key,
    required this.success,
    this.sessionId,
    this.token,
  });

  @override
  ConsumerState<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

enum _ConfirmStatus { checking, confirmed, error }

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  _ConfirmStatus _status = _ConfirmStatus.checking;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
    }
  }

  Future<void> _confirm() async {
    if (widget.sessionId == null || widget.token == null) {
      setState(() {
        _status = _ConfirmStatus.error;
        _error = 'Informations de paiement incomplètes';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final participantId = prefs.getString('participant_id_${widget.token}');

    if (participantId == null) {
      setState(() {
        _status = _ConfirmStatus.error;
        _error = 'Session participant introuvable';
      });
      return;
    }

    try {
      final api = ref.read(participantPublicApiServiceProvider);
      await api.confirmerPaiement(widget.token!, participantId, widget.sessionId!);
      setState(() => _status = _ConfirmStatus.confirmed);
    } catch (e) {
      setState(() {
        _status = _ConfirmStatus.error;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: !widget.success
                ? _buildCancel()
                : switch (_status) {
                    _ConfirmStatus.checking => const CircularProgressIndicator(color: AppColors.violet),
                    _ConfirmStatus.confirmed => _buildSuccess(),
                    _ConfirmStatus.error => _buildError(),
                  },
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.moneyGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, color: AppColors.moneyGreen, size: 40),
        ),
        const SizedBox(height: 24),
        Text('Paiement confirmé 🎉', style: AppTextStyles.display.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text('Merci d\'avoir payé ta part.', style: AppTextStyles.bodyMuted),
      ],
    );
  }

  Widget _buildCancel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.close, color: AppColors.muted, size: 48),
        const SizedBox(height: 16),
        Text('Paiement annulé', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text('Tu peux réessayer à tout moment via le lien reçu.', style: AppTextStyles.bodyMuted),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Retour',
          onPressed: () {
            if (widget.token != null) context.go('/pay/${widget.token}');
          },
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
        const SizedBox(height: 16),
        Text(_error ?? 'Une erreur est survenue', style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
      ],
    );
  }
}
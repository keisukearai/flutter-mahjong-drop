import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../purchase/purchase_service.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PurchaseService>();

    // 購入完了したら自動で閉じる
    if (service.isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
      });
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0505), Color(0xFF3A0808), Color(0xFF6B1010)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '👹',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              const Text(
                '鬼モードを解放する',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '全牌が登場するハードモード',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _FeatureRow(icon: Icons.local_fire_department, text: '全牌（萬・筒・索・字牌）が登場'),
              const SizedBox(height: 10),
              _FeatureRow(icon: Icons.trending_up, text: 'スコアが伸びるほど難易度が上昇'),
              const SizedBox(height: 10),
              _FeatureRow(icon: Icons.emoji_events, text: '鬼モード専用ハイスコア記録'),
              const SizedBox(height: 36),
              _PurchaseButton(service: service),
              const SizedBox(height: 12),
              TextButton(
                onPressed: service.isPurchasing ? null : () => service.restore(),
                child: const Text(
                  '購入を復元する',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF6B35), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      ],
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  final PurchaseService service;
  const _PurchaseButton({required this.service});

  @override
  Widget build(BuildContext context) {
    final priceLabel = service.product != null
        ? '解放する  ${service.product!.price}'
        : '解放する';

    return GestureDetector(
      onTap: service.isPurchasing ? null : () => service.purchase(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF6B35), width: 2),
          gradient: const LinearGradient(
            colors: [Color(0xFFBF3030), Color(0xFF7A1010)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4500).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: service.isPurchasing
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  priceLabel,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

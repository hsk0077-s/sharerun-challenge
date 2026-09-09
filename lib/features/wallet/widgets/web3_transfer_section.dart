import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';

enum Web3TransferChannel {
  externalWallet('external_wallet', '외부 지갑 (MetaMask 등)'),
  dex('dex', '외부 DEX');

  const Web3TransferChannel(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class Web3TransferSection extends StatefulWidget {
  const Web3TransferSection({
    required this.valueTokenBalance,
    required this.transferring,
    required this.onTransfer,
    super.key,
  });

  final int valueTokenBalance;
  final bool transferring;
  final Future<void> Function({
    required String destinationAddress,
    required int amountSrv,
    required Web3TransferChannel channel,
  }) onTransfer;

  @override
  State<Web3TransferSection> createState() => _Web3TransferSectionState();
}

class _Web3TransferSectionState extends State<Web3TransferSection> {
  final _addressController = TextEditingController(
    text: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0',
  );
  final _amountController = TextEditingController(text: '100');
  Web3TransferChannel _channel = Web3TransferChannel.externalWallet;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neonLime.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.neonLime),
              const SizedBox(width: 8),
              Text(
                'Web3 오프램프 전송',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '획득한 SRV(밸류 토큰)를 외부 개인 Web3 지갑이나 DEX로 전송합니다. '
            '앱 내부 현금 환전 API는 특정금융정보법 준수를 위해 제공하지 않습니다.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          SegmentedButton<Web3TransferChannel>(
            segments: Web3TransferChannel.values
                .map(
                  (channel) => ButtonSegment(
                    value: channel,
                    label: Text(channel.label),
                  ),
                )
                .toList(),
            selected: {_channel},
            onSelectionChanged: widget.transferring
                ? null
                : (selection) {
                    setState(() => _channel = selection.first);
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            enabled: !widget.transferring,
            decoration: InputDecoration(
              labelText: '수신 지갑 주소 (0x...)',
              hintText: 'MetaMask / 외부 지갑 주소',
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-Fx]')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            enabled: !widget.transferring,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '전송 SRV 수량',
              helperText: '보유: ${widget.valueTokenBalance} SRV',
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.transferring ? null : _submit,
            icon: widget.transferring
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              widget.transferring
                  ? '전송 중...'
                  : _channel == Web3TransferChannel.externalWallet
                      ? '외부 지갑으로 전송'
                      : 'DEX로 전송',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final address = _addressController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 Ethereum 지갑 주소(0x...)를 입력해 주세요.')),
      );
      return;
    }
    if (amount <= 0 || amount > widget.valueTokenBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전송 수량을 확인해 주세요.')),
      );
      return;
    }

    await widget.onTransfer(
      destinationAddress: address,
      amountSrv: amount,
      channel: _channel,
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'currency_service.dart';

void main() => runApp(const CurrencyApp());

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Currency Converter',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    home: const ConverterScreen(),
  );
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _amountCtrl = TextEditingController(text: '100');
  late Future<Rates> _future;
  String _from = 'USD';
  String _to = 'ETB';
  int _swapTurns = 0;

  @override
  void initState() {
    super.initState();
    _future = fetchRates();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;

  void _reload() => setState(() => _future = fetchRates());

  void _swap() => setState(() {
    final t = _from;
    _from = _to;
    _to = t;
    _swapTurns++;
  });

  Future<void> _pick(Rates rates, bool isFrom) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CurrencyPicker(codes: rates.rates.keys.toList()..sort()),
    );
    if (code == null) return;
    setState(() {
      if (isFrom) {
        _from = code;
      } else {
        _to = code;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Rates>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48),
                      const SizedBox(height: 12),
                      const Text('Could not load rates'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return _buildContent(snap.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Rates rates) {
    final unit = (rates.rates[_to] ?? 1) / (rates.rates[_from] ?? 1);
    final result = _amount * unit;
    final updated = rates.updated.split(' ').take(4).join(' ');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Currency Converter',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Live exchange rates',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                _CurrencyCard(
                  label: 'From',
                  code: _from,
                  onTapCode: () => _pick(rates, true),
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.]'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CurrencyCard(
                  label: 'To',
                  code: _to,
                  onTapCode: () => _pick(rates, false),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      fmt(result),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _swap,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 12),
                  ],
                ),
                child: AnimatedRotation(
                  turns: _swapTurns / 2,
                  duration: const Duration(milliseconds: 350),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '1 $_from = ${unit.toStringAsFixed(4)} $_to',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Updated $updated',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final String label, code;
  final VoidCallback onTapCode;
  final Widget child;
  const _CurrencyCard({
    required this.label,
    required this.code,
    required this.onTapCode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: child),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onTapCode,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CodeBadge(code),
                          const SizedBox(width: 8),
                          Text(
                            code,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String code;
  const _CodeBadge(this.code);

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [Color(0xFF7B61FF), Color(0xFF00D4FF)],
      ),
    ),
    child: Text(
      code,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class CurrencyPicker extends StatefulWidget {
  final List<String> codes;
  const CurrencyPicker({super.key, required this.codes});

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = widget.codes.where((c) {
      final name = (currencyNames[c] ?? '').toLowerCase();
      return c.toLowerCase().contains(q) || name.contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF16213E),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Search currency',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return ListTile(
                    leading: _CodeBadge(c),
                    title: Text(c),
                    subtitle: Text(currencyNames[c] ?? ''),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

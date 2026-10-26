import "package:candlestick_master/core/theme/app_theme.dart";
import "package:candlestick_master/models/trade_model.dart";
import "package:candlestick_master/providers/trade_notifier.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

class TradeFormScreen extends StatefulWidget {
  final Trade? trade;

  const TradeFormScreen({super.key, this.trade});

  @override
  State<TradeFormScreen> createState() => _TradeFormScreenState();
}

class _TradeFormScreenState extends State<TradeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _symbolController;
  late TextEditingController _entryPriceController;
  late TextEditingController _exitPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _stopLossController;
  late TextEditingController _takeProfitController;
  late TextEditingController _notesController;
  late TextEditingController _tagsController;

  late TradeType _tradeType;
  late TradeStatus _status;
  late DateTime _entryDate;
  DateTime? _exitDate;

  bool get isEditing => widget.trade != null;

  @override
  void initState() {
    super.initState();
    final t = widget.trade;
    _tradeType = t?.tradeType ?? TradeType.long;
    _status = t?.status ?? TradeStatus.open;
    _entryDate = t?.entryDate ?? DateTime.now();
    _exitDate = t?.exitDate;

    _symbolController = TextEditingController(text: t?.symbol ?? "");
    _entryPriceController =
        TextEditingController(text: t != null ? t.entryPrice.toString() : "");
    _exitPriceController = TextEditingController(
        text: t?.exitPrice != null ? t!.exitPrice.toString() : "");
    _quantityController =
        TextEditingController(text: t != null ? t.quantity.toString() : "1");
    _stopLossController = TextEditingController(
        text: t?.stopLoss != null ? t!.stopLoss.toString() : "");
    _takeProfitController = TextEditingController(
        text: t?.takeProfit != null ? t!.takeProfit.toString() : "");
    _notesController = TextEditingController(text: t?.notes ?? "");
    _tagsController = TextEditingController(text: t?.tags.join(", ") ?? "");
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _entryPriceController.dispose();
    _exitPriceController.dispose();
    _quantityController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isEntry) async {
    final initialDate = isEntry ? _entryDate : (_exitDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isEntry) {
          _entryDate = picked;
        } else {
          _exitDate = picked;
        }
      });
    }
  }

  List<String> _parseTags(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(",")
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final symbol = _symbolController.text.trim().toUpperCase();
    final entryPrice = double.tryParse(_entryPriceController.text.trim()) ?? 0;
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 1;
    final exitPrice = _status == TradeStatus.closed
        ? double.tryParse(_exitPriceController.text.trim())
        : null;
    final stopLoss = _stopLossController.text.trim().isNotEmpty
        ? double.tryParse(_stopLossController.text.trim())
        : null;
    final takeProfit = _takeProfitController.text.trim().isNotEmpty
        ? double.tryParse(_takeProfitController.text.trim())
        : null;
    final notes = _notesController.text.trim();
    final tags = _parseTags(_tagsController.text);

    final tradeNotifier = context.read<TradeNotifier>();

    if (isEditing) {
      final updated = widget.trade!.copyWith(
        symbol: symbol,
        tradeType: _tradeType,
        entryPrice: entryPrice,
        exitPrice: exitPrice,
        quantity: quantity,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
        entryDate: _entryDate,
        exitDate: _status == TradeStatus.closed ? (_exitDate ?? DateTime.now()) : null,
        notes: notes,
        tags: tags,
      );
      await tradeNotifier.updateTrade(updated);
    } else {
      await tradeNotifier.addTrade(
        symbol: symbol,
        tradeType: _tradeType,
        entryPrice: entryPrice,
        quantity: quantity,
        exitPrice: exitPrice,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
        entryDate: _entryDate,
        exitDate: _status == TradeStatus.closed ? (_exitDate ?? DateTime.now()) : null,
        notes: notes,
        tags: tags,
      );
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? "Edit Trade" : "Log Trade"),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trade Type Selector (Long / Short)
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      title: "LONG",
                      type: TradeType.long,
                      color: AppColors.bullish,
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      title: "SHORT",
                      type: TradeType.short,
                      color: AppColors.bearish,
                      icon: Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Selector (Open / Closed)
              Row(
                children: [
                  Expanded(
                    child: _buildStatusButton(
                      title: "Open Position",
                      status: TradeStatus.open,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusButton(
                      title: "Closed Position",
                      status: TradeStatus.closed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Symbol
              TextFormField(
                controller: _symbolController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  label: "Symbol / Pair",
                  hint: "e.g. BTC/USDT, NIFTY, AAPL",
                  icon: Icons.label_outline,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter a symbol";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Entry Price & Quantity Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _entryPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: "Entry Price",
                        hint: "0.00",
                        icon: Icons.attach_money,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Required";
                        }
                        if (double.tryParse(val.trim()) == null) {
                          return "Invalid";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: "Quantity / Lots",
                        hint: "1.0",
                        icon: Icons.pie_chart_outline,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Required";
                        }
                        if (double.tryParse(val.trim()) == null) {
                          return "Invalid";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Exit Price (if closed)
              if (_status == TradeStatus.closed) ...[
                TextFormField(
                  controller: _exitPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    label: "Exit Price",
                    hint: "0.00",
                    icon: Icons.exit_to_app,
                  ),
                  validator: (val) {
                    if (_status == TradeStatus.closed) {
                      if (val == null || val.trim().isEmpty) {
                        return "Please enter exit price for closed trades";
                      }
                      if (double.tryParse(val.trim()) == null) {
                        return "Invalid price";
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Stop Loss & Take Profit Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stopLossController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: "Stop Loss (Opt)",
                        hint: "0.00",
                        icon: Icons.shield_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _takeProfitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: "Take Profit (Opt)",
                        hint: "0.00",
                        icon: Icons.flag_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Pickers Row
              Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                      label: "Entry Date",
                      date: _entryDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  if (_status == TradeStatus.closed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateTile(
                        label: "Exit Date",
                        date: _exitDate ?? DateTime.now(),
                        onTap: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  label: "Tags (Comma separated)",
                  hint: "Breakout, Hammer, RSI, Support",
                  icon: Icons.sell_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  label: "Strategy Notes & Reflections",
                  hint: "Why did you take this trade? What did you learn?",
                  icon: Icons.notes,
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? "Update Trade" : "Save Trade to Journal",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String title,
    required TradeType type,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _tradeType == type;
    return InkWell(
      onTap: () => setState(() => _tradeType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String title,
    required TradeStatus status,
  }) {
    final isSelected = _status == status;
    return InkWell(
      onTap: () => setState(() => _status = status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceRaised : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}",
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

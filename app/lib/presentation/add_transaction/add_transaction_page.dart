import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/amount/amount_input.dart';
import '../../domain/catalog/chi_cho_catalog.dart';
import '../../domain/catalog/payment_option_catalog.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';
import '../theme/app_colors.dart';
import '../theme/category_look.dart';
import 'add_transaction_controller.dart';
import 'add_transaction_copy.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key, required this.controller});

  final AddTransactionController controller;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final FocusNode _amountFocus;

  AddTransactionController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: AmountInput.formatGrouped(_c.draft.amount),
    );
    _note = TextEditingController(text: _c.draft.note);
    _amountFocus = FocusNode();
    _c.addListener(_syncFields);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  void _syncFields() {
    final formatted = AmountInput.formatGrouped(_c.draft.amount);
    if (_amount.text != formatted) {
      _amount.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  void dispose() {
    _c.removeListener(_syncFields);
    _amount.dispose();
    _note.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final result = await _c.save();
    if (!mounted) return;
    if (result is Ok) {
      Navigator.of(context).pop(true);
      return;
    }
    if (_c.draft.amount <= 0) {
      _amountFocus.requestFocus();
    }
  }

  Future<void> _pickDate() async {
    final current = _c.draft.occurredOn;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 1),
    );
    if (picked != null) _c.setOccurredOn(picked);
  }

  Future<void> _pickTime() async {
    final parts = _c.draft.occurredTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final asDateTime = DateTime(2026, 1, 1, picked.hour, picked.minute);
    _c.setOccurredTime(formatHHmm(asDateTime));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.text),
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            centerTitle: true,
            title: const Text(
              AddTransactionCopy.title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
                  children: [
                    const _FieldLabel(AddTransactionCopy.amountLabel),
                    _AmountField(
                      controller: _amount,
                      focusNode: _amountFocus,
                      onChanged: _c.setAmountFromRaw,
                    ),
                    const SizedBox(height: 12),
                    _QuickAmounts(
                      active: _c.draft.activeShortcut,
                      onTap: _c.applyShortcut,
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(AddTransactionCopy.chiCho),
                    _ChiChoGrid(
                      selectedId: _c.draft.categoryId,
                      onSelect: _c.selectCategory,
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(AddTransactionCopy.detail),
                    _DetailChips(
                      options: _c.draft.detailOptions,
                      selected: _c.draft.detail,
                      onToggle: _c.toggleDetail,
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(AddTransactionCopy.payWith),
                    _PaySelect(
                      selected: _c.draft.payment,
                      onSelect: _c.selectPayment,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(AddTransactionCopy.date),
                              _BoxButton(
                                label: formatIsoDate(_c.draft.occurredOn),
                                onTap: _pickDate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(AddTransactionCopy.time),
                              _BoxButton(
                                label: _c.draft.occurredTime,
                                onTap: _pickTime,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(AddTransactionCopy.note),
                    TextField(
                      key: const Key('input-note'),
                      controller: _note,
                      onChanged: _c.setNote,
                      textInputAction: TextInputAction.done,
                      decoration: _filledDecoration(
                        hint: AddTransactionCopy.noteHint,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: AppColors.card,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    14 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_c.error != null) ...[
                        Text(
                          _c.error!,
                          key: const Key('add-tx-error'),
                          style: const TextStyle(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          key: const Key('btn-save-tx'),
                          onPressed: _c.saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AddTransactionCopy.save,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

InputDecoration _filledDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.textTertiary,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: AppColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

class _VndAmountFormatter extends TextInputFormatter {
  const _VndAmountFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final amount = AmountInput.parse(newValue.text);
    final text = AmountInput.formatGrouped(amount);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('input-amount'),
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: const [_VndAmountFormatter()],
      onChanged: onChanged,
      style: GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: AppColors.text,
      ),
      decoration: _filledDecoration(hint: '0').copyWith(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Text(
            '₫',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      ),
    );
  }
}

class _QuickAmounts extends StatelessWidget {
  const _QuickAmounts({required this.active, required this.onTap});

  final int? active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < AmountInput.shortcuts.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _QuickChip(
              amount: AmountInput.shortcuts[i],
              label: AmountInput.shortcutLabels[i],
              selected: active == AmountInput.shortcuts[i],
              onTap: onTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.amount,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final String label;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          key: Key('quick-amt-$amount'),
          onTap: () => onTap(amount),
          borderRadius: BorderRadius.circular(999),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChiChoGrid extends StatelessWidget {
  const _ChiChoGrid({required this.selectedId, required this.onSelect});

  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.72,
      children: [
        for (final category in ChiChoCatalog.all)
          _CatOption(
            id: category.id,
            selected: selectedId == category.id,
            onTap: () => onSelect(category.id),
          ),
      ],
    );
  }
}

class _CatOption extends StatelessWidget {
  const _CatOption({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(id);
    return Material(
      color: selected ? AppColors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('chi-cho-$id'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: look.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(look.icon, color: look.color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                look.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChips extends StatelessWidget {
  const _DetailChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in options)
          Material(
            color: selected == name ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => onToggle(name),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected == name ? AppColors.primary : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected == name ? AppColors.onPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PaySelect extends StatefulWidget {
  const _PaySelect({required this.selected, required this.onSelect});

  final PaymentOption selected;
  final ValueChanged<String> onSelect;

  @override
  State<_PaySelect> createState() => _PaySelectState();
}

class _PaySelectState extends State<_PaySelect> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BoxButton(
          key: const Key('pay-select'),
          label: widget.selected.pickerLabel,
          trailing: Icons.expand_more,
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x0D1A1D26)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F1A1D26),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (final option in PaymentOptionCatalog.all)
                  InkWell(
                    key: Key('pay-${option.source.id}'),
                    onTap: () {
                      widget.onSelect(option.source.id);
                      setState(() => _open = false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: option.source.id == widget.selected.source.id
                                ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                                : null,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.source.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  option.typeLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BoxButton extends StatelessWidget {
  const _BoxButton({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (trailing != null)
                  Icon(trailing, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/jv2.dart';
import 'listing_api.dart';
import 'listing_draft.dart';

const double kListPad = 20;
const Color _aiFill = Color(0x0FB8893D);

class SparkIcon extends StatelessWidget {
  final double size;
  final Color color;
  const SparkIcon({super.key, this.size = 11, this.color = JV2.goldHi});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.auto_awesome_rounded, size: size, color: color);
}

/// "Jeeran" mark on a field the assistant filled, until the seller touches it.
class AiTag extends StatelessWidget {
  const AiTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: JV2.goldFilm,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: JV2.goldEdge),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SparkIcon(size: 9),
        SizedBox(width: 4),
        Text(
          'Jeeran',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: JV2.gold,
          ),
        ),
      ],
    ),
  );
}

class FieldLabel extends StatelessWidget {
  final String text;
  final bool ai;
  final bool optional;
  const FieldLabel(
    this.text, {
    super.key,
    this.ai = false,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: JV2.ink,
            ),
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 7),
          Text(
            'listing.optional'.tr(),
            style: const TextStyle(fontSize: 11, color: JV2.inkMute),
          ),
        ],
        if (ai) ...[const Spacer(), const AiTag()],
      ],
    ),
  );
}

/// A text field in the design's look. [onChanged] fires with the raw text.
class ListingInput extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint, prefix, suffix, note;
  final bool ai, optional, numeric, multiline;
  final Key? fieldKey;
  const ListingInput({
    super.key,
    this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.prefix,
    this.suffix,
    this.note,
    this.ai = false,
    this.optional = false,
    this.numeric = false,
    this.multiline = false,
  });

  @override
  State<ListingInput> createState() => _ListingInputState();
}

class _ListingInputState extends State<ListingInput> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(ListingInput old) {
    super.didUpdateWidget(old);
    // the assistant (or "write it for me") may change the value from outside
    if (widget.value != _c.text && widget.value != old.value)
      _c.text = widget.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label, ai: widget.ai, optional: widget.optional),
        Container(
          constraints: BoxConstraints(minHeight: widget.multiline ? 96 : 50),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.ai ? _aiFill : JV2.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.ai ? JV2.goldEdge : JV2.line),
          ),
          child: Row(
            children: [
              if (widget.prefix != null) ...[
                Text(
                  widget.prefix!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: JV2.inkSub,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  key: widget.fieldKey,
                  controller: _c,
                  onChanged: widget.onChanged,
                  keyboardType: widget.numeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : (widget.multiline
                            ? TextInputType.multiline
                            : TextInputType.text),
                  inputFormatters: widget.numeric
                      ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                      : null,
                  minLines: widget.multiline ? 3 : 1,
                  maxLines: widget.multiline ? 8 : 1,
                  style: const TextStyle(fontSize: 15, color: JV2.ink),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: JV2.inkMute,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (widget.suffix != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.suffix!,
                  style: const TextStyle(fontSize: 13, color: JV2.inkSub),
                ),
              ],
            ],
          ),
        ),
        if (widget.note != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              widget.note!,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: JV2.inkSub,
              ),
            ),
          ),
      ],
    );
  }
}

/// One-of-many chips; tapping the chosen one again clears it when [clearable].
class ChipPicker extends StatelessWidget {
  final String label;
  final List<(String value, String text)> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool ai, clearable;
  final int? cols;
  const ChipPicker({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.ai = false,
    this.clearable = false,
    this.cols,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip((String, String) o) {
      final on = o.$1 == value;
      return GestureDetector(
        onTap: () => onChanged(on && clearable ? null : o.$1),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? (ai ? const Color(0x1FB8893D) : JV2.navy) : JV2.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: on ? (ai ? JV2.goldEdge : JV2.navy) : JV2.line,
            ),
          ),
          child: Text(
            o.$2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: on ? FontWeight.w600 : FontWeight.w500,
              color: on ? (ai ? JV2.gold : Colors.white) : JV2.ink,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, ai: ai),
        if (cols != null)
          LayoutBuilder(
            builder: (_, c) {
              final w = (c.maxWidth - 8 * (cols! - 1)) / cols!;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in options) SizedBox(width: w, child: chip(o)),
                ],
              );
            },
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final o in options) chip(o)],
          ),
      ],
    );
  }
}

class CounterField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool ai;
  final int min, max;
  const CounterField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.ai = false,
    this.min = 0,
    this.max = 30,
  });

  @override
  Widget build(BuildContext context) {
    Widget b(IconData i, VoidCallback f) => GestureDetector(
      onTap: f,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: JV2.fillFaint,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: JV2.line),
        ),
        child: Icon(i, size: 18, color: JV2.ink),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, ai: ai),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: ai ? _aiFill : JV2.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ai ? JV2.goldEdge : JV2.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              b(
                Icons.remove_rounded,
                () => value > min ? onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: JV2.ink,
                ),
              ),
              b(
                Icons.add_rounded,
                () => value < max ? onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String money(num n) {
  if (n >= 1e6) {
    final m = n / 1e6;
    return '${m.toStringAsFixed(m >= 10 ? 1 : 2).replaceFirst(RegExp(r'\.?0+$'), '')}M';
  }
  return '${(n / 1000).round()}K';
}

String grouped(num n) => NumberFormat('#,###').format(n);

/// Bottom sheet that picks the compound a listing belongs to.
class CompoundPicker extends StatefulWidget {
  final ListingApi api;
  final bool ar;
  const CompoundPicker({required this.api, required this.ar});

  @override
  State<CompoundPicker> createState() => CompoundPickerState();
}

class CompoundPickerState extends State<CompoundPicker> {
  List<CompoundRef>? _all;
  bool _failed = false;
  String _q = '';

  @override
  void initState() {
    super.initState();
    widget.api
        .compounds()
        .then((l) {
          if (mounted) setState(() => _all = l);
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = (_all ?? [])
        .where(
          (c) =>
              q.isEmpty ||
              '${c.nameAr} ${c.nameEn} ${c.developerEn ?? ''} ${c.developerAr ?? ''}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kListPad, 18, kListPad, 10),
                child: TextField(
                  key: const Key('compound-search'),
                  autofocus: false,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'listing.search_compound'.tr(),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: JV2.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: JV2.line),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _all == null
                    ? Center(
                        child: _failed
                            ? Text('listing.load_failed'.tr())
                            : const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: JV2.goldHi,
                              ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kListPad,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => ListTile(
                          key: Key('compound-${list[i].id}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            list[i].name(widget.ar),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: list[i].sub(widget.ar).isEmpty
                              ? null
                              : Text(
                                  list[i].sub(widget.ar),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => Navigator.pop(context, list[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Several choices at once (a unit can be a corner unit with a roof and parking).
class MultiChipPicker extends StatelessWidget {
  final String label;
  final List<(String value, String text)> options;
  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;
  const MultiChipPicker({
    super.key,
    required this.label,
    required this.options,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip((String, String) o) {
      final on = values.contains(o.$1);
      return GestureDetector(
        key: Key('extra-${o.$1}'),
        onTap: () =>
            onChanged(on ? ({...values}..remove(o.$1)) : {...values, o.$1}),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? JV2.navy : JV2.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? JV2.navy : JV2.line),
          ),
          child: Text(
            o.$2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: on ? FontWeight.w600 : FontWeight.w500,
              color: on ? Colors.white : JV2.ink,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, optional: true),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final o in options) chip(o)],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import 'tag_chip.dart';

class PaygSection extends StatefulWidget {
  const PaygSection({super.key});

  @override
  State<PaygSection> createState() => _PaygSectionState();
}

class _PaygSectionState extends State<PaygSection> {
  int _paygPick = 1;

  static const _paygPacks = [
    (ads: 1, price: 5, save: ''),
    (ads: 3, price: 13, save: '13%'),
    (ads: 10, price: 39, save: '22%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'plans.no_commitment'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'plans.payg_desc'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ..._paygPacks.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final on = _paygPick == i;
            return GestureDetector(
              onTap: () => setState(() => _paygPick = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: on ? AppColors.primary : AppColors.hairline,
                    width: on ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: Text(
                          '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: on ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ' ',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (p.save.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                TagChip(
                                  label: 'plans.save_percent'.tr(
                                    namedArgs: {'percent': p.save},
                                  ),
                                  tone: TagTone.gold,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ' ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: ' ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        children: const [
                          TextSpan(
                            text: 'JOD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

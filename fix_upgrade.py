# fix_upgrade.py
with open('lib/features/plans/presentation/widgets/upgrade_promo_card.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the literal backslash-comma pattern with proper Dart string
text = text.replace("                  '\\',", "                  '\$price',")
text = text.replace("                  '\$ads ads',", "                  '\$ads ads',")
text = text.replace("                  '\$price JOD/mo',", "                  '\$price JOD/mo',")
text = text.replace("                  '\$ads ads',", "                  '\$ads ads',")

with open('lib/features/plans/presentation/widgets/upgrade_promo_card.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('Fixed upgrade_promo_card.dart')

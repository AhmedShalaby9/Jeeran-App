import re

# Fix upgrade_promo_card.dart
with open('lib/features/plans/presentation/widgets/upgrade_promo_card.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "                  '\\'," in line and i > 0 and 'price' in lines[i-1]:
        lines[i] = line.replace("                  '\\',", "                  '\$price',")
    if "                  '\$ads ads'," in line:
        lines[i] = lines[i].replace("\$ads", "$ads")

with open('lib/features/plans/presentation/widgets/upgrade_promo_card.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

# Fix subscription_status_card.dart
with open('lib/features/subscription/presentation/widgets/subscription_status_card.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "                            '\\'," in line:
        if i > 3 and 'total - used' in lines[i-3]:
            lines[i] = line.replace("                            '\\',", "                            '\${total - used}',")
        elif i > 3 and 'used' in lines[i-3] and 'total' in lines[i-3]:
            lines[i] = line.replace("                            '\\',", "                            '\$used of \$total listings used',")
    if "\$used/\$total" in line:
        lines[i] = lines[i].replace("\$used", "$used").replace("\$total", "$total")

with open('lib/features/subscription/presentation/widgets/subscription_status_card.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Done')

import json
with open('assets/translations/ar.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

data['auth'] = {
    'welcome_back': 'مرحباً بك',
    'enter_phone': 'سوقك العقاري. أدخل رقم هاتفك للمتابعة.',
    'phone_number': 'رقم الهاتف',
    'phone_hint': '100 234 5678',
    'phone_helper': 'سنتحقق مما إذا كان لديك حساب. لا يوجد رمز تحقق مطلوب.',
    'continue': 'متابعة',
    'or_sign_in_with': 'أو سجل الدخول عبر',
    'apple': 'آبل',
    'google': 'جوجل',
    'terms_prefix': 'بالاستمرار فإنك توافق على ',
    'terms_of_service': 'شروط الخدمة',
    'privacy_policy': 'سياسة الخصوصية',
    'terms_connector': ' و',
    'select_country_code': 'اختر رمز الدولة',
    'create_profile': 'أنشئ ملفك الشخصي',
    'more_about_you': 'المزيد عنك',
    'step_required': 'معلومات مطلوبة',
    'step_optional': 'تفاصيل اختيارية',
    'add_profile_photo': 'أضف صورة الملف الشخصي',
    'optional': 'اختياري',
    'full_name': 'الاسم الكامل',
    'name_hint': 'مثال: أحمد الشلبي',
    'email': 'عنوان البريد الإلكتروني',
    'email_hint': 'you@example.com',
    'email_helper': 'البريد الإلكتروني غير مُحقق — فقط للإشعارات.',
    'gender': 'الجنس',
    'select_gender': 'اختر الجنس',
    'male': 'ذكر',
    'female': 'أنثى',
    'prefer_not_to_say': 'أفضل عدم القول',
    'date_of_birth': 'تاريخ الميلاد',
    'select_date': 'اختر التاريخ',
    'country': 'الدولة',
    'city': 'المدينة',
    'select_city': 'اختر المدينة',
    'referral_code': 'رمز الإحالة',
    'referral_hint': 'أدخل الرمز (اختياري)',
    'referral_helper': 'لديك رمز صديق؟ تحصلان معاً على مكافأة.',
    'skip': 'تخطي',
    'complete_setup': 'إكمال الإعداد',
}

with open('assets/translations/ar.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print('ar.json updated')

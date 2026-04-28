import json
with open('assets/translations/en.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

data['auth'] = {
    'welcome_back': 'Welcome back',
    'enter_phone': 'Your real estate marketplace. Enter your phone to continue.',
    'phone_number': 'Phone number',
    'phone_hint': '100 234 5678',
    'phone_helper': "We'll check if you have an account. No OTP, no verification needed.",
    'continue': 'Continue',
    'or_sign_in_with': 'or sign in with',
    'apple': 'Apple',
    'google': 'Google',
    'terms_prefix': 'By continuing you agree to our ',
    'terms_of_service': 'Terms of Service',
    'privacy_policy': 'Privacy Policy',
    'terms_connector': ' and ',
    'select_country_code': 'Select country code',
    'create_profile': 'Create your profile',
    'more_about_you': 'A little more about you',
    'step_required': 'Required info',
    'step_optional': 'Optional details',
    'add_profile_photo': 'Add profile photo',
    'optional': 'Optional',
    'full_name': 'Full name',
    'name_hint': 'e.g. Ahmed Shalabi',
    'email': 'Email address',
    'email_hint': 'you@example.com',
    'email_helper': 'Email is not verified — just for notifications.',
    'gender': 'Gender',
    'select_gender': 'Select gender',
    'male': 'Male',
    'female': 'Female',
    'prefer_not_to_say': 'Prefer not to say',
    'date_of_birth': 'Date of birth',
    'select_date': 'Select date',
    'country': 'Country',
    'city': 'City',
    'select_city': 'Select city',
    'referral_code': 'Referral code',
    'referral_hint': 'Enter code (optional)',
    'referral_helper': "Have a friend's code? You both get a reward.",
    'skip': 'Skip',
    'complete_setup': 'Complete setup',
}

with open('assets/translations/en.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print('en.json updated')

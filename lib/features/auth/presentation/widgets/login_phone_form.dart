import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/utils/app_colors.dart';
import 'auth_primary_button.dart';

// ─── Country data ──────────────────────────────────────────────────────────────

class _CountryInfo {
  final String name;
  final String flag;
  final String dialCode;
  final IsoCode isoCode;

  const _CountryInfo(this.name, this.flag, this.dialCode, this.isoCode);
}

const _countries = [
  // Egypt pinned first
  _CountryInfo('Egypt',                          '🇪🇬', '+20',   IsoCode.EG),
  // Rest alphabetical
  _CountryInfo('Afghanistan',                    '🇦🇫', '+93',   IsoCode.AF),
  _CountryInfo('Albania',                        '🇦🇱', '+355',  IsoCode.AL),
  _CountryInfo('Algeria',                        '🇩🇿', '+213',  IsoCode.DZ),
  _CountryInfo('American Samoa',                 '🇦🇸', '+1684', IsoCode.AS),
  _CountryInfo('Andorra',                        '🇦🇩', '+376',  IsoCode.AD),
  _CountryInfo('Angola',                         '🇦🇴', '+244',  IsoCode.AO),
  _CountryInfo('Anguilla',                       '🇦🇮', '+1264', IsoCode.AI),
  _CountryInfo('Antigua and Barbuda',            '🇦🇬', '+1268', IsoCode.AG),
  _CountryInfo('Argentina',                      '🇦🇷', '+54',   IsoCode.AR),
  _CountryInfo('Armenia',                        '🇦🇲', '+374',  IsoCode.AM),
  _CountryInfo('Aruba',                          '🇦🇼', '+297',  IsoCode.AW),
  _CountryInfo('Australia',                      '🇦🇺', '+61',   IsoCode.AU),
  _CountryInfo('Austria',                        '🇦🇹', '+43',   IsoCode.AT),
  _CountryInfo('Azerbaijan',                     '🇦🇿', '+994',  IsoCode.AZ),
  _CountryInfo('Bahamas',                        '🇧🇸', '+1242', IsoCode.BS),
  _CountryInfo('Bahrain',                        '🇧🇭', '+973',  IsoCode.BH),
  _CountryInfo('Bangladesh',                     '🇧🇩', '+880',  IsoCode.BD),
  _CountryInfo('Barbados',                       '🇧🇧', '+1246', IsoCode.BB),
  _CountryInfo('Belarus',                        '🇧🇾', '+375',  IsoCode.BY),
  _CountryInfo('Belgium',                        '🇧🇪', '+32',   IsoCode.BE),
  _CountryInfo('Belize',                         '🇧🇿', '+501',  IsoCode.BZ),
  _CountryInfo('Benin',                          '🇧🇯', '+229',  IsoCode.BJ),
  _CountryInfo('Bermuda',                        '🇧🇲', '+1441', IsoCode.BM),
  _CountryInfo('Bhutan',                         '🇧🇹', '+975',  IsoCode.BT),
  _CountryInfo('Bolivia',                        '🇧🇴', '+591',  IsoCode.BO),
  _CountryInfo('Bosnia and Herzegovina',         '🇧🇦', '+387',  IsoCode.BA),
  _CountryInfo('Botswana',                       '🇧🇼', '+267',  IsoCode.BW),
  _CountryInfo('Brazil',                         '🇧🇷', '+55',   IsoCode.BR),
  _CountryInfo('British Virgin Islands',         '🇻🇬', '+1284', IsoCode.VG),
  _CountryInfo('Brunei',                         '🇧🇳', '+673',  IsoCode.BN),
  _CountryInfo('Bulgaria',                       '🇧🇬', '+359',  IsoCode.BG),
  _CountryInfo('Burkina Faso',                   '🇧🇫', '+226',  IsoCode.BF),
  _CountryInfo('Burundi',                        '🇧🇮', '+257',  IsoCode.BI),
  _CountryInfo('Cambodia',                       '🇰🇭', '+855',  IsoCode.KH),
  _CountryInfo('Cameroon',                       '🇨🇲', '+237',  IsoCode.CM),
  _CountryInfo('Canada',                         '🇨🇦', '+1',    IsoCode.CA),
  _CountryInfo('Cape Verde',                     '🇨🇻', '+238',  IsoCode.CV),
  _CountryInfo('Cayman Islands',                 '🇰🇾', '+1345', IsoCode.KY),
  _CountryInfo('Central African Republic',       '🇨🇫', '+236',  IsoCode.CF),
  _CountryInfo('Chad',                           '🇹🇩', '+235',  IsoCode.TD),
  _CountryInfo('Chile',                          '🇨🇱', '+56',   IsoCode.CL),
  _CountryInfo('China',                          '🇨🇳', '+86',   IsoCode.CN),
  _CountryInfo('Colombia',                       '🇨🇴', '+57',   IsoCode.CO),
  _CountryInfo('Comoros',                        '🇰🇲', '+269',  IsoCode.KM),
  _CountryInfo('Cook Islands',                   '🇨🇰', '+682',  IsoCode.CK),
  _CountryInfo('Costa Rica',                     '🇨🇷', '+506',  IsoCode.CR),
  _CountryInfo('Croatia',                        '🇭🇷', '+385',  IsoCode.HR),
  _CountryInfo('Cuba',                           '🇨🇺', '+53',   IsoCode.CU),
  _CountryInfo('Cyprus',                         '🇨🇾', '+357',  IsoCode.CY),
  _CountryInfo('Czech Republic',                 '🇨🇿', '+420',  IsoCode.CZ),
  _CountryInfo('DR Congo',                       '🇨🇩', '+243',  IsoCode.CD),
  _CountryInfo('Denmark',                        '🇩🇰', '+45',   IsoCode.DK),
  _CountryInfo('Djibouti',                       '🇩🇯', '+253',  IsoCode.DJ),
  _CountryInfo('Dominica',                       '🇩🇲', '+1767', IsoCode.DM),
  _CountryInfo('Dominican Republic',             '🇩🇴', '+1809', IsoCode.DO),
  _CountryInfo('Ecuador',                        '🇪🇨', '+593',  IsoCode.EC),
  _CountryInfo('El Salvador',                    '🇸🇻', '+503',  IsoCode.SV),
  _CountryInfo('Equatorial Guinea',              '🇬🇶', '+240',  IsoCode.GQ),
  _CountryInfo('Eritrea',                        '🇪🇷', '+291',  IsoCode.ER),
  _CountryInfo('Estonia',                        '🇪🇪', '+372',  IsoCode.EE),
  _CountryInfo('Eswatini',                       '🇸🇿', '+268',  IsoCode.SZ),
  _CountryInfo('Ethiopia',                       '🇪🇹', '+251',  IsoCode.ET),
  _CountryInfo('Falkland Islands',               '🇫🇰', '+500',  IsoCode.FK),
  _CountryInfo('Faroe Islands',                  '🇫🇴', '+298',  IsoCode.FO),
  _CountryInfo('Fiji',                           '🇫🇯', '+679',  IsoCode.FJ),
  _CountryInfo('Finland',                        '🇫🇮', '+358',  IsoCode.FI),
  _CountryInfo('France',                         '🇫🇷', '+33',   IsoCode.FR),
  _CountryInfo('French Guiana',                  '🇬🇫', '+594',  IsoCode.GF),
  _CountryInfo('French Polynesia',               '🇵🇫', '+689',  IsoCode.PF),
  _CountryInfo('Gabon',                          '🇬🇦', '+241',  IsoCode.GA),
  _CountryInfo('Gambia',                         '🇬🇲', '+220',  IsoCode.GM),
  _CountryInfo('Georgia',                        '🇬🇪', '+995',  IsoCode.GE),
  _CountryInfo('Germany',                        '🇩🇪', '+49',   IsoCode.DE),
  _CountryInfo('Ghana',                          '🇬🇭', '+233',  IsoCode.GH),
  _CountryInfo('Gibraltar',                      '🇬🇮', '+350',  IsoCode.GI),
  _CountryInfo('Greece',                         '🇬🇷', '+30',   IsoCode.GR),
  _CountryInfo('Greenland',                      '🇬🇱', '+299',  IsoCode.GL),
  _CountryInfo('Grenada',                        '🇬🇩', '+1473', IsoCode.GD),
  _CountryInfo('Guadeloupe',                     '🇬🇵', '+590',  IsoCode.GP),
  _CountryInfo('Guam',                           '🇬🇺', '+1671', IsoCode.GU),
  _CountryInfo('Guatemala',                      '🇬🇹', '+502',  IsoCode.GT),
  _CountryInfo('Guinea',                         '🇬🇳', '+224',  IsoCode.GN),
  _CountryInfo('Guinea-Bissau',                  '🇬🇼', '+245',  IsoCode.GW),
  _CountryInfo('Guyana',                         '🇬🇾', '+592',  IsoCode.GY),
  _CountryInfo('Haiti',                          '🇭🇹', '+509',  IsoCode.HT),
  _CountryInfo('Honduras',                       '🇭🇳', '+504',  IsoCode.HN),
  _CountryInfo('Hong Kong',                      '🇭🇰', '+852',  IsoCode.HK),
  _CountryInfo('Hungary',                        '🇭🇺', '+36',   IsoCode.HU),
  _CountryInfo('Iceland',                        '🇮🇸', '+354',  IsoCode.IS),
  _CountryInfo('India',                          '🇮🇳', '+91',   IsoCode.IN),
  _CountryInfo('Indonesia',                      '🇮🇩', '+62',   IsoCode.ID),
  _CountryInfo('Iran',                           '🇮🇷', '+98',   IsoCode.IR),
  _CountryInfo('Iraq',                           '🇮🇶', '+964',  IsoCode.IQ),
  _CountryInfo('Ireland',                        '🇮🇪', '+353',  IsoCode.IE),
  _CountryInfo('Israel',                         '🇮🇱', '+972',  IsoCode.IL),
  _CountryInfo('Italy',                          '🇮🇹', '+39',   IsoCode.IT),
  _CountryInfo('Ivory Coast',                    '🇨🇮', '+225',  IsoCode.CI),
  _CountryInfo('Jamaica',                        '🇯🇲', '+1876', IsoCode.JM),
  _CountryInfo('Japan',                          '🇯🇵', '+81',   IsoCode.JP),
  _CountryInfo('Jordan',                         '🇯🇴', '+962',  IsoCode.JO),
  _CountryInfo('Kazakhstan',                     '🇰🇿', '+7',    IsoCode.KZ),
  _CountryInfo('Kenya',                          '🇰🇪', '+254',  IsoCode.KE),
  _CountryInfo('Kiribati',                       '🇰🇮', '+686',  IsoCode.KI),
  _CountryInfo('Kosovo',                         '🇽🇰', '+383',  IsoCode.XK),
  _CountryInfo('Kuwait',                         '🇰🇼', '+965',  IsoCode.KW),
  _CountryInfo('Kyrgyzstan',                     '🇰🇬', '+996',  IsoCode.KG),
  _CountryInfo('Laos',                           '🇱🇦', '+856',  IsoCode.LA),
  _CountryInfo('Latvia',                         '🇱🇻', '+371',  IsoCode.LV),
  _CountryInfo('Lebanon',                        '🇱🇧', '+961',  IsoCode.LB),
  _CountryInfo('Lesotho',                        '🇱🇸', '+266',  IsoCode.LS),
  _CountryInfo('Liberia',                        '🇱🇷', '+231',  IsoCode.LR),
  _CountryInfo('Libya',                          '🇱🇾', '+218',  IsoCode.LY),
  _CountryInfo('Liechtenstein',                  '🇱🇮', '+423',  IsoCode.LI),
  _CountryInfo('Lithuania',                      '🇱🇹', '+370',  IsoCode.LT),
  _CountryInfo('Luxembourg',                     '🇱🇺', '+352',  IsoCode.LU),
  _CountryInfo('Macau',                          '🇲🇴', '+853',  IsoCode.MO),
  _CountryInfo('Madagascar',                     '🇲🇬', '+261',  IsoCode.MG),
  _CountryInfo('Malawi',                         '🇲🇼', '+265',  IsoCode.MW),
  _CountryInfo('Malaysia',                       '🇲🇾', '+60',   IsoCode.MY),
  _CountryInfo('Maldives',                       '🇲🇻', '+960',  IsoCode.MV),
  _CountryInfo('Mali',                           '🇲🇱', '+223',  IsoCode.ML),
  _CountryInfo('Malta',                          '🇲🇹', '+356',  IsoCode.MT),
  _CountryInfo('Marshall Islands',               '🇲🇭', '+692',  IsoCode.MH),
  _CountryInfo('Martinique',                     '🇲🇶', '+596',  IsoCode.MQ),
  _CountryInfo('Mauritania',                     '🇲🇷', '+222',  IsoCode.MR),
  _CountryInfo('Mauritius',                      '🇲🇺', '+230',  IsoCode.MU),
  _CountryInfo('Mexico',                         '🇲🇽', '+52',   IsoCode.MX),
  _CountryInfo('Micronesia',                     '🇫🇲', '+691',  IsoCode.FM),
  _CountryInfo('Moldova',                        '🇲🇩', '+373',  IsoCode.MD),
  _CountryInfo('Monaco',                         '🇲🇨', '+377',  IsoCode.MC),
  _CountryInfo('Mongolia',                       '🇲🇳', '+976',  IsoCode.MN),
  _CountryInfo('Montenegro',                     '🇲🇪', '+382',  IsoCode.ME),
  _CountryInfo('Montserrat',                     '🇲🇸', '+1664', IsoCode.MS),
  _CountryInfo('Morocco',                        '🇲🇦', '+212',  IsoCode.MA),
  _CountryInfo('Mozambique',                     '🇲🇿', '+258',  IsoCode.MZ),
  _CountryInfo('Myanmar',                        '🇲🇲', '+95',   IsoCode.MM),
  _CountryInfo('Namibia',                        '🇳🇦', '+264',  IsoCode.NA),
  _CountryInfo('Nauru',                          '🇳🇷', '+674',  IsoCode.NR),
  _CountryInfo('Nepal',                          '🇳🇵', '+977',  IsoCode.NP),
  _CountryInfo('Netherlands',                    '🇳🇱', '+31',   IsoCode.NL),
  _CountryInfo('New Caledonia',                  '🇳🇨', '+687',  IsoCode.NC),
  _CountryInfo('New Zealand',                    '🇳🇿', '+64',   IsoCode.NZ),
  _CountryInfo('Nicaragua',                      '🇳🇮', '+505',  IsoCode.NI),
  _CountryInfo('Niger',                          '🇳🇪', '+227',  IsoCode.NE),
  _CountryInfo('Nigeria',                        '🇳🇬', '+234',  IsoCode.NG),
  _CountryInfo('North Korea',                    '🇰🇵', '+850',  IsoCode.KP),
  _CountryInfo('North Macedonia',               '🇲🇰', '+389',  IsoCode.MK),
  _CountryInfo('Northern Mariana Islands',       '🇲🇵', '+1670', IsoCode.MP),
  _CountryInfo('Norway',                         '🇳🇴', '+47',   IsoCode.NO),
  _CountryInfo('Oman',                           '🇴🇲', '+968',  IsoCode.OM),
  _CountryInfo('Pakistan',                       '🇵🇰', '+92',   IsoCode.PK),
  _CountryInfo('Palau',                          '🇵🇼', '+680',  IsoCode.PW),
  _CountryInfo('Palestine',                      '🇵🇸', '+970',  IsoCode.PS),
  _CountryInfo('Panama',                         '🇵🇦', '+507',  IsoCode.PA),
  _CountryInfo('Papua New Guinea',               '🇵🇬', '+675',  IsoCode.PG),
  _CountryInfo('Paraguay',                       '🇵🇾', '+595',  IsoCode.PY),
  _CountryInfo('Peru',                           '🇵🇪', '+51',   IsoCode.PE),
  _CountryInfo('Philippines',                    '🇵🇭', '+63',   IsoCode.PH),
  _CountryInfo('Poland',                         '🇵🇱', '+48',   IsoCode.PL),
  _CountryInfo('Portugal',                       '🇵🇹', '+351',  IsoCode.PT),
  _CountryInfo('Puerto Rico',                    '🇵🇷', '+1787', IsoCode.PR),
  _CountryInfo('Qatar',                          '🇶🇦', '+974',  IsoCode.QA),
  _CountryInfo('Republic of the Congo',          '🇨🇬', '+242',  IsoCode.CG),
  _CountryInfo('Réunion',                        '🇷🇪', '+262',  IsoCode.RE),
  _CountryInfo('Romania',                        '🇷🇴', '+40',   IsoCode.RO),
  _CountryInfo('Russia',                         '🇷🇺', '+7',    IsoCode.RU),
  _CountryInfo('Rwanda',                         '🇷🇼', '+250',  IsoCode.RW),
  _CountryInfo('Saint Kitts and Nevis',          '🇰🇳', '+1869', IsoCode.KN),
  _CountryInfo('Saint Lucia',                    '🇱🇨', '+1758', IsoCode.LC),
  _CountryInfo('Saint Pierre and Miquelon',      '🇵🇲', '+508',  IsoCode.PM),
  _CountryInfo('Saint Vincent and the Grenadines','🇻🇨', '+1784', IsoCode.VC),
  _CountryInfo('Samoa',                          '🇼🇸', '+685',  IsoCode.WS),
  _CountryInfo('San Marino',                     '🇸🇲', '+378',  IsoCode.SM),
  _CountryInfo('São Tomé and Príncipe',          '🇸🇹', '+239',  IsoCode.ST),
  _CountryInfo('Saudi Arabia',                   '🇸🇦', '+966',  IsoCode.SA),
  _CountryInfo('Senegal',                        '🇸🇳', '+221',  IsoCode.SN),
  _CountryInfo('Serbia',                         '🇷🇸', '+381',  IsoCode.RS),
  _CountryInfo('Seychelles',                     '🇸🇨', '+248',  IsoCode.SC),
  _CountryInfo('Sierra Leone',                   '🇸🇱', '+232',  IsoCode.SL),
  _CountryInfo('Singapore',                      '🇸🇬', '+65',   IsoCode.SG),
  _CountryInfo('Sint Maarten',                   '🇸🇽', '+1721', IsoCode.SX),
  _CountryInfo('Slovakia',                       '🇸🇰', '+421',  IsoCode.SK),
  _CountryInfo('Slovenia',                       '🇸🇮', '+386',  IsoCode.SI),
  _CountryInfo('Solomon Islands',                '🇸🇧', '+677',  IsoCode.SB),
  _CountryInfo('Somalia',                        '🇸🇴', '+252',  IsoCode.SO),
  _CountryInfo('South Africa',                   '🇿🇦', '+27',   IsoCode.ZA),
  _CountryInfo('South Korea',                    '🇰🇷', '+82',   IsoCode.KR),
  _CountryInfo('South Sudan',                    '🇸🇸', '+211',  IsoCode.SS),
  _CountryInfo('Spain',                          '🇪🇸', '+34',   IsoCode.ES),
  _CountryInfo('Sri Lanka',                      '🇱🇰', '+94',   IsoCode.LK),
  _CountryInfo('Sudan',                          '🇸🇩', '+249',  IsoCode.SD),
  _CountryInfo('Suriname',                       '🇸🇷', '+597',  IsoCode.SR),
  _CountryInfo('Sweden',                         '🇸🇪', '+46',   IsoCode.SE),
  _CountryInfo('Switzerland',                    '🇨🇭', '+41',   IsoCode.CH),
  _CountryInfo('Syria',                          '🇸🇾', '+963',  IsoCode.SY),
  _CountryInfo('Taiwan',                         '🇹🇼', '+886',  IsoCode.TW),
  _CountryInfo('Tajikistan',                     '🇹🇯', '+992',  IsoCode.TJ),
  _CountryInfo('Tanzania',                       '🇹🇿', '+255',  IsoCode.TZ),
  _CountryInfo('Thailand',                       '🇹🇭', '+66',   IsoCode.TH),
  _CountryInfo('Timor-Leste',                    '🇹🇱', '+670',  IsoCode.TL),
  _CountryInfo('Togo',                           '🇹🇬', '+228',  IsoCode.TG),
  _CountryInfo('Tonga',                          '🇹🇴', '+676',  IsoCode.TO),
  _CountryInfo('Trinidad and Tobago',            '🇹🇹', '+1868', IsoCode.TT),
  _CountryInfo('Tunisia',                        '🇹🇳', '+216',  IsoCode.TN),
  _CountryInfo('Turkey',                         '🇹🇷', '+90',   IsoCode.TR),
  _CountryInfo('Turkmenistan',                   '🇹🇲', '+993',  IsoCode.TM),
  _CountryInfo('Turks and Caicos Islands',       '🇹🇨', '+1649', IsoCode.TC),
  _CountryInfo('Tuvalu',                         '🇹🇻', '+688',  IsoCode.TV),
  _CountryInfo('UAE',                            '🇦🇪', '+971',  IsoCode.AE),
  _CountryInfo('Uganda',                         '🇺🇬', '+256',  IsoCode.UG),
  _CountryInfo('Ukraine',                        '🇺🇦', '+380',  IsoCode.UA),
  _CountryInfo('United Kingdom',                 '🇬🇧', '+44',   IsoCode.GB),
  _CountryInfo('United States',                  '🇺🇸', '+1',    IsoCode.US),
  _CountryInfo('Uruguay',                        '🇺🇾', '+598',  IsoCode.UY),
  _CountryInfo('US Virgin Islands',              '🇻🇮', '+1340', IsoCode.VI),
  _CountryInfo('Uzbekistan',                     '🇺🇿', '+998',  IsoCode.UZ),
  _CountryInfo('Vanuatu',                        '🇻🇺', '+678',  IsoCode.VU),
  _CountryInfo('Venezuela',                      '🇻🇪', '+58',   IsoCode.VE),
  _CountryInfo('Vietnam',                        '🇻🇳', '+84',   IsoCode.VN),
  _CountryInfo('Wallis and Futuna',              '🇼🇫', '+681',  IsoCode.WF),
  _CountryInfo('Yemen',                          '🇾🇪', '+967',  IsoCode.YE),
  _CountryInfo('Zambia',                         '🇿🇲', '+260',  IsoCode.ZM),
  _CountryInfo('Zimbabwe',                       '🇿🇼', '+263',  IsoCode.ZW),
];

// ─── Widget ───────────────────────────────────────────────────────────────────

class LoginPhoneForm extends StatefulWidget {
  final bool isLoading;
  final ValueChanged<String> onContinue;

  const LoginPhoneForm({
    super.key,
    required this.isLoading,
    required this.onContinue,
  });

  @override
  State<LoginPhoneForm> createState() => _LoginPhoneFormState();
}

class _LoginPhoneFormState extends State<LoginPhoneForm> {
  final _phoneCtrl = TextEditingController();
  bool _valid = false;
  bool _termsAccepted = false;
  _CountryInfo _selectedCountry = _countries.first; // Egypt default

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_validatePhone);
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (_valid) setState(() => _valid = false);
      return;
    }
    bool isValid = false;
    try {
      final parsed = PhoneNumber.parse(
        digits,
        callerCountry: _selectedCountry.isoCode,
      );
      isValid = parsed.isValid();
    } catch (_) {
      isValid = false;
    }
    if (isValid != _valid) setState(() => _valid = isValid);
  }

  void _onContinue() {
    if (!_valid || !_termsAccepted || widget.isLoading) return;
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    try {
      final parsed = PhoneNumber.parse(digits, callerCountry: _selectedCountry.isoCode);
      widget.onContinue(parsed.international);
    } catch (_) {
      // Fallback — shouldn't happen when _valid is true
      widget.onContinue('${_selectedCountry.dialCode}$digits');
    }
  }

  void _openCountryPicker() {
    showModalBottomSheet<_CountryInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CountryPickerSheet(
        selected: _selectedCountry,
        onSelect: (c) {
          setState(() {
            _selectedCountry = c;
          });
          _validatePhone();
        },
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    final lang = context.locale.languageCode;
    final html = AppSettingsService.instance.terms(lang);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'auth.terms_of_service'.tr(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.inkSub),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: html != null && html.isNotEmpty
                    ? Html(
                        data: html,
                        style: {
                          'body': Style(
                            fontSize: FontSize(14),
                            color: AppColors.inkSub,
                            lineHeight: LineHeight(1.65),
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          'h1, h2, h3': Style(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          'a': Style(color: AppColors.secondary),
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Content coming soon',
                            style: TextStyle(fontSize: 14, color: AppColors.grey),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'auth.phone_number'.tr(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Country code picker button
              GestureDetector(
                onTap: _openCountryPicker,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry.dialCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppColors.inkSub),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                    ],
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.ink,
                      letterSpacing: 0.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'auth.phone_hint'.tr(),
                      hintStyle: const TextStyle(
                        color: AppColors.inkMute,
                        fontSize: 17,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.hairline,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.hairline,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'auth.phone_helper'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            label: 'auth.continue'.tr(),
            enabled: _valid && _termsAccepted && !widget.isLoading,
            onTap: _onContinue,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'auth.agree_terms_prefix'.tr(),
                style:
                    const TextStyle(fontSize: 13, color: AppColors.inkSub),
              ),
              GestureDetector(
                onTap: () => _showTermsDialog(context),
                child: Text(
                  'auth.terms_of_service'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Country Picker Bottom Sheet ──────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final _CountryInfo selected;
  final ValueChanged<_CountryInfo> onSelect;

  const _CountryPickerSheet({required this.selected, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<_CountryInfo> _filtered = _countries;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _countries
          : _countries
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.dialCode.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Select Country',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Search country...',
                hintStyle:
                    const TextStyle(color: AppColors.inkMute, fontSize: 15),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.inkSub),
                filled: true,
                fillColor: const Color(0xFFF5F6F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.hairline, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.hairline, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No results',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.inkMute),
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final c = _filtered[i];
                      final isSelected =
                          c.isoCode == widget.selected.isoCode;
                      return ListTile(
                        leading: Text(c.flag,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.ink,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          c.dialCode,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.inkSub,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor:
                            AppColors.primary.withOpacity(0.06),
                        onTap: () {
                          widget.onSelect(c);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

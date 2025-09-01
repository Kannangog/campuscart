class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  @override
  String toString() => '$dialCode ($name)';

  // List of common countries
  static List<Country> get countries => [
    const Country(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    const Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    const Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    const Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    const Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    const Country(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    const Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    const Country(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    const Country(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    const Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    const Country(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
    const Country(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
    const Country(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
    const Country(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    const Country(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
    const Country(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
    const Country(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    const Country(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
    const Country(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
    const Country(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
  ];
}
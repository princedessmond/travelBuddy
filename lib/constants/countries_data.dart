class CountryData {
  final String name;
  final String code;
  final String flag;
  final String currencyCode;
  final String currencyName;
  final String greeting;
  final String funFact;
  final String emojiScene;

  CountryData({
    required this.name,
    required this.code,
    required this.flag,
    required this.currencyCode,
    required this.currencyName,
    required this.greeting,
    required this.funFact,
    required this.emojiScene,
  });
}

class CountriesData {
  static final List<CountryData> countries = [
    CountryData(
      name: 'South Africa',
      code: 'ZA',
      flag: '🇿🇦',
      currencyCode: 'ZAR',
      currencyName: 'South African Rand',
      greeting: 'Sawubona!',
      funFact: 'Home to Table Mountain & safari adventures!',
      emojiScene: '🦁🌍🏔️',
    ),
    CountryData(
      name: 'Egypt',
      code: 'EG',
      flag: '🇪🇬',
      currencyCode: 'EGP',
      currencyName: 'Egyptian Pound',
      greeting: 'Marhaban!',
      funFact: 'The pyramids are over 4,500 years old!',
      emojiScene: '🏜️🐪🔺',
    ),
    CountryData(
      name: 'Tanzania',
      code: 'TZ',
      flag: '🇹🇿',
      currencyCode: 'TZS',
      currencyName: 'Tanzanian Shilling',
      greeting: 'Jambo!',
      funFact: 'Home to Mount Kilimanjaro & Serengeti!',
      emojiScene: '🏔️🦒🌅',
    ),
    CountryData(
      name: 'Rwanda',
      code: 'RW',
      flag: '🇷🇼',
      currencyCode: 'RWF',
      currencyName: 'Rwandan Franc',
      greeting: 'Muraho!',
      funFact: 'The land of a thousand hills & mountain gorillas!',
      emojiScene: '🦍🌄🌿',
    ),
    CountryData(
      name: 'Kenya',
      code: 'KE',
      flag: '🇰🇪',
      currencyCode: 'KES',
      currencyName: 'Kenyan Shilling',
      greeting: 'Jambo!',
      funFact: 'Witness the Great Migration in Maasai Mara!',
      emojiScene: '🦒🌅🦓',
    ),
    CountryData(
      name: 'Morocco',
      code: 'MA',
      flag: '🇲🇦',
      currencyCode: 'MAD',
      currencyName: 'Moroccan Dirham',
      greeting: 'Salam!',
      funFact: 'Explore vibrant souks & blue Chefchaouen!',
      emojiScene: '🕌🐫🎨',
    ),
    CountryData(
      name: 'United States',
      code: 'US',
      flag: '🇺🇸',
      currencyCode: 'USD',
      currencyName: 'US Dollar',
      greeting: 'Hey there!',
      funFact: 'From NYC skyscrapers to Grand Canyon!',
      emojiScene: '🗽🌉🏙️',
    ),
    CountryData(
      name: 'United Kingdom',
      code: 'GB',
      flag: '🇬🇧',
      currencyCode: 'GBP',
      currencyName: 'British Pound',
      greeting: 'Hello!',
      funFact: 'Tea time at 4pm is a cherished tradition!',
      emojiScene: '🫖👑🏰',
    ),
    CountryData(
      name: 'France',
      code: 'FR',
      flag: '🇫🇷',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      greeting: 'Bonjour!',
      funFact: 'Home to the Eiffel Tower and finest cuisine!',
      emojiScene: '🗼🥐☕',
    ),
    CountryData(
      name: 'Germany',
      code: 'DE',
      flag: '🇩🇪',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      greeting: 'Guten Tag!',
      funFact: 'Over 1,500 kinds of beer and 20,000 castles!',
      emojiScene: '🏰🍺🥨',
    ),
    CountryData(
      name: 'Italy',
      code: 'IT',
      flag: '🇮🇹',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      greeting: 'Ciao!',
      funFact: 'The Colosseum could hold 50,000 spectators!',
      emojiScene: '🍕🏛️🍝',
    ),
    CountryData(
      name: 'Spain',
      code: 'ES',
      flag: '🇪🇸',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      greeting: 'Hola!',
      funFact: 'Birthplace of flamenco & siesta culture!',
      emojiScene: '💃🌞🥘',
    ),
    CountryData(
      name: 'Japan',
      code: 'JP',
      flag: '🇯🇵',
      currencyCode: 'JPY',
      currencyName: 'Japanese Yen',
      greeting: 'Konnichiwa!',
      funFact: 'Cherry blossoms bloom for just 2 weeks!',
      emojiScene: '🌸🗾🍣',
    ),
    CountryData(
      name: 'China',
      code: 'CN',
      flag: '🇨🇳',
      currencyCode: 'CNY',
      currencyName: 'Chinese Yuan',
      greeting: 'Nǐ hǎo!',
      funFact: 'The Great Wall stretches over 13,000 miles!',
      emojiScene: '🏯🐼🥟',
    ),
    CountryData(
      name: 'Thailand',
      code: 'TH',
      flag: '🇹🇭',
      currencyCode: 'THB',
      currencyName: 'Thai Baht',
      greeting: 'Sawasdee!',
      funFact: 'Land of Smiles with 40,000+ Buddhist temples!',
      emojiScene: '🛕🐘🌴',
    ),
    CountryData(
      name: 'India',
      code: 'IN',
      flag: '🇮🇳',
      currencyCode: 'INR',
      currencyName: 'Indian Rupee',
      greeting: 'Namaste!',
      funFact: 'The Taj Mahal changes color throughout the day!',
      emojiScene: '🕌🐅🪔',
    ),
    CountryData(
      name: 'United Arab Emirates',
      code: 'AE',
      flag: '🇦🇪',
      currencyCode: 'AED',
      currencyName: 'UAE Dirham',
      greeting: 'Marhaba!',
      funFact: 'Burj Khalifa is the world\'s tallest building!',
      emojiScene: '🏙️🏜️🐪',
    ),
    CountryData(
      name: 'Australia',
      code: 'AU',
      flag: '🇦🇺',
      currencyCode: 'AUD',
      currencyName: 'Australian Dollar',
      greeting: 'G\'day!',
      funFact: 'Home to 10,000+ beaches and unique wildlife!',
      emojiScene: '🦘🏖️🪃',
    ),
    CountryData(
      name: 'New Zealand',
      code: 'NZ',
      flag: '🇳🇿',
      currencyCode: 'NZD',
      currencyName: 'New Zealand Dollar',
      greeting: 'Kia ora!',
      funFact: 'Middle Earth comes alive in stunning landscapes!',
      emojiScene: '🏔️🥝🐑',
    ),
    CountryData(
      name: 'Canada',
      code: 'CA',
      flag: '🇨🇦',
      currencyCode: 'CAD',
      currencyName: 'Canadian Dollar',
      greeting: 'Hello / Bonjour!',
      funFact: 'More lakes than the rest of the world combined!',
      emojiScene: '🍁🏔️🦫',
    ),
    CountryData(
      name: 'Brazil',
      code: 'BR',
      flag: '🇧🇷',
      currencyCode: 'BRL',
      currencyName: 'Brazilian Real',
      greeting: 'Olá!',
      funFact: 'Rio Carnival is the world\'s biggest party!',
      emojiScene: '🎊⚽🦜',
    ),
    CountryData(
      name: 'Mexico',
      code: 'MX',
      flag: '🇲🇽',
      currencyCode: 'MXN',
      currencyName: 'Mexican Peso',
      greeting: '¡Hola!',
      funFact: 'Ancient Mayan pyramids & cenote swimming!',
      emojiScene: '🌮🏜️🦎',
    ),
    CountryData(
      name: 'Argentina',
      code: 'AR',
      flag: '🇦🇷',
      currencyCode: 'ARS',
      currencyName: 'Argentine Peso',
      greeting: '¡Hola!',
      funFact: 'Tango birthplace & world-class steak!',
      emojiScene: '💃🥩🍷',
    ),
    CountryData(
      name: 'Turkey',
      code: 'TR',
      flag: '🇹🇷',
      currencyCode: 'TRY',
      currencyName: 'Turkish Lira',
      greeting: 'Merhaba!',
      funFact: 'Istanbul bridges Europe & Asia!',
      emojiScene: '🕌🧿🫖',
    ),
    CountryData(
      name: 'Greece',
      code: 'GR',
      flag: '🇬🇷',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      greeting: 'Yassas!',
      funFact: 'Over 6,000 islands with stunning blue waters!',
      emojiScene: '🏛️🫒🌊',
    ),
    CountryData(
      name: 'Portugal',
      code: 'PT',
      flag: '🇵🇹',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      greeting: 'Olá!',
      funFact: 'Cork capital & birthplace of Port wine!',
      emojiScene: '🍷🌊🏰',
    ),
    CountryData(
      name: 'Netherlands',
      code: 'NL',
      flag: '🇳🇱',
      currencyCode: 'EUR',
      currencyName: 'Euro',
      greeting: 'Hallo!',
      funFact: 'More bicycles than people!',
      emojiScene: '🚲🌷🏘️',
    ),
    CountryData(
      name: 'Switzerland',
      code: 'CH',
      flag: '🇨🇭',
      currencyCode: 'CHF',
      currencyName: 'Swiss Franc',
      greeting: 'Grüezi!',
      funFact: 'Chocolates, watches & Alpine perfection!',
      emojiScene: '⛷️🍫⌚',
    ),
    CountryData(
      name: 'Sweden',
      code: 'SE',
      flag: '🇸🇪',
      currencyCode: 'SEK',
      currencyName: 'Swedish Krona',
      greeting: 'Hej!',
      funFact: 'Midnight sun in summer, Northern Lights in winter!',
      emojiScene: '🌌❄️🦌',
    ),
    CountryData(
      name: 'Norway',
      code: 'NO',
      flag: '🇳🇴',
      currencyCode: 'NOK',
      currencyName: 'Norwegian Krone',
      greeting: 'Hei!',
      funFact: 'Breathtaking fjords & Viking heritage!',
      emojiScene: '🛶🏔️🌊',
    ),
    CountryData(
      name: 'Denmark',
      code: 'DK',
      flag: '🇩🇰',
      currencyCode: 'DKK',
      currencyName: 'Danish Krone',
      greeting: 'Hej!',
      funFact: 'Happiest country & home of LEGO!',
      emojiScene: '🧱🚲🏰',
    ),
    CountryData(
      name: 'Singapore',
      code: 'SG',
      flag: '🇸🇬',
      currencyCode: 'SGD',
      currencyName: 'Singapore Dollar',
      greeting: 'Hello!',
      funFact: 'A garden city with futuristic architecture!',
      emojiScene: '🏙️🌳🦁',
    ),
    CountryData(
      name: 'Malaysia',
      code: 'MY',
      flag: '🇲🇾',
      currencyCode: 'MYR',
      currencyName: 'Malaysian Ringgit',
      greeting: 'Selamat datang!',
      funFact: 'Petronas Towers were world\'s tallest until 2004!',
      emojiScene: '🏙️🌴🦧',
    ),
    CountryData(
      name: 'Indonesia',
      code: 'ID',
      flag: '🇮🇩',
      currencyCode: 'IDR',
      currencyName: 'Indonesian Rupiah',
      greeting: 'Halo!',
      funFact: 'Over 17,000 islands with stunning beaches!',
      emojiScene: '🏝️🌋🦎',
    ),
    CountryData(
      name: 'South Korea',
      code: 'KR',
      flag: '🇰🇷',
      currencyCode: 'KRW',
      currencyName: 'South Korean Won',
      greeting: 'Annyeonghaseyo!',
      funFact: 'K-pop, kimchi & cutting-edge technology!',
      emojiScene: '🎤🥢🏙️',
    ),
    CountryData(
      name: 'Philippines',
      code: 'PH',
      flag: '🇵🇭',
      currencyCode: 'PHP',
      currencyName: 'Philippine Peso',
      greeting: 'Kumusta!',
      funFact: '7,641 islands with world-class diving!',
      emojiScene: '🏝️🤿🥥',
    ),
    CountryData(
      name: 'Vietnam',
      code: 'VN',
      flag: '🇻🇳',
      currencyCode: 'VND',
      currencyName: 'Vietnamese Dong',
      greeting: 'Xin chào!',
      funFact: 'Halong Bay has 1,600 limestone islands!',
      emojiScene: '🛶🍜🏮',
    ),
  ];

  static List<String> get countryNames =>
      countries.map((c) => c.name).toList();

  static List<String> get currencyCodes =>
      countries.map((c) => c.currencyCode).toSet().toList();

  static CountryData? getCountryByName(String name) {
    try {
      return countries.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  static CountryData? getCountryByCode(String code) {
    try {
      return countries.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }

  static List<CountryData> searchCountries(String query) {
    if (query.isEmpty) return countries;
    return countries
        .where((c) =>
            c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.currencyCode.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

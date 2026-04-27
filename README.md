# Travel Companion 🌍

Your intelligent travel planning companion powered by AI. Plan trips, track budgets, get personalized packing lists, and explore destinations with ease.

## Features

### Core Features
- **Trip Planning**: Select destinations with currency-specific budgeting
- **Smart Budget Tracking**: Track expenses in real-time with editable budgets and alerts
- **AI-Powered Itineraries**: Generate personalized day-by-day itineraries using Google Gemini AI
- **Intelligent Packing Lists**: Get AI-powered packing suggestions based on destination, weather, and trip duration
- **Weather Integration**: Real-time weather data and forecasts for your destination
- **Currency Conversion**: Live exchange rates for accurate budget planning
- **Trip History**: Archive and review past trips
- **Social Features**: Share trips with friends and family

### Advanced Features
- **Daily Trip Planning**: Plan activities and outfits for each day
- **Map Integration**: Visualize destinations with Google Maps
- **Offline Support**: Access trip data without internet connection
- **Multi-currency Support**: Track expenses in any currency
- **Budget Alerts**: Get notified when approaching or exceeding budget limits
- **Mascot Guide**: Interactive onboarding experience

## Tech Stack

- **Flutter**: Cross-platform mobile development (iOS & Android)
- **Provider**: State management
- **Google Gemini AI**: Itinerary generation and travel recommendations
- **Anthropic Claude**: Smart packing list suggestions
- **OpenWeatherMap API**: Weather data and forecasts
- **ExchangeRate-API**: Real-time currency conversion
- **Google Maps**: Location visualization
- **Local Storage**: Trip data persistence with shared_preferences

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- API Keys (see Configuration section)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/princedessmond/travelBuddy.git
cd travelBuddy
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure environment variables (see Configuration section below)

4. Run the app:
```bash
flutter run
```

## Configuration

### API Keys Setup

This app requires API keys for various services. All API keys are managed through environment variables for security.

1. Create a `.env` file in the project root:
```bash
cp .env.example .env
```

2. Add your API keys to the `.env` file:

```env
# Google Gemini AI API Key
# Get your free API key from: https://makersuite.google.com/app/apikey
GEMINI_API_KEY=your_gemini_api_key_here

# Anthropic Claude API Key
# Get your API key from: https://console.anthropic.com/
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# OpenWeather API Key
# Free tier: 60 calls/minute, 1,000,000 calls/month
# Get your API key from: https://openweathermap.org/api
OPENWEATHER_API_KEY=your_openweather_key_here

# Exchange Rate API Key
# Free tier: 1,500 requests/month
# Get your API key from: https://www.exchangerate-api.com/
EXCHANGE_RATE_API_KEY=your_exchange_rate_key_here
```

### Obtaining API Keys

#### Google Gemini AI (Free)
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. Copy the key to your `.env` file

#### Anthropic Claude (Free Trial)
1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Sign up for an account
3. Generate an API key
4. Copy the key to your `.env` file

#### OpenWeatherMap (Free Tier)
1. Visit [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Generate an API key
4. Copy the key to your `.env` file

#### ExchangeRate-API (Free Tier)
1. Visit [ExchangeRate-API](https://www.exchangerate-api.com/)
2. Sign up for a free account
3. Get your API key
4. Copy the key to your `.env` file

## Project Structure

```
lib/
├── constants/          # App constants and configuration
│   └── ai_config.dart # AI service configuration
├── models/            # Data models
├── providers/         # State management (Provider)
├── screens/           # UI screens
├── services/          # API services and business logic
│   ├── ai_packing_service.dart
│   ├── currency_service.dart
│   └── weather_service.dart
├── widgets/           # Reusable UI components
└── main.dart         # App entry point
```

## Security

- API keys are stored in `.env` file (not committed to git)
- `.env.example` template provided for setup
- All sensitive data excluded from version control via `.gitignore`
- Environment variables loaded securely using `flutter_dotenv`

**Important**: Never commit your `.env` file to version control!

## Development

### Running Tests
```bash
flutter test
```

### Building for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Gemini AI for intelligent itinerary generation
- Anthropic Claude for smart packing suggestions
- OpenWeatherMap for weather data
- ExchangeRate-API for currency conversion
- Flutter team for the amazing framework

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

Built with ❤️ using Flutter and AI

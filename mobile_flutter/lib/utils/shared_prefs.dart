import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtils {
  static const String _sizeKey = "captionSize";
  static const String _textColorKey = "captionTextColor";
  static const String _backgroundColorKey = "captionBackgroundColor";
  static const String _captionEnableStateKey = 'captionEnableState';

  static Future<void> storeCaptionEnableState(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_captionEnableStateKey, isEnabled);
  }

  static Future<bool> getCaptionEnableState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_captionEnableStateKey) ?? false; // Default to false
  }

  static Future<void> storeCaptionSize(double size) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sizeKey, size);
  }

  static Future<double> getCaptionSize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_sizeKey) ?? 50.0;
  }

  static Future<void> storeCaptionTextColor(String colorName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textColorKey, colorName);
  }

  static Future<String> getCaptionTextColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_textColorKey) ?? "black";
  }

  static Future<void> storeCaptionBackgroundColor(String colorName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundColorKey, colorName);
  }

  static Future<String> getCaptionBackgroundColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundColorKey) ?? "white";
  }

  static Future<void> storeTheme(String theme) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
  }

  static Future<String> getTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme') ?? 'Light';
  }

  static const String _languageKey = "selectedLanguage";

  static Future<void> storeLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'English';
  }

  static Future<void> storeWalkthrough(bool walkthrough) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWalkthrough', walkthrough);
  }

  static Future<bool> getWalkthrough() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isWalkthrough') ?? false;
  }

  static Future<String> getThemeAndWalkthrough() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme').toString();
  }

  static Future<void> storeTTSSettings(String language, String voice) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("TTS_language", language);
    await prefs.setString("TTS_voice", voice);
  }

  static Future<Map<String, String>> getTTSSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? language = prefs.getString("TTS_language");
    final String? voice = prefs.getString("TTS_voice");

    return {
      "language": language ?? "en-US",
      "voice": voice ?? "fil-ph-x-fie-local",
    };
  }

  static Future<void> storeAmplifierVolume(double volume) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('isAmplifierVolume', volume);
  }

  static Future<void> storeAudioBalanceLevel(double balance) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('isAudioBalanceLevel', balance);
  }

  static Future<void> storeDenoiseLevel(int level) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('isDenoiseLevel', level);
  }

  static Future<double> getAmplifierVolume() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('isAmplifierVolume') ?? 1.0;
  }

  static Future<int> getDenoiseLevel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('isDenoiseLevel') ?? -10;
  }

  static Future<void> storeTTSVoice(String voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("TTS_selectedVoice", voice);
  }

  static Future<String> getTTSVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("TTS_selectedVoice") ??
        "fil-ph-x-fie-local"; // default voice
  }

  static Future<void> storeTTSRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("TTS_selectedRate", rate);
  }

  static Future<double> getTTSRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble("TTS_selectedRate") ?? 0.5; // default rate
  }
}

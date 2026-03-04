class AIConfig {
  static const String apiKey =
      String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');
  static const String baseUrl = 'https://api.deepseek.com/v1';
  static const String model = 'deepseek-chat';
  static const String thinkingModel = 'deepseek-reasoner';
  static const double temperature = 0.1;

  static const String openaiApiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String openaiVisionModel = 'gpt-4o-mini';
}

class ApiConfig {
  static const String baseUrl = "http://10.0.2.2:8001";

  static String wsBaseUrl() {
    if (baseUrl.startsWith("https://")) {
      return baseUrl.replaceFirst("https://", "wss://");
    }
    if (baseUrl.startsWith("http://")) {
      return baseUrl.replaceFirst("http://", "ws://");
    }
    return baseUrl; // fallback
  }

  static String chatWsUrl({required int recipientId, required String token}) {
    return "${wsBaseUrl()}/ws/chat/$recipientId/?token=$token";
  }
}

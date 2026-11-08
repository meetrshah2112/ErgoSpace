/// Configure at run time:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000 --dart-define=RAZORPAY_KEY=rzp_test_xxx
class ApiConfig {
  static const baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');
  static const razorpayKey = String.fromEnvironment('RAZORPAY_KEY');

  /// Resolves absolute or relative media paths against the API origin.
  static String? media(String? p) {
    if (p == null || p.trim().isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final origin = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return p.startsWith('/') ? '$origin$p' : '$origin/$p';
  }
}

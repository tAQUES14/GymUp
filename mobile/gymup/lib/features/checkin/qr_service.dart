class QrService {
  static const String validQrPrefix = "GYMUP-ACADEMIA-";

  bool isValidQr(String? code) {
    if (code == null) return false;
    // Simple validation: check if it starts with the expected prefix
    // In a real app, you might validate a signed token or check against a list of valid IDs
    return code.startsWith(validQrPrefix);
  }
  
  String? extractGymId(String code) {
    if (!isValidQr(code)) return null;
    return code.replaceAll(validQrPrefix, "");
  }
}

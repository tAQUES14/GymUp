class QrService {
  bool isValidQr(String? code) {
    if (code == null) return false;
    final trimmed = code.trim();
    // Aceita qualquer token não vazio com pelo menos 8 caracteres.
    // A validação real (correspondência com o qr_token da academia) é feita pelo backend.
    return trimmed.length >= 8;
  }
}

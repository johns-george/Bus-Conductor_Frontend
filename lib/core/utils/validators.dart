class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[\w\.\-]+$');
  static final RegExp _phone = RegExp(r'^\d{7,15}$');

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    if (!_phone.hasMatch(v.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? notEmpty(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }
}

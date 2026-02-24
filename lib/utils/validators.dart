/// Utility functions for form validation.
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
    if (!emailRegex.hasMatch(value)) return 'Invalid email';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    // basic gabon phone pattern
    final phoneRegex = RegExp(r"^\+?\d{8,15}");
    if (!phoneRegex.hasMatch(value)) return 'Invalid phone';
    return null;
  }

  static String? validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }
}

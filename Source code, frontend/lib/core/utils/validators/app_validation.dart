
import 'package:pass_rate/core/extensions/strings_extensions.dart';

class AppValidation {
  AppValidation._();

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return "Email is required";
    }
    if (!email.isValidEmail()) {
      return "Invalid email address";
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return "Password is required";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must contain at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least one number";
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "Password must contain at least one special character";
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return "Confirm password is required";
    }
    if (password != confirmPassword) {
      return "Passwords do not match";
    }
    return null;
  }

  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return "Phone number is required";
    }

    final RegExp phoneRegExp = RegExp(r'^\+?[\d\s-]{10,15}$');

    if (!phoneRegExp.hasMatch(phoneNumber)) {
      return "Invalid phone number";
    }
    return null;
  }

  static String? validateRequired(String? value, {String fieldName = "Field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }

  static String? validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return "Username is required";
    }
    if (username.length < 3) {
      return "Username must be at least 3 characters";
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return "Username can only contain letters, numbers, and underscores";
    }
    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return "Name is required";
    }
    if (name.length < 2) {
      return "Name must be at least 2 characters";
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  static String? validateMinLength(String? value, int minLength, {String fieldName = "Field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    if (value.length < minLength) {
      return "$fieldName must be at least $minLength characters";
    }
    return null;
  }

  static String? validateMaxLength(String? value, int maxLength, {String fieldName = "Field"}) {
    if (value != null && value.length > maxLength) {
      return "$fieldName must not exceed $maxLength characters";
    }
    return null;
  }
}

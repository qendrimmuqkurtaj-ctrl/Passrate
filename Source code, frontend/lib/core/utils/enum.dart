enum ResultStatus {
  passed('Passed'),
  failed('Failed');

  const ResultStatus(this.displayName);

  final String displayName;

  // Optional: Add other useful properties
  bool get isSuccess => this == ResultStatus.passed;

  // Convert from string
  static ResultStatus? fromString(String value) {
    for (final ResultStatus status in ResultStatus.values) {
      if (status.displayName.toLowerCase() == value.toLowerCase()) {
        return status;
      }
    }
    return null;
  }
}

/// ResultStatus status = ResultStatus.passed;
/// status.displayName ===> ResultStatus.passed.displayName

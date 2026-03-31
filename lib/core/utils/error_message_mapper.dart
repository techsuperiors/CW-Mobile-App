class ErrorMessageMapper {
  ErrorMessageMapper._();

  static String toUserFriendlyMessage(String? rawMessage) {
    final message = (rawMessage ?? '').trim();
    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    final normalized = message.toLowerCase();

    if (normalized.contains("cannot read properties of null") &&
        normalized.contains("reading 'id'")) {
      return 'You do not have access to this section, or it is not configured for your role yet.';
    }

    if (normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection reset') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('software caused connection abort')) {
      return 'Please check your internet connection and try again.';
    }

    if (normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('permission')) {
      return 'You do not have permission to access this section.';
    }

    if (normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('internet')) {
      return 'Please check your internet connection and try again.';
    }

    if (normalized.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    if (normalized.contains('server') ||
        normalized.contains('500') ||
        normalized.contains('internal error')) {
      return 'Our server is having trouble right now. Please try again in a moment.';
    }

    if (normalized.contains('something went wrong') ||
        normalized.contains('failed to load') ||
        normalized.contains('failed to fetch') ||
        normalized.contains('instance of')) {
      return 'We could not load this data right now. Please try again.';
    }

    return message.length > 140
        ? 'We could not load this data right now. Please try again.'
        : message;
  }
}

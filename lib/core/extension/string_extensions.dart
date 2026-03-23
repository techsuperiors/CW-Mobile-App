extension StringCasingExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String toTitleCase() {
    return split(' ')
        .map((word) =>
    word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

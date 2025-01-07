/// Returns the plural form of a word based on the count
String pluralize(String word, int count) {
  if (count == 1) return word;
  return '${word}s';
}

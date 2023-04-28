class VersionComparator {
  static bool isVersion1Greater({required String v1, required String v2}) {
    int v1Number = getExtendedVersionNumber(v1);
    int v2Number = getExtendedVersionNumber(v2);
    return v1Number > v2Number;
  }

  static int getExtendedVersionNumber(String version) {
    List<String> stringVersionCells = version.split('.');
    List<int> intVersionCells = stringVersionCells.map((i) => int.parse(i)).toList();
    return intVersionCells[0] * 100000 + intVersionCells[1] * 1000 + intVersionCells[2];
  }
}

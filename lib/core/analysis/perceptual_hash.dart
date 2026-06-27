int hammingDistance(String a, String b) {
  if (a.length != b.length) return a.length;
  var dist = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) dist++;
  }
  return dist;
}

/// Near-identical copies, re-exports, or lightly edited versions.
const duplicateHammingThreshold = 5;

/// Burst shots and near-duplicates taken close together.
const similarHammingThreshold = 5;

/// Standard responsive grid column counts used across media grids.
int gridCrossAxisCountForWidth(
  double width, {
  int compact = 3,
  int medium = 4,
  int wide = 6,
}) {
  if (width > 1200) return wide;
  if (width > 800) return medium;
  return compact;
}

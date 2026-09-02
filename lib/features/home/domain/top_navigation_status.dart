class TopNavigationStatus {
  const TopNavigationStatus({
    required this.level,
    required this.xp,
    required this.hearts,
    required this.maxHearts,
    required this.experienceProgress,
  });

  final int level;
  final int xp;
  final int hearts;
  final int maxHearts;

  // The API currently exposes total xp, but not the current-level threshold.
  // Keep this presentation value at the mapping boundary until that rule is
  // defined by the backend contract.
  final double experienceProgress;
}

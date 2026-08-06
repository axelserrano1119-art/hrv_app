class ReadinessChecker {
  bool fingerDetected = false;
  bool flashStable = false;
  bool exposureStable = false;
  bool waveformDetected = false;
  bool movementLow = false;
  bool signalQualityGood = false;

  bool get ready =>
      fingerDetected &&
      flashStable &&
      exposureStable &&
      waveformDetected &&
      movementLow &&
      signalQualityGood;
}
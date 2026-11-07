/// Published delivery prices used by the landing page, order form and API.
const kStandardDeliveryFee = 8.0;
const kRemoteDeliveryFee = 9.0;
const kHeavyParcelThresholdKg = 10.0;
const kHeavyParcelFeePerKg = 1.0;

const kStandardGovernorates = {
  'Tunis',
  'Ariana',
  'Ben Arous',
  'Manouba',
  'Zaghouan',
  'Nabeul',
  'Bizerte',
  'Sousse',
  'Monastir',
  'Mahdia',
  'Sfax',
  'Beja',
  'Jendouba',
  'Le Kef',
  'Siliana',
};

/// Zone price up to 10 kg, then 1 DT per kg for the whole weight.
///
/// Prefer [tarif] from the référentiel when the picker supplies it so accents /
/// renames do not flip the zone. Fall back to the published name table.
double deliveryFeeFor({
  required String gouvernorat,
  required double kg,
  double? tarif,
}) {
  if (kg > kHeavyParcelThresholdKg) {
    return kg * kHeavyParcelFeePerKg;
  }
  if (tarif != null) return tarif;
  return kStandardGovernorates.contains(gouvernorat)
      ? kStandardDeliveryFee
      : kRemoteDeliveryFee;
}

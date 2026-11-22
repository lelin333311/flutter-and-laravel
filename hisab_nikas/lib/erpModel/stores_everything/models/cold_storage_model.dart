class ColdStorageFacility {
  final int? id;
  final String storageName; // e.g. Khulna Cold Storage
  final String chamberNo; // Chamber-01, Chamber-02
  final String address;
  final String phone;
  final int totalBagsStored; // e.g. 3000 Bosta
  final double totalWeightKg; // e.g. 150,000 Kg
  final double dailyRatePerBag; // ৳2/Bag/Day
  final double totalAccruedRent; // e.g. ৳60,000

  const ColdStorageFacility({
    this.id,
    required this.storageName,
    this.chamberNo = 'Chamber-01',
    this.address = 'Khulna Sadar',
    this.phone = '01700-000000',
    required this.totalBagsStored,
    required this.totalWeightKg,
    this.dailyRatePerBag = 2.0,
    required this.totalAccruedRent,
  });

  /// Calculates total rental cost for N days: Rent = Bags * Rate * Days
  double calculateRentForDays(int days) {
    return totalBagsStored * dailyRatePerBag * days;
  }
}

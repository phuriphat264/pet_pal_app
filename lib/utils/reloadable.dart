// Implemented by tab pages kept alive inside an IndexedStack (so their
// initState only runs once) that need to refresh their data whenever the
// bottom nav switches back to them -- e.g. after booking a hotel elsewhere,
// the Live Cam / Chat tabs need fresh data the next time they're tapped.
abstract class Reloadable {
  Future<void> reload();
}

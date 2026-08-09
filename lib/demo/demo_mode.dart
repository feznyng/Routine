/// Screenshot mode.
///
/// Off unless the build is passed `--dart-define=DEMO_MODE=true`, which makes
/// [enabled] a compile-time `false` in every normal build and lets the tree
/// shaker drop the seed data and the branches that read this flag.
///
/// Turning it on does two things:
///   * seeds the local database with a fixed set of routines (see
///     `demo_seed.dart`), replacing whatever was there;
///   * hides chrome that is honest in real use but only clutters a store
///     screenshot -- the block-permissions banner (Screen Time can never be
///     authorized in the Simulator), the signed-out banner, and the sync
///     snackbars.
///
/// Seeding refuses to run while signed in, because the seeded rows would
/// otherwise be pushed to that account on the next sync.
class DemoMode {
  const DemoMode._();

  static const bool enabled = bool.fromEnvironment('DEMO_MODE');
}

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/condition.dart';
import '../models/device.dart';
import '../setup.dart';
import 'demo_mode.dart';

/// Replaces the local routines, groups and stand-in devices with a fixed set
/// built for App Store screenshots. No-op unless [DemoMode.enabled].
///
/// Safe to run while signed in: demo builds open their own database file and
/// [SyncService] is disabled outright, so none of this can reach the account.
/// Rows are still written straight to drift rather than through [Routine.save],
/// which keeps every row's `changes` list empty and avoids the save path's
/// side effects.
Future<void> seedDemoData() async {
  if (!DemoMode.enabled) return;

  final db = getIt<AppDatabase>();
  final deviceId = getIt<Device>().id;
  final now = DateTime.now();

  // Two windows anchored to the current time, so the list always has something
  // in its Active and Completed sections whenever the screenshots are taken.
  // Both start on the half hour at or before now, which keeps the times on the
  // cards looking deliberate rather than like whatever o'clock it happens to be.
  final anchor = (_minutesOfDay(now) ~/ 30) * 30;
  final activeStart = _clampToDay(anchor - 60);
  final activeEnd = _clampToDay(anchor + 120);
  final completedStart = anchor;
  final completedEnd = _clampToDay(anchor + 90);

  await db.transaction(() async {
    await db.delete(db.routines).go();
    await db.delete(db.groups).go();
    // Only the stand-ins below -- never this device's own row, which the app
    // depends on and which getCurrent() would otherwise have to rebuild.
    await (db.delete(db.devices)..where((t) => t.id.isIn(_otherDevices.map((d) => d.id).toList()))).go();

    for (final device in _otherDevices) {
      await db.into(db.devices).insert(DevicesCompanion.insert(
            id: device.id,
            name: device.name,
            type: device.type.name,
            curr: false,
            changes: const [],
            updatedAt: now,
          ));
    }

    // Active now: the flagship card, mid-session with strict mode on, and the
    // one that carries a block group on every device. The routine detail page
    // lists one row per device, so this is where multi-device blocking shows.
    await _insert(
      db,
      now: now,
      slug: 'deep-work',
      name: 'Deep Work',
      days: _withToday(_weekdays, now),
      startTime: activeStart,
      endTime: activeEnd,
      groups: [
        // This device first: the routine card's chips read the current
        // device's group, so it is the one that has to look complete.
        (
          deviceId: deviceId,
          allow: false,
          apps: _apps(6),
          sites: const [
            'x.com',
            'reddit.com',
            'youtube.com',
            'news.ycombinator.com',
            'instagram.com',
          ],
        ),
        (
          deviceId: _macbook.id,
          allow: false,
          apps: _apps(4),
          sites: const ['x.com', 'reddit.com', 'youtube.com', 'news.ycombinator.com'],
        ),
        (
          deviceId: _windows.id,
          allow: false,
          apps: _apps(3),
          sites: const ['x.com', 'reddit.com', 'twitch.tv'],
        ),
      ],
      // Deliberately not strict: strict mode locks the detail page of a routine
      // that is currently active, replacing it with a warning banner, and this
      // is the routine whose detail page shows the per-device block groups.
      // Wind Down carries the strict flag instead.
      friction: 'delay',
      frictionLen: 30,
      maxBreaks: 2,
    );

    // Completed: conditions all met, so it renders under the Completed header.
    await _insert(
      db,
      now: now,
      slug: 'morning-reset',
      name: 'Morning Reset',
      days: _everyDay,
      startTime: completedStart,
      endTime: completedEnd,
      groups: [
        (deviceId: deviceId, allow: false, apps: _apps(9), sites: const ['x.com', 'tiktok.com', 'instagram.com']),
      ],
      completableBefore: 30,
      conditions: [
        Condition(
          id: 'demo-condition-gym',
          type: ConditionType.location,
          name: 'Arrive at the gym',
          latitude: 37.7749,
          longitude: -122.4194,
          proximity: 150,
          completedAt: now.subtract(const Duration(minutes: 12)),
        ),
        Condition(
          id: 'demo-condition-desk',
          type: ConditionType.nfc,
          name: 'Tap the tag on your desk',
          nfcQrCode: 'demo-tag',
          completedAt: now.subtract(const Duration(minutes: 4)),
        ),
      ],
    );

    // Upcoming: an allowlist, to show the other side of the block/allow toggle.
    await _insert(
      db,
      now: now,
      slug: 'study-session',
      name: 'Study Session',
      days: const [true, false, true, false, true, false, false],
      startTime: 18 * 60,
      endTime: 21 * 60,
      groups: [
        (
          deviceId: deviceId,
          allow: true,
          apps: _apps(3),
          sites: const ['notion.so', 'anki.web.app', 'wikipedia.org'],
        ),
      ],
      friction: 'code',
      frictionLen: 8,
      maxBreaks: 1,
    );

    // Upcoming: the everything-off evening block. Covers this device and the
    // laptop but not the desktop, so the detail page shows a "None" row too --
    // per-device groups are opt-in, not all-or-nothing.
    await _insert(
      db,
      now: now,
      slug: 'wind-down',
      name: 'Wind Down',
      days: _everyDay,
      startTime: 22 * 60,
      endTime: 23 * 60 + 30,
      groups: [
        (
          deviceId: deviceId,
          allow: false,
          apps: _apps(12),
          sites: const [
            'x.com',
            'reddit.com',
            'youtube.com',
            'netflix.com',
            'twitch.tv',
            'instagram.com',
            'tiktok.com',
          ],
        ),
        (
          deviceId: _macbook.id,
          allow: false,
          apps: _apps(7),
          sites: const ['x.com', 'reddit.com', 'youtube.com', 'netflix.com', 'twitch.tv'],
        ),
      ],
      // Safe to mark strict here: the routine is inactive at screenshot time,
      // so the chip shows on the card without locking anything.
      strictMode: true,
      friction: 'pomodoro',
      frictionLen: 25,
      maxBreaks: 0,
    );
  });

  logger.i('demo mode: seeded screenshot routines');
}

/// A routine's block list is per device, so showing that off needs devices
/// besides the one running the screenshot. These are plain rows in the devices
/// table -- the same thing a real sync would have pulled down from the other
/// machines on the account.
///
/// Deliberately no iPad or phone here: the current device already is one of
/// those depending on which simulator the recipe is pointed at, and a second
/// row with the same name reads as a bug rather than a second device.
typedef _DemoDevice = ({String id, String name, DeviceType type});

const _macbook = (id: 'demo-device-macbook', name: 'Macbook', type: DeviceType.macos);
const _windows = (id: 'demo-device-windows', name: 'Windows', type: DeviceType.windows);
const List<_DemoDevice> _otherDevices = [_macbook, _windows];

/// One device's share of a routine's block list.
typedef _GroupSpec = ({
  String deviceId,
  bool allow,
  List<String> apps,
  List<String> sites,
});

const _everyDay = [true, true, true, true, true, true, true];
const _weekdays = [true, true, true, true, true, false, false];

/// A routine only counts as active on a day it runs, so the card that has to be
/// active for the screenshot has today switched on regardless. On a weekday
/// this leaves the weekday set untouched; shooting on a weekend just lights up
/// one extra day on the card.
List<bool> _withToday(List<bool> days, DateTime now) {
  final today = now.weekday - 1;
  return [for (var i = 0; i < days.length; i++) days[i] || i == today];
}

int _minutesOfDay(DateTime t) => t.hour * 60 + t.minute;

/// Keeps a window inside the day. A window clamped at 23:59 stops covering
/// "now" only in the last minute before midnight, which is not a minute anyone
/// is taking store screenshots in.
int _clampToDay(int minutes) => minutes.clamp(0, 24 * 60 - 1);

/// Blocked apps are opaque Screen Time tokens on iOS and package names on
/// Android; nothing in the UI renders them by name, only counts, so
/// placeholders are enough to make the counts read right.
List<String> _apps(int count) => [for (var i = 0; i < count; i++) 'demo-app-$i'];

Future<void> _insert(
  AppDatabase db, {
  required DateTime now,
  required String slug,
  required String name,
  required List<bool> days,
  required int startTime,
  required int endTime,
  required List<_GroupSpec> groups,
  String friction = 'none',
  int? frictionLen,
  int? maxBreaks,
  bool strictMode = false,
  int completableBefore = 0,
  List<Condition> conditions = const [],
}) async {
  final groupIds = <String>[];

  // One group per device the routine covers. A device with no group here is a
  // device the routine does not block on, which the detail page shows as
  // "None" rather than hiding.
  for (var i = 0; i < groups.length; i++) {
    final spec = groups[i];
    final groupId = 'demo-group-$slug-$i';
    groupIds.add(groupId);

    await db.into(db.groups).insert(GroupsCompanion.insert(
          id: groupId,
          device: spec.deviceId,
          allow: spec.allow,
          apps: Value(spec.apps),
          sites: Value(spec.sites),
          changes: const [],
          updatedAt: now,
        ));
  }

  await db.into(db.routines).insert(RoutinesCompanion.insert(
        id: 'demo-routine-$slug',
        name: name,
        monday: days[0],
        tuesday: days[1],
        wednesday: days[2],
        thursday: days[3],
        friday: days[4],
        saturday: days[5],
        sunday: days[6],
        startTime: startTime,
        endTime: endTime,
        groups: groupIds,
        friction: friction,
        frictionLen: Value(frictionLen),
        maxBreaks: Value(maxBreaks),
        strictMode: Value(strictMode),
        completableBefore: Value(completableBefore),
        conditions: conditions,
        changes: const [],
        updatedAt: now,
      ));
}

import 'routine.dart';
import 'app_list.dart';
import 'package:uuid/uuid.dart';
import 'package:cron/cron.dart';


class Manager {
  static final Manager _instance = Manager._internal();
  
  final cron = Cron();
  final List<Routine> _routines = [];
  final Map<String, BlockList> _blockLists = {};
  final List<ScheduledTask> _scheduledTasks = [];

  Manager._internal() {
    // block lists
    String workBlockListId = Uuid().v4();
    BlockList workBlockList = BlockList(name: 'Work');
    workBlockList.sites = [
      "facebook.com",
      "youtube.com",
      "discord.com",
      "reddit.com",
      "news.ycombinator.com",
    ];

    workBlockList.apps = [
      'discord',
      'chrome',
      'safari'
    ];

    String everythingBlockListId = Uuid().v4();
    BlockList everythingBlockList = BlockList(name: 'Everything');
    everythingBlockList.allowList = true;

    _blockLists[workBlockListId] = workBlockList;
    _blockLists[everythingBlockListId] = everythingBlockList;

    // routines
    Routine morningRoutine = Routine(name: "Morning Work");
    morningRoutine.setTimeRange(9, 0, 12, 0);
    morningRoutine.blockId = workBlockListId;
    morningRoutine.numBreaks = 2;
    morningRoutine.maxBreakDuration = 20;

    Routine afternoonRoutine = Routine(name: "Afternoon Work");
    afternoonRoutine.setTimeRange(1, 0, 4, 0);
    afternoonRoutine.blockId = workBlockListId;
    afternoonRoutine.numBreaks = 2;
    afternoonRoutine.maxBreakDuration = 20;

    Routine exerciseRoutine = Routine(name: "Exercise");
    exerciseRoutine.setTimeRange(4, 0, 5, 0);
    exerciseRoutine.blockId = everythingBlockListId;
    exerciseRoutine.numBreaks = 0;

    Routine eveningRoutine = Routine(name: "Evening Work");
    eveningRoutine.setTimeRange(5, 0, 7, 30);
    eveningRoutine.blockId = workBlockListId;
    eveningRoutine.numBreaks = 2;
    eveningRoutine.maxBreakDuration = 20;

    Routine nightRoutine = Routine(name: "Night Work");
    nightRoutine.setTimeRange(8, 30, 10, 0);
    nightRoutine.blockId = workBlockListId;
    nightRoutine.numBreaks = 1;
    nightRoutine.maxBreakDuration = 20;

    _routines.add(morningRoutine);
    _routines.add(afternoonRoutine);
    _routines.add(exerciseRoutine);
    _routines.add(eveningRoutine);
    _routines.add(nightRoutine);
    
    _routines.sort((a, b) => a.startTime.compareTo(b.startTime));

    Set<Schedule> evaluationTimes = {};
    for (final Routine routine in _routines) {
      evaluationTimes.add(Schedule(hours: routine.startHour, minutes: routine.startMinute));
      evaluationTimes.add(Schedule(hours: routine.endHour, minutes: routine.endMinute));
    }

    for (final Schedule time in evaluationTimes) {
      ScheduledTask task = cron.schedule(time, () async {
        compile();
      });
      _scheduledTasks.add(task);
    }
  }

  BlockList? compile() {
    List<BlockList> activeBlockLists = [];
    List<BlockList> activeAllowLists = [];

    for (final Routine routine in _routines) {
      if (routine.isActive()) {
        final BlockList blockList = _blockLists[routine.blockId]!;
        (blockList.allowList ? activeAllowLists : activeBlockLists).add(blockList);
      }
    }

    List<String> apps = []; 
    List<String> sites = []; 

    if (activeAllowLists.isNotEmpty) {
      Map<String, int> appFrequency = {};
      Map<String, int> siteFrequency = {};
      for (final BlockList blockList in activeAllowLists) {
        for (final String app in blockList.apps) {
          appFrequency[app] = appFrequency[app] ?? 0;
          appFrequency[app] = appFrequency[app]! + 1;
        }
        for (final String site in blockList.sites) {
          siteFrequency[site] = siteFrequency[site] ?? 0;
          siteFrequency[site] = siteFrequency[site]! + 1;
        }
      }
      apps = appFrequency.entries.where((entry) => entry.value == activeAllowLists.length).map((entry) => entry.key).toList();
      sites = siteFrequency.entries.where((entry) => entry.value == activeAllowLists.length).map((entry) => entry.key).toList();
    }

    if (activeBlockLists.isNotEmpty) {
      for (final BlockList blockList in activeBlockLists) {
        sites.addAll(blockList.sites);
        apps.addAll(blockList.apps);
      }
    }

    if (sites.isEmpty && apps.isEmpty) {
      return null;
    }

    BlockList compositeList = BlockList(name: "composite");
    compositeList.sites = sites;
    compositeList.apps = apps;

    return compositeList;
  }

  factory Manager() {
    return _instance;
  }
}

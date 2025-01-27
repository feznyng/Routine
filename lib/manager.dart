import 'routine.dart';
import 'block_list.dart';
import 'package:uuid/uuid.dart';
import 'package:cron/cron.dart';
import 'platform_service.dart';
import 'package:flutter/material.dart';

class Manager {
  static final Manager _instance = Manager._internal();
  
  final cron = Cron();
  final List<Routine> _routines = [];
  final Map<String, BlockList> _blockLists = {};
  final List<ScheduledTask> _scheduledTasks = [];

  Manager._internal() {
    // temp initialization code - replace with sqlite/supabase later

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
      'google chrome',
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
    afternoonRoutine.setTimeRange(13, 0, 16, 0);
    afternoonRoutine.blockId = workBlockListId;
    afternoonRoutine.numBreaks = 2;
    afternoonRoutine.maxBreakDuration = 20;

    Routine exerciseRoutine = Routine(name: "Exercise");
    exerciseRoutine.setTimeRange(16, 0, 17, 0);
    exerciseRoutine.blockId = everythingBlockListId;
    exerciseRoutine.numBreaks = 0;

    Routine eveningRoutine = Routine(name: "Evening Work");
    eveningRoutine.setTimeRange(17, 0, 19, 0);
    eveningRoutine.blockId = workBlockListId;
    eveningRoutine.numBreaks = 2;
    eveningRoutine.maxBreakDuration = 20;

    Routine nightRoutine = Routine(name: "Night Work");
    nightRoutine.setTimeRange(20, 30, 22, 0);
    nightRoutine.blockId = workBlockListId;
    nightRoutine.numBreaks = 1;
    nightRoutine.maxBreakDuration = 20;

    _routines.add(morningRoutine);
    _routines.add(afternoonRoutine);
    _routines.add(exerciseRoutine);
    _routines.add(eveningRoutine);
    _routines.add(nightRoutine);
    
    _routines.sort((a, b) => a.startTime.compareTo(b.startTime));

    // desktop specific code - add check later
    PlatformService.startTcpServer();
   
    Set<Schedule> evaluationTimes = {};
    for (final Routine routine in _routines) {
      evaluationTimes.add(Schedule(hours: routine.startHour, minutes: routine.startMinute));
      evaluationTimes.add(Schedule(hours: routine.endHour, minutes: routine.endMinute));
    }

    for (final Schedule time in evaluationTimes) {
      ScheduledTask task = cron.schedule(time, () async {
        _evaluate();
      });
      _scheduledTasks.add(task);
    }

    _evaluate();
  }

  void _evaluate() {
    Set<BlockList> activeBlockLists = {};
    Set<BlockList> activeAllowLists = {};

    for (final Routine routine in _routines) {
      debugPrint("Evaluating routine: ${routine.name} = ${routine.isActive()}");

      if (routine.isActive()) {
        final BlockList blockList = _blockLists[routine.blockId]!;
        (blockList.allowList ? activeAllowLists : activeBlockLists).add(blockList);
      }
    }

    debugPrint("Active allow lists: $activeAllowLists");
    debugPrint("Active block lists: $activeBlockLists");

    List<String> apps = []; 
    List<String> sites = [];
    bool allowList = false;

    if (activeAllowLists.isNotEmpty) {
      allowList = true;

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

    debugPrint("Active apps: $apps");
    debugPrint("Active sites: $sites");
    debugPrint("Allow list: $allowList");

    PlatformService.updateLists(apps, sites, allowList);
  }

  factory Manager() {
    return _instance;
  }
}

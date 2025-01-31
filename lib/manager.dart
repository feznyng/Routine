import 'dart:io';

import 'routine.dart';
import 'group.dart';
import 'device.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class Manager {
  static final Manager _instance = Manager._internal();
  
  final List<Routine> routines = [];
  final Map<String, Device> devices = {};
  final Map<String, Group> namedBlockLists = {};
  final Map<String, Group> anonblockLists = {};

  late Device thisDevice;

  // Temp items for new routines
  late Group tempGroup;
  late Routine tempRoutine;

  Manager._internal() {
    DeviceType type;

    if (Platform.isAndroid) {
      type = DeviceType.android;
    } else if (Platform.isIOS) {
      type = DeviceType.ios;
    } else if (Platform.isWindows) {
      type = DeviceType.windows;
    } else if (Platform.isLinux) {
      type = DeviceType.linux;
    } else {
      type = DeviceType.macos;
    }

    thisDevice = Device(
      id: Uuid().v4(),
      type: type,
    );

    devices[thisDevice.id] = thisDevice;

    tempGroup = Group(
      id: 'temp_group',
      deviceId: thisDevice.id,
      apps: [],
      sites: [],
      allowList: false,
    );
    anonblockLists[tempGroup.id] = tempGroup;

    // Create temp routine that references the temp group
    tempRoutine = Routine(
      id: 'temp_routine',
      name: '',
      startTime: 9 * 60,  // Default to 9 AM
      endTime: 17 * 60,   // Default to 5 PM
      groupIds: {thisDevice.id: tempGroup.id},
    );

    _initializeData();
  }

  void _initializeData() {
    // temp initialization code - replace with sqlite/supabase later

    // block lists
    String workBlockListId = Uuid().v4();
    Group workBlockList = Group(
      id: workBlockListId,
      name: 'Work',
      deviceId: thisDevice.id,
      sites: [
        "facebook.com",
        "youtube.com",
        "discord.com",
        "reddit.com",
        "news.ycombinator.com",
      ],
      apps: [
        '/Applications/Discord.app',
        '/Applications/Google Chrome.app',
        '/Applications/Safari.app'
      ]
    );

    String everythingBlockListId = Uuid().v4();
    Group everythingBlockList = Group(
      id: everythingBlockListId,
      deviceId: thisDevice.id,
      name: 'Everything',
      allowList: true
    );

    String foodBlockListId = Uuid().v4();
    Group foodBlockList = Group(
      id: foodBlockListId,
      deviceId: thisDevice.id,
      name: 'Food',
      sites: [
        "doordash.com",
        "ubereats.com"
      ]
    );

    namedBlockLists[workBlockListId] = workBlockList;
    namedBlockLists[everythingBlockListId] = everythingBlockList;
    namedBlockLists[foodBlockListId] = foodBlockList;

    // routines
    routines.add(Routine(
      id: Uuid().v4(),
      name: "Meal Delivery",
      days: [true, true, true, false, true, true, true],
      groupIds: {thisDevice.id: foodBlockListId},
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Morning Work",
      startTime: 9 * 60,
      endTime: 12 * 60,
      groupIds: {thisDevice.id: workBlockListId},
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Afternoon Work",
      startTime: 13 * 60,
      endTime: 16 * 60,
      groupIds: {thisDevice.id: workBlockListId},
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Exercise",
      startTime: 16 * 60,
      endTime: 17 * 60,
      groupIds: {thisDevice.id: everythingBlockListId},
      numBreaks: 0
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Evening Work",
      startTime: 17 * 60,
      endTime: 19 * 60 + 30,
      groupIds: {thisDevice.id: workBlockListId},
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Sleep",
      startTime: 23 * 60,
      endTime: 7 * 60,
      groupIds: {thisDevice.id: everythingBlockListId},
      numBreaks: 0
    ));

    routines.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void addRoutine(Routine routine) {
    routines.add(routine);
    routines.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void updateRoutine(Routine routine) {
    debugPrint('updateRoutine ${routine.id}');
    int index = routines.indexWhere((element) => element.id == routine.id);
    routines[index] = routine;
    routines.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void removeRoutine(String id) {
    routines.removeWhere((element) => element.id == id);
  }

  void upsertBlockList(Group blockList) {
    debugPrint('upsertBlockList ${blockList.id}');
    (blockList.name != null ? namedBlockLists : anonblockLists)[blockList.id] = blockList;
  }

  void removeBlockList(String id) {
    namedBlockLists.remove(id);
    anonblockLists.remove(id);
  }

  Group? findBlockList(String id) {
    return namedBlockLists[id] ?? anonblockLists[id]!;
  }

  factory Manager() {
    return _instance;
  }
}

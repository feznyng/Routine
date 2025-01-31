import 'routine.dart';
import 'group.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class Manager {
  static final Manager _instance = Manager._internal();
  
  final List<Routine> routines = [];
  final Map<String, Group> namedBlockLists = {};
  final Map<String, Group> anonblockLists = {};

  // Temp items for new routines
  late Group tempGroup;
  late Routine tempRoutine;

  Manager._internal() {
    // Create temp block group
    tempGroup = Group(
      id: 'temp_group',
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
      groupId: tempGroup.id,
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
      name: 'Everything',
      allowList: true
    );

    String foodBlockListId = Uuid().v4();
    Group foodBlockList = Group(
      id: foodBlockListId,
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
      groupId: foodBlockListId
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Morning Work",
      startTime: 9 * 60,
      endTime: 12 * 60,
      groupId: workBlockListId,
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Afternoon Work",
      startTime: 13 * 60,
      endTime: 16 * 60,
      groupId: workBlockListId,
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Exercise",
      startTime: 16 * 60,
      endTime: 17 * 60,
      groupId: everythingBlockListId,
      numBreaks: 0
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Evening Work",
      startTime: 17 * 60,
      endTime: 19 * 60 + 30,
      groupId: workBlockListId,
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Sleep",
      startTime: 23 * 60,
      endTime: 7 * 60,
      groupId: everythingBlockListId,
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

  Routine createTempRoutine() {
    // Create a temporary block group
    final tempGroupId = Uuid().v4();
    final tempGroup = Group(
      id: tempGroupId,
      apps: [],
      sites: [],
      allowList: false,
    );
    upsertBlockList(tempGroup);
    
    // Create a temporary routine with the block group
    final tempRoutine = Routine(
      id: Uuid().v4(),
      name: "",
      startTime: 9 * 60,  // Default to 9 AM
      endTime: 17 * 60,   // Default to 5 PM
      groupId: tempGroupId,
    );
    routines.add(tempRoutine);
    routines.sort((a, b) => a.startTime.compareTo(b.startTime));
    // _notifyListeners(); // This line is commented out because _notifyListeners is not defined in this class
    
    return tempRoutine;
  }

  factory Manager() {
    return _instance;
  }
}

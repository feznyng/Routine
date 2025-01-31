import 'routine.dart';
import 'group.dart';
import 'package:uuid/uuid.dart';

class Manager {
  static final Manager _instance = Manager._internal();
  
  final List<Routine> routines = [];
  final Map<String, Group> namedBlockLists = {};
  final Map<String, Group> anonblockLists = {};

  Manager._internal() {
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
      blockId: foodBlockListId
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Morning Work",
      startTime: 9 * 60,
      endTime: 12 * 60,
      blockId: workBlockListId,
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Afternoon Work",
      startTime: 13 * 60,
      endTime: 16 * 60,
      blockId: workBlockListId,
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Exercise",
      startTime: 16 * 60,
      endTime: 17 * 60,
      blockId: everythingBlockListId,
      numBreaks: 0
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Evening Work",
      startTime: 17 * 60,
      endTime: 19 * 60 + 30,
      blockId: workBlockListId,
      numBreaks: 2,
      maxBreakDuration: 20
    ));

    routines.add(Routine(
      id: Uuid().v4(),
      name: "Sleep",
      startTime: 23 * 60,
      endTime: 7 * 60,
      blockId: everythingBlockListId,
      numBreaks: 0
    ));

    routines.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void addRoutine(Routine routine) {
    routines.add(routine);
    routines.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void updateRoutine(Routine routine) {
    int index = routines.indexWhere((element) => element.id == routine.id);
    routines[index] = routine;
    routines.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void removeRoutine(String id) {
    routines.removeWhere((element) => element.id == id);
  }

  void upsertBlockList(Group blockList) {
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

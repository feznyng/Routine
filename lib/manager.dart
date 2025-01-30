import 'routine.dart';
import 'block_list.dart';
import 'package:uuid/uuid.dart';

class Manager {
  static final Manager _instance = Manager._internal();
  
  final List<Routine> routines = [];
  final Map<String, BlockList> blockLists = {};

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
      '/Applications/Sublime Text.app',
      '/Applications/Google Chrome.app',
      '/Applications/Safari.app'
    ];

    String everythingBlockListId = Uuid().v4();
    BlockList everythingBlockList = BlockList(name: 'Everything');
    everythingBlockList.allowList = true;

    String foodBlockListId = Uuid().v4();
    BlockList foodBlockList = BlockList(name: 'Food');
    foodBlockList.sites = [
      "doordash.com",
      "ubereats.com"
    ];

    blockLists[workBlockListId] = workBlockList;
    blockLists[everythingBlockListId] = everythingBlockList;
    blockLists[foodBlockListId] = foodBlockList;

    // routines
    Routine foodRoutine = Routine(id: Uuid().v4(), name: "Meal Delivery");
    foodRoutine.setAllDay();
    foodRoutine.setDays([true, true, true, false, true, true, true]);
    foodRoutine.blockId = foodBlockListId;
    routines.add(foodRoutine);

    Routine morningRoutine = Routine(id: Uuid().v4(), name: "Morning Work");
    morningRoutine.setTimeRange(9, 0, 12, 0);
    morningRoutine.blockId = workBlockListId;
    morningRoutine.numBreaks = 2;
    morningRoutine.maxBreakDuration = 20;
    routines.add(morningRoutine);

    Routine afternoonRoutine = Routine(id: Uuid().v4(), name: "Afternoon Work");
    afternoonRoutine.setTimeRange(13, 0, 16, 0);
    afternoonRoutine.blockId = workBlockListId;
    afternoonRoutine.numBreaks = 2;
    afternoonRoutine.maxBreakDuration = 20;
    routines.add(afternoonRoutine);

    Routine exerciseRoutine = Routine(id: Uuid().v4(), name: "Exercise");
    exerciseRoutine.setTimeRange(16, 0, 17, 0);
    exerciseRoutine.blockId = everythingBlockListId;
    exerciseRoutine.numBreaks = 0;
    routines.add(exerciseRoutine);

    Routine eveningRoutine = Routine(id: Uuid().v4(), name: "Evening Work"); 
    eveningRoutine.setTimeRange(17, 0, 19, 30);
    eveningRoutine.blockId = workBlockListId;
    eveningRoutine.numBreaks = 2;
    eveningRoutine.maxBreakDuration = 20;
    routines.add(eveningRoutine);

    Routine sleepRoutine = Routine(id: Uuid().v4(), name: "Sleep");
    sleepRoutine.setTimeRange(23, 0, 7, 0);
    sleepRoutine.blockId = everythingBlockListId;
    sleepRoutine.numBreaks = 0;
    routines.add(sleepRoutine);

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

  void removeRoutine(int index) {
    routines.removeAt(index);
  }

  factory Manager() {
    return _instance;
  }
}

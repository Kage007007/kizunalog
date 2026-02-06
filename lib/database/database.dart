import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

class Memories extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get category => text()();
  TextColumn get subType => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get mediaPath => text().nullable()();
  IntColumn get amount => integer().nullable()();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Schema versioning: 将来のマイグレーションをここに追加
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'kizunalog');
  }

  // --- CRUD Operations ---

  Future<List<Memory>> getAllMemories() => select(memories).get();

  Future<List<Memory>> getMemoriesByCategory(String category) {
    return (select(memories)..where((t) => t.category.equals(category))).get();
  }

  Stream<List<Memory>> watchAllMemories() {
    return (select(memories)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Stream<List<Memory>> watchMemoriesByCategory(String category) {
    return (select(memories)
          ..where((t) => t.category.equals(category))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<Memory?> getRandomMemory() async {
    final all = await getAllMemories();
    if (all.isEmpty) return null;
    all.shuffle();
    return all.first;
  }

  Future<int> insertMemory(MemoriesCompanion entry) {
    return into(memories).insert(entry);
  }

  Future<bool> updateMemory(MemoriesCompanion entry) {
    return update(memories).replace(entry);
  }

  Future<int> deleteMemory(String id) {
    return (delete(memories)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getMemoryCount() async {
    final count = countAll();
    final query = selectOnly(memories)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count)!;
  }
}

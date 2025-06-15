import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String? id;
  final String title;
  final String? note;
  final DateTime? dateTime;
  final bool isCompleted;
  final String userId;
  final bool isNote;
  final Timestamp? createdAt;

  Item({
    this.id,
    required this.title,
    this.note,
    this.dateTime,
    this.isCompleted = false,
    required this.userId,
    this.isNote = false,
    this.createdAt,
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      title: data['title'] ?? '',
      note: data['note'],
      dateTime: (data['dateTime'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] ?? false,
      userId: data['userId'] ?? '',
      isNote: data['isNote'] ?? false,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  factory Item.fromNote(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      title: data['note'] ?? 'Anotação vazia',
      note: data['note'] ?? '',
      userId: data['userId'] ?? '',
      dateTime: (data['timestamp'] as Timestamp?)?.toDate(),
      isNote: true,
      createdAt: data['timestamp'] as Timestamp?,
    );
  }

  Map<String, dynamic> toTaskMap() {
    return {
      'title': title,
      'note': note,
      'isCompleted': isCompleted,
      'userId': userId,
      'dateTime': dateTime != null ? Timestamp.fromDate(dateTime!) : null,
      'isNote': isNote,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toNoteMap() {
    return {
      'note': title,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  Item copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? dateTime,
    bool? isCompleted,
    String? userId,
    bool? isNote,
    Timestamp? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      isNote: isNote ?? this.isNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ItemsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _lastDeletedData;
  String? _lastDeletedId;
  String? _lastDeletedCollection;

  Stream<List<Item>> getCombinedStream(String userId) {
    final tasksStream = _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((doc) => Item.fromFirestore(doc)).toList());

    final notesStream = _db
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((doc) => Item.fromNote(doc)).toList());

    return StreamZip([tasksStream, notesStream]).map((streams) {
      final List<Item> tasks = streams[0];
      final List<Item> notes = streams[1];
      final combined = [...tasks, ...notes];

      combined.sort((a, b) {
        if (a.isNote != b.isNote) return a.isNote ? 1 : -1;
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        final aDate = a.dateTime ?? a.createdAt?.toDate() ?? DateTime(1970);
        final bDate = b.dateTime ?? b.createdAt?.toDate() ?? DateTime(1970);
        return bDate.compareTo(aDate); // Mais recentes primeiro
      });
      return combined;
    });
  }

  Future<void> addItem(Item item) async {
    final collection = item.isNote ? 'notes' : 'tasks';
    final data = item.isNote ? item.toNoteMap() : item.toTaskMap();
    await _db.collection(collection).add(data);
  }

  Future<void> updateItem(Item item) async {
    if (item.id == null) return;

    final collection = item.isNote ? 'notes' : 'tasks';
    final data = item.isNote ? {'note': item.title} : item.toTaskMap();

    await _db.collection(collection).doc(item.id).update(data);
  }

  Future<void> deleteItem(String itemId, bool isNote) async {
    _lastDeletedCollection = isNote ? 'notes' : 'tasks';
    _lastDeletedId = itemId;

    final docRef = _db.collection(_lastDeletedCollection!).doc(itemId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      _lastDeletedData = docSnapshot.data();
      await docRef.delete();
    }
  }

  Future<void> undoDeleteItem(Item item) async {
    if (_lastDeletedId != null &&
        _lastDeletedData != null &&
        _lastDeletedCollection != null) {
      await _db
          .collection(_lastDeletedCollection!)
          .doc(_lastDeletedId!)
          .set(_lastDeletedData!);
      _lastDeletedId = null;
      _lastDeletedData = null;
      _lastDeletedCollection = null;
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool currentStatus) async {
    await _db.collection('tasks').doc(taskId).update({
      'isCompleted': !currentStatus,
    });
  }
}

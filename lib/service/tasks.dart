import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? id;
  final String title;
  final String? note;
  final DateTime? dateTime;
  final bool isCompleted;
  final String userId;
  final bool isNote;
  final Timestamp? createdAt;

  Task({
    this.id,
    required this.title,
    this.note,
    this.dateTime,
    this.isCompleted = false,
    required this.userId,
    this.isNote = false,
    this.createdAt,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      note: data['note'],
      dateTime: (data['dateTime'] as Timestamp?)?.toDate(),
      isCompleted: data['completed'] ?? false,
      userId: data['userId'] ?? '',
      isNote: data['isNote'] ?? false, // Lê o novo campo
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'note': note,
      'completed': isCompleted,
      'userId': userId,
      'dateTime': dateTime != null ? Timestamp.fromDate(dateTime!) : null,
      'isNote': isNote, // Salva o novo campo
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}

class TasksService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _collectionPath = 'tasks';

  Stream<List<Task>> getItemsStream(String userId) {
    return _db
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          var items = snapshot.docs
              .map((doc) => Task.fromFirestore(doc))
              .toList();
          items.sort((a, b) {
            if (a.isNote != b.isNote) return a.isNote ? 1 : -1;
            if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
            return (b.createdAt ?? Timestamp(0, 0)).compareTo(
              a.createdAt ?? Timestamp(0, 0),
            );
          });
          return items;
        });
  }

  Future<void> toggleItemCompletion(String itemId, bool currentStatus) async {
    await _db.collection(_collectionPath).doc(itemId).update({
      'completed': !currentStatus,
    });
  }

  Stream<List<Task>> getTasksStream(String userId) {
    return _db
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('isNote', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          var tasks = snapshot.docs
              .map((doc) => Task.fromFirestore(doc))
              .toList();
          tasks.sort((a, b) {
            if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
            return (b.createdAt ?? Timestamp(0, 0)).compareTo(
              a.createdAt ?? Timestamp(0, 0),
            );
          });
          return tasks;
        });
  }

  Future<void> addItem(Task item) async =>
      await _db.collection(_collectionPath).add(item.toFirestore());
  Future<void> updateItem(Task item) async => await _db
      .collection(_collectionPath)
      .doc(item.id)
      .update(item.toFirestore());
  Future<void> deleteItem(String itemId) async =>
      await _db.collection(_collectionPath).doc(itemId).delete();
  Future<void> toggleTaskCompletion(String itemId, bool currentStatus) async =>
      await _db.collection(_collectionPath).doc(itemId).update({
        'completed': !currentStatus,
      });
}

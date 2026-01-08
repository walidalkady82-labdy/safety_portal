import 'package:firebase_database/firebase_database.dart';

enum QueryType { isEqualTo, isLessThan, isGreaterThan }

class QueryCondition {
  final String field;
  final QueryType type;
  final dynamic value;

  QueryCondition(this.field, this.type, this.value);
}

abstract class IRepoRealtime {
  Future<String> generateId(String path);
  Future<DataSnapshot> getData(String path, {List<QueryCondition>? where, int? limit});
  Stream<DatabaseEvent> getStream(String path,{int? limit});
  Future<void> set(String path, String id, Map<String, dynamic> data);
  Future<void> update(String path, String id, Map<String, dynamic> data);
  Future<void> remove(String path, String id);
}
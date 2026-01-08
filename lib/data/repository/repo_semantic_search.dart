import 'i_repo_duplicate_detector.dart';

class RepoSemanticSearch {
  final IRepoDuplicateDetector _embeddingModel;
  final List<dynamic> _database; // Your loaded atr.json

  RepoSemanticSearch(this._embeddingModel, this._database);

  Future<List<dynamic>> search(String userQuery) async {
    // 1. Convert user query to vector (Context is empty for generic search)
    // We pass the query as 'text' and leave line/area empty or generic
    List<double> queryVector = await _embeddingModel.getEmbedding(
      line: "", 
      area: "General", 
      text: userQuery
    );

    // 2. Compare against all historical records
    List<Map<String, dynamic>> results = [];

    for (var record in _database) {
      // Ensure your JSON parser casts 'vector' to List<double>
      List<double> recordVector = List<double>.from(record['vector']);
      
      double score = _embeddingModel.calculateSimilarity(queryVector, recordVector);
      
      if (score > 0.65) { // Threshold for "Relevant"
        results.add({
          'record': record,
          'score': score
        });
      }
    }

    // 3. Sort by relevance (Highest first)
    results.sort((a, b) => b['score'].compareTo(a['score']));

    return results.take(5).toList(); // Return top 5
  }
}
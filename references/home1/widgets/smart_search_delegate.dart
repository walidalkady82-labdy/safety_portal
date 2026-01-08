import 'package:flutter/material.dart';
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/data/service/service_atr.dart';
import 'package:safety_portal/locator.dart';

class SmartSearchDelegate extends SearchDelegate<ModelAtr?> {
  final  _aiService = sl<ServiceAI>();
  final  _atrService = sl<AtrService>(); // To fetch data if needed, or pass list in constructor
  final List<ModelAtr> preloadedReports;

  SmartSearchDelegate({
    required this.preloadedReports, 
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.manage_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Enter issue description to find similar reports..."),
          ],
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _aiService.searchSimilarReports(query, preloadedReports, threshold: 0.3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No semantically similar reports found."));
        }

        final results = snapshot.data!;

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final match = results[index];
            final ModelAtr report = match['report'];
            final double score = match['score'];
            
            // Format score as percentage
            final int similarity = (score * 100).toInt();

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getSimilarityColor(score),
                child: Text("$similarity%", style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(report.observation, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text("${report.status} • ${report.area ?? 'Unknown'} • ${report.hazardKind ?? ''}"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                close(context, report);
              },
            );
          },
        );
      },
    );
  }

  Color _getSimilarityColor(double score) {
    if (score > 0.85) return Colors.red; // Very high match (Potential Duplicate)
    if (score > 0.6) return Colors.orange;
    return Colors.green; // Loose match
  }
}
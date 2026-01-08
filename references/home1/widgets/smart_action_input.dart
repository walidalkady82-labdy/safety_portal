import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safety_portal/data/repository/i_repo_hazard_classifier.dart';

class SmartActionInput extends StatefulWidget {
  final TextEditingController textController; // The hazard description
  final IRepoHazardClassifier classifier;
  final Function(String) onActionSelected;

  const SmartActionInput({
    super.key,
    required this.textController,
    required this.classifier,
    required this.onActionSelected,
  });

  @override
  _SmartActionInputState createState() => _SmartActionInputState();
}

class _SmartActionInputState extends State<SmartActionInput> {
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final text = widget.textController.text;
      if (text.length < 5) return;

      // 1. Get raw prediction from your existing classifier
      // You might need to update your interface to expose raw probabilities
      // Or simply create a helper in the repo to get 'top 3'
      // For now, let's assume we added getTop3Actions to the repo
      final suggestions = await widget.classifier.predictTopActions("","",text);
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("💡 AI Recommendations:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
        Wrap(
          spacing: 8.0,
          children: _suggestions.map((s) {
            return ActionChip(
              avatar: const Icon(Icons.smart_toy, size: 16),
              label: Text("${s['action']} (${s['confidence']})"),
              backgroundColor: Colors.blue.shade50,
              onPressed: () {
                widget.onActionSelected(s['action']);
                setState(() => _suggestions = []); // Hide after selection
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
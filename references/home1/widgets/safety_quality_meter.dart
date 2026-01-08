import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/locator.dart';

//If you want the AI to care more about Equipment Names, change the list to:
// final List<String> _goldStandards = [
// Focus on what could happen
//   "Cable cut causing potential fire",
//   "Water leak causing electrical short circuit risk",
//   "Loose guard causing risk of amputation"
// ];
//If you want the AI to care more about Consequences, change the list to:
//final List<String> _goldStandards = [
// Focus on what could happen
//   "Cable cut causing potential fire",
//   "Water leak causing electrical short circuit risk",
//   "Loose guard causing risk of amputation"
// ];
class SafetyQualityMeter extends StatefulWidget {
  final String observation;
  final duplicateRepo = sl<ServiceAI>();

  SafetyQualityMeter({
    super.key, 
    required this.observation, 
  });

  @override
  _SafetyQualityMeterState createState() => _SafetyQualityMeterState();
}

class _SafetyQualityMeterState extends State<SafetyQualityMeter> {
  double _score = 0.0;
  String _message = "Enter details...";
  Color _color = Colors.grey;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _checkQuality(widget.observation);
  }

  @override
  void didUpdateWidget(covariant SafetyQualityMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observation != widget.observation) {
      _checkQuality(widget.observation);
    }
  }

  void _checkQuality(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      
      if (text.length < 5) {
        setState(() { _score = 0; _message = "Too short"; _color = Colors.grey; });
        return;
      }

      // Call the new repo method
      // (Ensure you added getQualityScore to your Interface first!)
      // For now, casting or assuming implementation:
      double quality = await (widget.duplicateRepo as dynamic).getQualityScore(text);

      if (mounted) {
        setState(() {
          _score = quality;
          if (quality < 0.4) {
            _message = "وصف غير واضح";
            _color = Colors.red;
          } else if (quality < 0.7) {
            _message = "جيد";
            _color = Colors.orange;
          } else {
            _message = "ممتاز!";
            _color = Colors.green;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Report Quality:", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(_message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _score,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_color),
            minHeight: 6,
          ),
        ),
        if (_score < 0.6) // Only show help if they are struggling
              TextButton.icon(
                icon: const Icon(Icons.help_outline, size: 14),
                label: const Text("See Example", style: TextStyle(fontSize: 12)),
                onPressed: _showGuidance,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        )
      ],
    );
  }

  // Add this inside your _SafetyQualityMeterState

  void _showGuidance() {
    // These are the specific things the AI looks for
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🏆 How to get a 100% Score", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("A 'Good Enough' report contains 3 things:"),
            const SizedBox(height: 10),
            _buildCheckItem("Where?", "Specific location (e.g., 'Main Pump Seal')"),
            _buildCheckItem("What?", "The defect (e.g., 'Oil Leakage')"),
            _buildCheckItem("Why?", "The risk (e.g., 'Slip Hazard')"),
            const Divider(),
            const Text("Example of Perfect Thinking:", style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Text(
                "\"Oil leakage detected in the main pump seal causing slip hazard\"",
                style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String label, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Text(text),
        ],
      ),
    );
  }
}
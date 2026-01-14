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

const Map<String, Map<String, String>> _locals = {
  'en': {
    'idle': "Enter details...",
    'tooShort': "Too short",
    'low': "Unclear description",
    'medium': "Good",
    'high': "Excellent!",
    'label': "Report Quality:",
    'title': "🏆 How to get a 100% Score",
    'subtitle': "A 'Good Enough' report contains 3 things:",
    'where': "Where?",
    'where_desc': "Specific location (e.g., 'Main Pump Seal')",
    'what': "What?",
    'what_desc': "The defect (e.g., 'Oil Leakage')",
    'why': "Why?",
    'why_desc': "The risk (e.g., 'Slip Hazard')",
    'example_title': "Example of Perfect Thinking:",
    'gold_label': "Gold Standard Example:",
    'more_tips': "See more tips...",
  },
  'ar': {
    'idle': "أدخل التفاصيل...",
    'tooShort': "قصير جداً",
    'low': "وصف غير واضح",
    'medium': "جيد",
    'high': "ممتاز!",
    'label': "جودة التقرير:",
    'title': "🏆 كيف تحصل على نسبة 100%",
    'subtitle': "التقرير الجيد يحتوي على 3 عناصر:",
    'where': "أين؟",
    'where_desc': "مكان محدد (مثال: 'مانع تسرب المضخة الرئيسية')",
    'what': "ماذا؟",
    'what_desc': "العطل (مثال: 'تسريب زيت')",
    'why': "لماذا؟",
    'why_desc': "الخطر (مثال: 'خطر انزلاق')",
    'example_title': "مثال للتفكير المثالي:",
    'gold_label': "مثال نموذجي:",
    'more_tips': "المزيد من النصائح...",
  }
};

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

enum _QualityState { idle, tooShort, low, medium, high }

class _SafetyQualityMeterState extends State<SafetyQualityMeter> {
  double _score = 0.0;
  _QualityState _qualityState = _QualityState.idle;
  Color _color = Colors.grey;
  Timer? _debounce;
  String _relevantExample = "";

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
        setState(() { 
          _score = 0; 
          _qualityState = _QualityState.tooShort; 
          _color = Colors.grey; 
          _relevantExample = "";
        });
        return;
      }

      // Call the new repo method
      // (Ensure you added getQualityScore to your Interface first!)
      // For now, casting or assuming implementation:
      double quality = await (widget.duplicateRepo as dynamic).getQualityScore(text);
      String example = await widget.duplicateRepo.getRelevantGoldStandard(text);

      if (mounted) {
        setState(() {
          _score = quality;
          _relevantExample = example;
          if (quality < 0.4) {
            _qualityState = _QualityState.low;
            _color = Colors.red;
          } else if (quality < 0.7) {
            _qualityState = _QualityState.medium;
            _color = Colors.orange;
          } else {
            _qualityState = _QualityState.high;
            _color = Colors.green;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final strings = _locals[isAr ? 'ar' : 'en']!;
    
    String message;
    switch (_qualityState) {
      case _QualityState.idle: message = strings['idle']!; break;
      case _QualityState.tooShort: message = strings['tooShort']!; break;
      case _QualityState.low: message = strings['low']!; break;
      case _QualityState.medium: message = strings['medium']!; break;
      case _QualityState.high: message = strings['high']!; break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(strings['label']!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _color)),
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
        if (_score < 0.6) ...[
          const SizedBox(height: 8),
          _buildGoldStandardTip(strings),
        ]
      ],
    );
  }

  // Add this inside your _SafetyQualityMeterState

  void _showGuidance(Map<String, String> strings) {
    // These are the specific things the AI looks for
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(strings['subtitle']!),
            const SizedBox(height: 10),
            _buildCheckItem(strings['where']!, strings['where_desc']!),
            _buildCheckItem(strings['what']!, strings['what_desc']!),
            _buildCheckItem(strings['why']!, strings['why_desc']!),
            const Divider(),
            Text(strings['example_title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildGoldStandardTip(Map<String, String> strings) {
    if (_relevantExample.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade900),
              const SizedBox(width: 6),
              Text(strings['gold_label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "\"$_relevantExample\"",
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showGuidance(strings),
            child: Text(strings['more_tips']!, style: TextStyle(fontSize: 11, color: Colors.blue.shade700, decoration: TextDecoration.underline)),
          )
        ],
      ),
    );
  }
}
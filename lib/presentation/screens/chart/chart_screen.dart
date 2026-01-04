import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import '../../../data/datasources/mock_data_service.dart';
import '../../../domain/detection/pattern_detector.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late List<Candle> _candles;
  DetectionResult? _selectedDetection;

  @override
  void initState() {
    super.initState();
    _candles = MockDataService.generateCandles();
    // In a real app, detection happens possibly async or on button press
  }

  void _runDetection() {
    final detector = PatternDetector();
    final results = detector.detect(_candles);
    
    if (results.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Detected ${results.length} patterns!"),
      ));
      
      // Highlight the first one for now
      setState(() {
        _selectedDetection = results.first;
      });
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No patterns detected."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chart Simulator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Detect Patterns",
            onPressed: _runDetection,
          ),
        ],
      ),
      body: Stack(
        children: [
          Candlesticks(
            candles: _candles,
            // Simple indicator to highlight detected index?
            // The package supports annotations (TrendLines, etc), but maybe complex for MVP.
            // We'll overlay a marker if detection exists.
          ),
          
          if (_selectedDetection != null)
             Positioned(
               top: 20,
               left: 20,
               child: Container(
                 padding: const EdgeInsets.all(8),
                 color: Colors.black87,
                 child: Text(
                   "Detected: ${_selectedDetection!.patternName} (${_selectedDetection!.bias})",
                   style: const TextStyle(color: Colors.white),
                 ),
               ),
             ),
        ],
      ),
    );
  }
}

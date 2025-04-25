import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpeedGraphWidget extends StatelessWidget {
  final Map<String, int> speedZones;
  
  const SpeedGraphWidget({
    super.key,
    required this.speedZones,
  });

  @override
  Widget build(BuildContext context) {
    final totalSeconds = speedZones.values.fold(0, (sum, value) => sum + value);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            'Speed Zones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200,
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: _buildSpeedZoneBars(totalSeconds),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('0-5', Colors.blue.shade300),
            _buildLegendItem('5-10', Colors.green.shade300),
            _buildLegendItem('10-15', Colors.amber.shade300),
            _buildLegendItem('15-20', Colors.orange.shade300),
            _buildLegendItem('20+', Colors.red.shade300),
          ],
        ),
      ],
    );
  }
  
  List<Widget> _buildSpeedZoneBars(int totalSeconds) {
    if (totalSeconds == 0) {
      return [
        Expanded(
          child: Container(color: Colors.grey.shade300),
        ),
      ];
    }
    
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.amber.shade300,
      Colors.orange.shade300,
      Colors.red.shade300,
    ];
    
    final List<Widget> bars = [];
    int index = 0;
    
    for (final entry in speedZones.entries) {
      final percentage = entry.value / totalSeconds;
      if (percentage > 0) {
        bars.add(
          Expanded(
            flex: math.max(1, (percentage * 100).round()),
            child: Container(color: colors[index % colors.length]),
          ),
        );
      }
      index++;
    }
    
    return bars;
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

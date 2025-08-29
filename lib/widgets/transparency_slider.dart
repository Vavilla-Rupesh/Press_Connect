import 'package:flutter/material.dart';

class TransparencySlider extends StatelessWidget {
  final double opacity;
  final ValueChanged<double> onChanged;

  const TransparencySlider({
    super.key,
    required this.opacity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey[900],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.opacity,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Watermark Transparency',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(opacity * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.visibility_off,
                color: Colors.grey,
                size: 16,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: Colors.grey[700],
                    thumbColor: Colors.red,
                    overlayColor: Colors.red.withAlpha(32),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: opacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust watermark transparency before going live',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
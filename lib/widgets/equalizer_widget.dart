import 'package:flutter/material.dart';
import '../services/equalizer_service.dart';

class EqualizerWidget extends StatefulWidget {
  const EqualizerWidget({super.key});

  @override
  State<EqualizerWidget> createState() => _EqualizerWidgetState();
}

class _EqualizerWidgetState extends State<EqualizerWidget> {
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreset();
  }

  Future<void> _loadCurrentPreset() async {
    final preset = await EqualizerService.getCurrentPreset();
    setState(() {
      _selectedPreset = preset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- TÍTULO ---
            Text(
              'Ecualizador',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // --- BANDAS DE FRECUENCIA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  // Header de bandas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bandas',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        'dB',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sliders de bandas
                  ...List.generate(
                    5,
                    (index) => _buildBandSlider(index),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- PRESETS ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presets',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EqualizerService.presets.keys.map((presetName) {
                      final isSelected = _selectedPreset == presetName;
                      return FilterChip(
                        label: Text(presetName),
                        selected: isSelected,
                        onSelected: (selected) async {
                          if (selected) {
                            await EqualizerService.applyPreset(presetName);
                            setState(() {
                              _selectedPreset = presetName;
                            });
                          }
                        },
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        selectedColor: Colors.greenAccent.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.greenAccent
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- BOTÓN RESET ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  await EqualizerService.reset();
                  setState(() {
                    _selectedPreset = null;
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ecualizador reseteado a valores normales'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('Resetear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandSlider(int index) {
    final frequency = EqualizerService.bandLabels[index];
    final value = EqualizerService.bandValues[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          // Etiqueta y valor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                frequency,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value > 0 ? '+' : ''}${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 4,
              ),
              activeTrackColor: Colors.greenAccent,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              thumbColor: Colors.greenAccent,
              valueIndicatorColor: Colors.greenAccent,
            ),
            child: Slider(
              value: value,
              min: -15,
              max: 15,
              divisions: 30,
              label: '${value.toInt()}dB',
              onChanged: (newValue) async {
                EqualizerService.bandValues[index] = newValue;
                await EqualizerService.setBandLevel(index, newValue.toInt());
                setState(() {
                  _selectedPreset = null; // Deseleccionar preset al cambiar manualmente
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

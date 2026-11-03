import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/localizacao.dart';

/// Mapa esquemático local, sem depender de conexão ou serviço de tiles.
class MapaLocalizacoes extends StatelessWidget {
  const MapaLocalizacoes({super.key, required this.localizacoes});

  final List<Localizacao> localizacoes;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _MapaPainter(localizacoes, Theme.of(context).colorScheme),
          child: const SizedBox.expand(),
        ),
      );
}

class _MapaPainter extends CustomPainter {
  _MapaPainter(this.pontos, this.cores);
  final List<Localizacao> pontos;
  final ColorScheme cores;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(cores.surfaceContainerHighest, BlendMode.src);
    final grade = Paint()
      ..color = cores.outlineVariant.withValues(alpha: .55)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grade);
    }
    for (var y = 0.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grade);
    }
    if (pontos.isEmpty) {
      final text = TextPainter(
        text: TextSpan(text: 'Nenhuma localização salva', style: TextStyle(color: cores.onSurfaceVariant)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 24);
      text.paint(canvas, Offset((size.width - text.width) / 2, (size.height - text.height) / 2));
      return;
    }

    final minLat = pontos.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final maxLat = pontos.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final minLon = pontos.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final maxLon = pontos.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    final latRange = math.max(maxLat - minLat, .001);
    final lonRange = math.max(maxLon - minLon, .001);
    final posicoes = pontos.map((p) => Offset(
      (20 + (p.longitude - minLon) / lonRange * math.max(1.0, size.width - 40)).toDouble(),
      (size.height - 20 - (p.latitude - minLat) / latRange * math.max(1.0, size.height - 40)).toDouble(),
    )).toList();
    if (posicoes.length > 1) {
      canvas.drawPath(Path()..addPolygon(posicoes, false), Paint()
        ..color = cores.primary.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
    for (final posicao in posicoes) {
      canvas.drawCircle(posicao, 8, Paint()..color = cores.primary);
      canvas.drawCircle(posicao, 3, Paint()..color = cores.onPrimary);
    }
  }

  @override
  bool shouldRepaint(covariant _MapaPainter oldDelegate) =>
      oldDelegate.pontos != pontos || oldDelegate.cores != cores;
}

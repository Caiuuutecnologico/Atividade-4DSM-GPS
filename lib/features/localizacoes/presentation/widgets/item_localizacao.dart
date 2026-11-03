import 'package:flutter/material.dart';

import '../../models/localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({super.key, required this.localizacao, this.onExcluir});

  final Localizacao localizacao;
  final VoidCallback? onExcluir;

  @override
  Widget build(BuildContext context) {
    final data = localizacao.dataHora.toLocal();
    final dataFormatada = '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.place_outlined)),
        title: Text('${localizacao.latitude.toStringAsFixed(5)}, '
            '${localizacao.longitude.toStringAsFixed(5)}'),
        subtitle: Text('$dataFormatada\nPrecisão: ${localizacao.precisao.toStringAsFixed(0)} m'),
        isThreeLine: true,
        trailing: onExcluir == null
            ? null
            : IconButton(
                tooltip: 'Excluir localização',
                onPressed: onExcluir,
                icon: const Icon(Icons.delete_outline),
              ),
      ),
    );
  }
}

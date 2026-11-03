import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../services/servico_localizacao.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key, required this.repositorio});
  final RepositorioLocalizacoes repositorio;

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  bool _carregando = false;

  Future<void> _coletar() async {
    setState(() => _carregando = true);
    try {
      final localizacao = await ServicoLocalizacao().obterLocalizacaoAtual();
      await widget.repositorio.salvar(localizacao);
      if (mounted) Navigator.pop(context, true);
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Coletar localização')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.my_location, size: 72),
              const SizedBox(height: 16),
              const Text('Obtenha as coordenadas atuais do dispositivo e salve-as localmente.'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _carregando ? null : _coletar,
                icon: _carregando
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.gps_fixed),
                label: Text(_carregando ? 'Obtendo localização…' : 'Obter e salvar'),
              ),
            ]),
          ),
        ),
      );
}

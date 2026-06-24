import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seguridad_ciudadana_app/core/config/router.dart';
import 'package:seguridad_ciudadana_app/features/sos/presentation/controllers/sos_controller.dart';
import 'package:seguridad_ciudadana_app/shared/widgets/app_drawer.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(sosControllerProvider);
    final sosController = ref.read(sosControllerProvider.notifier);

    ref.listen<SosState>(sosControllerProvider, (previous, next) {
      if (previous?.message != next.message && next.message != null) {
        final snackBar = SnackBar(
          content: Text(next.message!),
          backgroundColor: next.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(seconds: 4),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad Ciudadana')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Alerta Segura',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Abre el menú para iniciar sesión o registrarte, o presiona SOS para solicitar ayuda por una incidencia.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 72, color: Colors.red),
                        const SizedBox(height: 20),
                        const Text(
                          'Botón de Pánico',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Presiona SOS para reportar una alerta de ayuda SOS, se usara tu ubicacion actual.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => context.push(myIncidentsDefaultRoute),
                          icon: const Icon(Icons.history),
                          label: const Text('Ver mis incidencias'),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 190,
                          height: 190,
                          child: ElevatedButton(
                            onPressed: sosState.isSending ? null : () => sosController.sendSOS(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: const CircleBorder(),
                              elevation: 8,
                            ),
                            child: sosState.isSending
                                ? const SizedBox(
                                    height: 32,
                                    width: 32,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : const Text(
                                    'SOS',
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                        if (sosState.message != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            sosState.message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: sosState.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

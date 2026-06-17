import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/controllers/auth_controller.dart";
import "package:seguridad_ciudadana_app/features/location/presentation/controllers/location_controller.dart";
import "package:seguridad_ciudadana_app/features/background_location/presentation/controllers/background_location_controller.dart";
import "package:seguridad_ciudadana_app/shared/widgets/app_button.dart";

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);
    final locationState = ref.watch(locationControllerProvider);
    final locationController = ref.read(locationControllerProvider.notifier);
    final backgroundLocationState = ref.watch(backgroundLocationControllerProvider);
    final backgroundLocationController = ref.read(backgroundLocationControllerProvider.notifier);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: Center(
        child: user == null 
          ? const Text("Usuario no autenticado")
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                  const SizedBox(height: 16),
                  Text(user.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  Text(user.email, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  const Text('Seguimiento en pantalla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    locationState.isTracking ? 'Seguimiento activado' : 'Seguimiento pausado',
                    style: TextStyle(
                      fontSize: 16,
                      color: locationState.isTracking ? Colors.green : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (locationState.currentLocation != null) ...[
                    const SizedBox(height: 12),
                    Text('Lat: ${locationState.currentLocation!.latitude.toStringAsFixed(6)}', textAlign: TextAlign.center),
                    Text('Lng: ${locationState.currentLocation!.longitude.toStringAsFixed(6)}', textAlign: TextAlign.center),
                    Text('Updated: ${locationState.currentLocation!.timestamp.toLocal()}', textAlign: TextAlign.center),
                  ],
                  if (locationState.error != null) ...[
                    const SizedBox(height: 12),
                    Text(locationState.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    text: locationState.isTracking ? 'Detener seguimiento' : 'Iniciar seguimiento',
                    isLoading: authState.isLoading,
                    color: locationState.isTracking ? Colors.orange : Colors.blue,
                    onPressed: () {
                      if (locationState.isTracking) {
                        locationController.stopTracking();
                      } else {
                        locationController.startTracking();
                      }
                    },
                  ),

                  const SizedBox(height: 32),
                  const Text('Seguimiento en segundo plano', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    backgroundLocationState.isRunning ? 'Seguimiento en segundo plano activado' : 'Seguimiento en segundo plano pausado',
                    style: TextStyle(
                      fontSize: 16,
                      color: backgroundLocationState.isRunning ? Colors.green : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (backgroundLocationState.lastLocation != null) ...[
                    const SizedBox(height: 12),
                    Text('Lat: ${backgroundLocationState.lastLocation!.latitude.toStringAsFixed(6)}', textAlign: TextAlign.center),
                    Text('Lng: ${backgroundLocationState.lastLocation!.longitude.toStringAsFixed(6)}', textAlign: TextAlign.center),
                    Text('Updated: ${backgroundLocationState.lastLocation!.timestamp.toLocal()}', textAlign: TextAlign.center),
                  ],
                  if (backgroundLocationState.error != null) ...[
                    const SizedBox(height: 12),
                    Text(backgroundLocationState.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    text: backgroundLocationState.isRunning ? 'Detener seguimiento en segundo plano' : 'Iniciar seguimiento en segundo plano',
                    isLoading: false,
                    color: backgroundLocationState.isRunning ? Colors.orange : Colors.green,
                    onPressed: () {
                      if (backgroundLocationState.isRunning) {
                        backgroundLocationController.stop();
                      } else {
                        backgroundLocationController.start();
                      }
                    },
                  ),

                  const SizedBox(height: 32),
                  AppButton(
                    text: "Ver solicitudes disponibles",
                    isLoading: false,
                    color: Colors.blue,
                    onPressed: () => context.push('/rides'),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: "Cerrar sesión",
                    isLoading: authState.isLoading,
                    color: Colors.red,
                    onPressed: () => authController.logout(),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

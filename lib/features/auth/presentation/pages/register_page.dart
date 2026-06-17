import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:seguridad_ciudadana_app/features/auth/presentation/controllers/auth_controller.dart";
import "package:seguridad_ciudadana_app/shared/widgets/app_button.dart";
import "package:seguridad_ciudadana_app/shared/widgets/app_text_field.dart";

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Join us to get started"),
              const SizedBox(height: 32),
              AppTextField(
                label: "Full Name",
                hint: "Enter your name",
                controller: nameController,
                validator: (value) => value == null || value.isEmpty ? "Name is required" : null,
              ),
              AppTextField(
                label: "Email",
                hint: "Enter your email",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty ? "Email is required" : null,
              ),
              AppTextField(
                label: "Password",
                hint: "Enter your password",
                controller: passwordController,
                isPassword: true,
                validator: (value) => value == null || value.isEmpty ? "Password is required" : null,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: "Register",
                isLoading: authState.isLoading,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    authController.register(nameController.text, emailController.text, passwordController.text);
                  }
                },
              ),
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(authState.error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

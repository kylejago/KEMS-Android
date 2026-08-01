import 'package:flutter/material.dart';
import '../state/app_controller.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _token = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.saveConfiguration(_url.text, _token.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Icon(Icons.bolt, size: 56, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text('Connect KEMS', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        const Text('Enter your Home Assistant address and a Long-Lived Access Token. The token is encrypted on this device.', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _url,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(labelText: 'Home Assistant URL', hintText: 'https://home.example.com', border: OutlineInputBorder()),
                          validator: (value) {
                            final uri = Uri.tryParse(value?.trim() ?? '');
                            return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') ? null : 'Enter a valid http or https URL';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _token,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Long-Lived Access Token',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                          ),
                          validator: (value) => (value?.trim().length ?? 0) > 20 ? null : 'Paste the complete token',
                        ),
                        if (widget.controller.error != null) ...[
                          const SizedBox(height: 12),
                          Text(widget.controller.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: widget.controller.loading ? null : _connect,
                          icon: widget.controller.loading
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.link),
                          label: const Text('Connect to Home Assistant'),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

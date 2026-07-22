import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/proxy_models.dart';
import '../providers/app_state.dart';

class ProfileEditorSheet extends StatefulWidget {
  const ProfileEditorSheet({super.key, this.profile});

  final ProxyProfile? profile;

  @override
  State<ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<ProfileEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _localPortCtrl;
  late ProxyType _type;
  late String _method;
  late bool _systemProxy;

  static const _shadowsocksMethods = [
    'aes-256-gcm',
    'aes-128-gcm',
    'chacha20-poly1305',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _hostCtrl = TextEditingController(text: p?.host ?? '');
    _portCtrl = TextEditingController(text: '${p?.port ?? 8080}');
    _usernameCtrl = TextEditingController(text: p?.username ?? '');
    _passwordCtrl = TextEditingController(text: p?.password ?? '');
    _localPortCtrl = TextEditingController(text: '${p?.localPort ?? 10808}');
    _type = p?.type ?? ProxyType.httpProxy;
    _method = p?.method ?? 'aes-256-gcm';
    _systemProxy = p?.systemProxy ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _localPortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.profile == null ? 'Add Profile' : 'Edit Profile',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _label('Protocol'),
              const SizedBox(height: 6),
              SegmentedButton<ProxyType>(
                segments: ProxyType.values
                    .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                    .toList(),
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 14),
              _field(_nameCtrl, 'Profile Name', validator: _required),
              const SizedBox(height: 12),
              _field(_hostCtrl, 'Server Host', validator: _required),
              const SizedBox(height: 12),
              _field(
                _portCtrl,
                'Server Port',
                keyboardType: TextInputType.number,
                validator: _portValidator,
              ),
              if (_type == ProxyType.httpProxy) ...[
                const SizedBox(height: 12),
                _field(_usernameCtrl, 'Username (optional)'),
                const SizedBox(height: 12),
                _field(_passwordCtrl, 'Password (optional)', obscure: true),
              ],
              if (_type == ProxyType.shadowsocks) ...[
                const SizedBox(height: 12),
                _label('Encryption Method'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _method,
                  items: _shadowsocksMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _method = v!),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 12),
                _field(_passwordCtrl, 'Password', obscure: true, validator: _required),
              ],
              const SizedBox(height: 12),
              _field(
                _localPortCtrl,
                'Local Port',
                keyboardType: TextInputType.number,
                validator: _portValidator,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('System-wide proxy'),
                subtitle: Text(
                  'Route all system traffic through this proxy',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                value: _systemProxy,
                onChanged: (v) => setState(() => _systemProxy = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(labelText: label),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _portValidator(String? v) {
    final port = int.tryParse(v ?? '');
    if (port == null || port < 1 || port > 65535) {
      return 'Invalid port';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final profile = ProxyProfile(
      id: widget.profile?.id,
      name: _nameCtrl.text.trim(),
      type: _type,
      host: _hostCtrl.text.trim(),
      port: int.parse(_portCtrl.text.trim()),
      username: _type == ProxyType.httpProxy && _usernameCtrl.text.isNotEmpty
          ? _usernameCtrl.text.trim()
          : null,
      password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      method: _type == ProxyType.shadowsocks ? _method : null,
      localPort: int.parse(_localPortCtrl.text.trim()),
      systemProxy: _systemProxy,
    );

    context.read<AppState>().saveProfile(profile);
    Navigator.of(context).pop();
  }
}

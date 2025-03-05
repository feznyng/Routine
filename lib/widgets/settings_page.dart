import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../auth_service.dart';
import '../theme_provider.dart';
import '../desktop_service.dart';
import '../strict_mode_service.dart';
import '../device.dart';
import '../database.dart';
import '../setup.dart';
import 'auth_page.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  final _desktopService = DesktopService.instance;
  final _strictModeService = StrictModeService.instance;
  bool _startOnLogin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // Get startup setting for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _loadStartupSetting();
    }
    
    // Initialize strict mode service
    _strictModeService.init().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  Future<void> _loadStartupSetting() async {
    try {
      // Add a small delay to ensure desktop service is initialized
      await Future.delayed(const Duration(milliseconds: 100));
      final startOnLogin = await _desktopService.getStartOnLogin();
      if (mounted) {
        setState(() {
          _startOnLogin = startOnLogin;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading startup setting: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAuthPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AuthPage(),
      ),
    );
  }
  
  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.windows:
      case DeviceType.linux:
      case DeviceType.macos:
        return Icons.computer;
      case DeviceType.ios:
      case DeviceType.android:
        return Icons.smartphone;
    }
  }
  
  void _showDeviceOptions(Device device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DeviceOptionsBottomSheet(device: device),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => ListTile(
                title: const Text('Theme'),
                leading: Icon(
                  themeProvider.isSystemMode
                      ? Icons.brightness_auto
                      : themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                ),
                trailing: DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  underline: const SizedBox(),
                  onChanged: (ThemeMode? newMode) {
                    if (newMode != null) {
                      themeProvider.setThemeMode(newMode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System Default'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light Mode'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark Mode'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Start on login option (desktop only)
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
            Card(
              child: ListTile(
                title: const Text('Start on system startup'),
                leading: const Icon(Icons.power_settings_new),
                trailing: _isLoading 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _startOnLogin,
                      onChanged: _strictModeService.inStrictMode
                        ? null  // Disable the switch completely when in strict mode
                        : (value) async {
                            // If trying to disable while effective block is on, show dialog
                            if (!value && _strictModeService.effectiveBlockDisablingSystemStartup) {
                              _strictModeService.showStrictModeActiveDialog(context);
                              return;
                            }
                            
                            setState(() => _isLoading = true);
                            await _desktopService.setStartOnLogin(value);
                            final result = await _desktopService.getStartOnLogin();
                            setState(() {
                              _startOnLogin = result;
                              _isLoading = false;
                            });
                          },
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Strict Mode section
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Strict Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                
                // Warning banner when in strict mode
                if (_strictModeService.inStrictMode) ...[
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Strict Mode Active',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'A routine with strict mode is currently active. You cannot disable strict mode settings until all strict mode routines become inactive.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Desktop strict mode options
                if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
                  SwitchListTile(
                    title: const Text('Block app exit'),
                    subtitle: const Text('Prevent closing the app'),
                    value: _strictModeService.blockAppExit,
                    onChanged: _strictModeService.inStrictMode
                      ? null // Disable the switch completely when in strict mode
                      : (value) async {
                        final success = await _strictModeService.setBlockAppExitWithConfirmation(context, value);
                        if (success && mounted) {
                          setState(() {});
                        }
                      },
                  ),
                  SwitchListTile(
                    title: const Text('Block disabling system startup'),
                    subtitle: const Text('Prevent turning off startup with system'),
                    value: _strictModeService.blockDisablingSystemStartup,
                    onChanged: _strictModeService.inStrictMode
                      ? null // Disable the switch completely when in strict mode
                      : (value) async {
                        final success = await _strictModeService.setBlockDisablingSystemStartupWithConfirmation(context, value);
                        if (success && mounted) {
                          setState(() {});
                        }
                      },
                  ),
                ],
                
                // iOS strict mode options
                if (Platform.isIOS) ...[
                  SwitchListTile(
                    title: const Text('Block changing time settings'),
                    subtitle: const Text('Prevent changing system time'),
                    value: _strictModeService.blockChangingTimeSettings,
                    onChanged: _strictModeService.inStrictMode
                      ? null // Disable the switch completely when in strict mode
                      : (value) async {
                        final success = await _strictModeService.setBlockChangingTimeSettingsWithConfirmation(context, value);
                        if (success && mounted) {
                          setState(() {});
                        }
                      },
                  ),
                  SwitchListTile(
                    title: const Text('Block uninstalling apps'),
                    subtitle: const Text('Prevent uninstalling apps'),
                    value: _strictModeService.blockUninstallingApps,
                    onChanged: _strictModeService.inStrictMode
                      ? null // Disable the switch completely when in strict mode
                      : (value) async {
                        final success = await _strictModeService.setBlockUninstallingAppsWithConfirmation(context, value);
                        if (success && mounted) {
                          setState(() {});
                        }
                      },
                  ),
                  SwitchListTile(
                    title: const Text('Block installing apps'),
                    subtitle: const Text('Prevent installing new apps'),
                    value: _strictModeService.blockInstallingApps,
                    onChanged: _strictModeService.inStrictMode
                      ? null // Disable the switch completely when in strict mode
                      : (value) async {
                        final success = await _strictModeService.setBlockInstallingAppsWithConfirmation(context, value);
                        if (success && mounted) {
                          setState(() {});
                        }
                      },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Device Management section
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Devices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                StreamBuilder<List<Device>>(
                  stream: Device.watchAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    
                    final devices = snapshot.data ?? [];
                    if (devices.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No devices found')),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return Stack(
                          children: [
                            ListTile(
                              title: Text(device.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.curr ? 'Current Device' : device.formattedType),
                                  Text(
                                    device.lastSyncStatus,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              leading: Icon(_getDeviceIcon(device.type)),
                              trailing: SizedBox(width: 24), // Reserve space for the icon
                              onTap: () => _showDeviceOptions(device),
                            ),
                            if (device.curr)
                              Positioned(
                                right: 16,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Icon(Icons.check_circle, color: Colors.green),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (!_authService.isSignedIn) ...[            
            Card(
              child: InkWell(
                onTap: _showAuthPage,
                child: const ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text('Sign In or Create Account'),
                  subtitle: Text('Sync your routines across devices'),
                ),
              ),
            ),
          ] else ...[            
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text('Signed in as ${_authService.currentUser}'),
                trailing: TextButton(
                  onPressed: () async {
                    await _authService.signOut();
                    setState(() {});
                  },
                  child: const Text('Sign Out'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AuthDialog extends StatefulWidget {
  final bool isSignUp;

  const AuthDialog({super.key, this.isSignUp = false});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class DeviceOptionsBottomSheet extends StatefulWidget {
  final Device device;
  
  const DeviceOptionsBottomSheet({super.key, required this.device});
  
  @override
  State<DeviceOptionsBottomSheet> createState() => _DeviceOptionsBottomSheetState();
}

class _DeviceOptionsBottomSheetState extends State<DeviceOptionsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isLoading = false;
  
  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.windows:
      case DeviceType.linux:
      case DeviceType.macos:
        return Icons.computer;
      case DeviceType.ios:
      case DeviceType.android:
        return Icons.smartphone;
    }
  }
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _updateDeviceName() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      widget.device.name = _nameController.text.trim();
      widget.device.save();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating device: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _deleteDevice() async {
    if (widget.device.curr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete the current device')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      widget.device.delete();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting device: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.device.curr ? 'Current Device' : 'Device Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getDeviceIcon(widget.device.type),
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.device.formattedType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.device.lastSyncStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Device name cannot be empty';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateDeviceName,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update Name'),
          ),
          if (!widget.device.curr) ...[  
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isLoading ? null : _deleteDevice,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete Device'),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AuthDialogState extends State<AuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = _isSignUp
          ? await _authService.signUp(_emailController.text, _passwordController.text)
          : await _authService.signIn(_emailController.text, _passwordController.text);

      if (success && mounted) {

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('AuthException: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSignUp ? 'Create account' : 'Sign in',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: _validatePassword,
                    obscureText: true,
                    enabled: !_isLoading,
                  ),
                  if (_isSignUp) ...[                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirm password'),
                      validator: _validateConfirmPassword,
                      obscureText: true,
                      enabled: !_isLoading,
                    ),
                  ],
                  if (_errorMessage != null) ...[                    
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _isSignUp = !_isSignUp);
                            _formKey.currentState?.reset();
                          },
                    child: Text(_isSignUp
                        ? 'Already have an account? Sign in'
                        : 'Need an account? Sign up'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isSignUp ? 'Sign up' : 'Sign in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
    ));
  }
}

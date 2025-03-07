import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'block_apps_dialog.dart';
import 'block_sites_dialog.dart';
import 'app_site_selector.dart';
import 'browser_extension_onboarding_dialog.dart';
import '../services/browser_extension_service.dart';

class BlockGroupEditor extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final List<String>? selectedCategories;
  final Function(List<String>, List<String>, List<String>?) onSave;
  final bool blockSelected;
  final Function(bool) onBlockModeChanged;
  final bool showBlockMode;

  const BlockGroupEditor({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.selectedCategories,
    required this.onSave,
    required this.blockSelected,
    required this.onBlockModeChanged,
    this.showBlockMode = true,
  });

  @override
  State<BlockGroupEditor> createState() => _BlockGroupEditorState();
}

class _BlockGroupEditorState extends State<BlockGroupEditor> {
  late List<String> _selectedApps;
  late List<String> _selectedSites;
  late List<String>? _selectedCategories;
  late bool _blockSelected;

  @override
  void initState() {
    super.initState();
    _selectedApps = List.from(widget.selectedApps);
    _selectedSites = List.from(widget.selectedSites);
    _selectedCategories = List.from(widget.selectedCategories ?? []);
    _blockSelected = widget.blockSelected;
  }

  Future<void> _openAppsDialog() async {
    final result = await showDialog<Map<String, List<String>>>(
      context: context,
      builder: (context) => BlockAppsDialog(
        selectedApps: _selectedApps,
        selectedCategories: _selectedCategories ?? [],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedApps = result['apps'] ?? [];
        _selectedCategories = result['categories'] ?? [];
      });
      widget.onSave(_selectedApps, _selectedSites, _selectedCategories);
    }
  }

  Future<void> _openSitesDialog() async {
    // Check if browser extension setup has been completed
    final browserExtensionService = BrowserExtensionService.instance;
    final isSetupCompleted = await browserExtensionService.isSetupCompleted();
    
    if (!isSetupCompleted && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Show onboarding dialog if setup is not completed
      final result = await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => BrowserExtensionOnboardingDialog(
          selectedSites: _selectedSites,
          onComplete: (sites) {
            // Mark setup as completed
            browserExtensionService.markSetupCompleted();
            Navigator.of(context).pop(sites);
          },
          onSkip: () {
            Navigator.of(context).pop();
          },
        ),
      );
      
      if (result != null) {
        setState(() {
          _selectedSites = result;
        });
        widget.onSave(_selectedApps, _selectedSites, _selectedCategories);
      }
    } else {
      // Show regular sites dialog if setup is completed
      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) => BlockSitesDialog(selectedSites: _selectedSites),
      );

      if (result != null) {
        setState(() {
          _selectedSites = result;
        });
        widget.onSave(_selectedApps, _selectedSites, _selectedCategories);
      }
    }
  }

  String _getAppSubtitle() {
    String appText = '';
    String categoryText = '';
    
    // Handle apps text
    if (_selectedApps.isEmpty) {
      appText = _blockSelected
          ? 'No applications blocked'
          : 'All applications blocked';
    } else {
      String appLabel = _selectedApps.length == 1 ? 'application' : 'applications';
      appText = _blockSelected
          ? '${_selectedApps.length} $appLabel blocked'
          : '${_selectedApps.length} $appLabel allowed';
    }
    
    // Handle categories text
    if (_selectedCategories != null && _selectedCategories!.isNotEmpty) {
      String categoryLabel = Platform.isIOS 
          ? (_selectedCategories!.length == 1 ? 'category' : 'categories')
          : (_selectedCategories!.length == 1 ? 'folder' : 'folders');
          
      categoryText = _blockSelected
          ? '${_selectedCategories!.length} $categoryLabel blocked'
          : '${_selectedCategories!.length} $categoryLabel allowed';
      
      // Combine both texts if both are present
      if (_selectedApps.isNotEmpty) {
        return '$appText, $categoryText';
      }
    }
    
    // If no categories or no apps, return the appropriate text
    return categoryText.isNotEmpty ? categoryText : appText;
  }
  
  String _getCombinedSubtitle() {
    List<String> parts = [];
    String blockModePrefix = _blockSelected ? 'Blocking' : 'Allowing';
    
    // Handle apps
    if (_selectedApps.isNotEmpty) {
      String appLabel = _selectedApps.length == 1 ? 'application' : 'applications';
      parts.add('${_selectedApps.length} $appLabel');
    }
    
    // Handle categories
    if (_selectedCategories != null && _selectedCategories!.isNotEmpty) {
      String categoryLabel = Platform.isIOS 
          ? (_selectedCategories!.length == 1 ? 'category' : 'categories')
          : (_selectedCategories!.length == 1 ? 'folder' : 'folders');
          
      parts.add('${_selectedCategories!.length} $categoryLabel');
    }
    
    // Handle sites
    if (_selectedSites.isNotEmpty) {
      String siteLabel = _selectedSites.length == 1 ? 'site' : 'sites';
      parts.add('${_selectedSites.length} $siteLabel');
    }
    
    // If nothing is selected
    if (parts.isEmpty) {
      return _blockSelected ? 'Blocking nothing' : 'Blocking everything';
    }
    
    // Join all parts with commas and add the block mode at the beginning
    if (parts.length == 1) {
      return '$blockModePrefix ${parts[0]}';
    } else if (parts.length == 2) {
      return '$blockModePrefix ${parts[0]} and ${parts[1]}';
    } else {
      String allButLast = parts.sublist(0, parts.length - 1).join(', ');
      return '$blockModePrefix $allButLast, and ${parts.last}';
    }
  }

  String _getSiteSubtitle() {
    if (_selectedSites.isEmpty) {
      return _blockSelected
          ? 'No sites blocked'
          : 'All sites blocked';
    }
    String siteLabel = _selectedSites.length == 1 ? 'site' : 'sites';
    return _blockSelected
        ? '${_selectedSites.length} $siteLabel blocked'
        : '${_selectedSites.length} $siteLabel allowed';
  }

  Widget _buildBlockButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Card(
      color: enabled ? null : Theme.of(context).disabledColor.withOpacity(0.1),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Use colorScheme.primaryContainer for better dark mode support
                  color: enabled 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  // Use colorScheme.onPrimaryContainer for better contrast in both modes
                  color: enabled 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showBlockMode) ...[            
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Block'),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Allow'),
                      ),
                    ],
                    selected: {_blockSelected},
                    style: ButtonStyle(
                      // Use theme-aware colors for better dark mode support
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (states) => states.contains(MaterialState.selected) 
                          ? Theme.of(context).colorScheme.secondaryContainer 
                          : Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    onSelectionChanged: (Set<bool> newSelection) {
                      print('newSelection: $newSelection');
                      setState(() {
                        _blockSelected = newSelection.first;
                      });
                      widget.onBlockModeChanged(_blockSelected);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          _buildBlockButton(
            title: 'Applications & Websites',
            subtitle: _getCombinedSubtitle(),
            icon: Icons.apps,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AppSiteSelectorPage(
                    selectedApps: _selectedApps,
                    selectedSites: _selectedSites,
                    selectedCategories: _selectedCategories,
                    onSave: (apps, sites, categories) {
                      setState(() {
                        _selectedApps = apps;
                        _selectedSites = sites;
                        _selectedCategories = categories;
                      });
                      widget.onSave(apps, sites, categories);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showBlockMode) ...[
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Block'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Allow'),
                    ),
                  ],
                  selected: {_blockSelected},
                  style: ButtonStyle(
                    // Use theme-aware colors for better dark mode support
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) => states.contains(MaterialState.selected) 
                        ? Theme.of(context).colorScheme.secondaryContainer 
                        : Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  onSelectionChanged: (Set<bool> newSelection) {
                    print('newSelection: $newSelection');
                    setState(() {
                      _blockSelected = newSelection.first;
                    });
                    widget.onBlockModeChanged(_blockSelected);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        _buildBlockButton(
          title: 'Applications',
          subtitle: _getAppSubtitle(),
          icon: Icons.apps,
          onPressed: _openAppsDialog,
        ),
        const SizedBox(height: 5),
        _buildBlockButton(
          title: 'Sites',
          subtitle: _getSiteSubtitle(),
          icon: Icons.language,
          onPressed: _openSitesDialog,
        ),
      ],
    );
  }
  }
}

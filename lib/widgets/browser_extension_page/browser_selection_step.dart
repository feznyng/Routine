import 'package:Routine/services/browser_config.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:Routine/services/strict_mode_service.dart';
import 'package:flutter/material.dart';

/// Step 1: Browser Selection
class BrowserSelectionStep extends StatelessWidget {
  final List<Browser> installedBrowsers;
  final List<Browser> selectedBrowsers;
  final Function(Browser) onToggleBrowser;
  late final StrictModeService _strictModeService;

  BrowserSelectionStep({
    Key? key,
    required this.installedBrowsers,
    required this.selectedBrowsers,
    required this.onToggleBrowser,
  }) : super(key: key) {
    _strictModeService = StrictModeService.instance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (installedBrowsers.isEmpty) {
      return _buildEmptyState(context);
    }

    final connectedBrowsers = installedBrowsers
        .where((b) => BrowserService.instance.isBrowserConnected(b))
        .toList();
    final unconnectedBrowsers = installedBrowsers
        .where((b) => !BrowserService.instance.isBrowserConnected(b))
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: 24),
          
          // Warning message if strict mode is enabled
          if (_strictModeService.effectiveBlockBrowsersWithoutExtension && unconnectedBrowsers.isNotEmpty)
            _buildWarningMessage(context),
          
          // Available browsers section
          if (unconnectedBrowsers.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Select Browsers to Configure',
              Icons.web_rounded,
              colorScheme.onSurface,
            ),
            const SizedBox(height: 12),
            ...unconnectedBrowsers.map((browser) => _buildBrowserCard(context, browser)),
            const SizedBox(height: 24),
          ],
          
          // Connected browsers section
          if (connectedBrowsers.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Already Connected',
              Icons.check_circle_rounded,
              colorScheme.primary,
            ),
            const SizedBox(height: 12),
            ...connectedBrowsers.map((browser) => _buildConnectedBrowserCard(context, browser)),
          ],
          
          // Add some bottom padding to ensure content doesn't get cut off
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.web,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No Supported Browsers Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please install at least one of the following browsers:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  'Chrome',
                  'Firefox', 
                  'Edge',
                  'Safari',
                  'Brave',
                  'Opera'
                ].map((name) => Chip(
                  label: Text(name),
                  backgroundColor: colorScheme.surfaceVariant,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.web_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select Browsers',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which browsers you want to configure for Routine integration.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  
  Widget _buildWarningMessage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Strict Mode Active',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.amber[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Browsers you don\'t configure now will be blocked for at least 10 minutes. '
            'Select all browsers you want to use to avoid interruptions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.amber[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildConnectedBrowserCard(BuildContext context, Browser browser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final browserData = BrowserService.instance.getBrowserData(browser);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _getBrowserIcon(browser, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      browserData.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Already connected and ready to use',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBrowserCard(BuildContext context, Browser browser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final browserData = BrowserService.instance.getBrowserData(browser);
    final isSelected = selectedBrowsers.contains(browser);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: isSelected 
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected 
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onToggleBrowser(browser),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _getBrowserIcon(browser, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    browserData.appName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleBrowser(browser),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getBrowserIcon(Browser browser, {double size = 20}) {
    
    IconData iconData;
    Color iconColor;
    
    // Map browsers to appropriate icons and colors
    switch (browser) {
      case Browser.firefox:
        iconData = Icons.web_rounded;
        iconColor = Colors.orange;
        break;
      case Browser.chrome:
        iconData = Icons.web_rounded;
        iconColor = Colors.blue;
        break;
      case Browser.edge:
        iconData = Icons.web_rounded;
        iconColor = Colors.blue[700]!;
        break;
      case Browser.safari:
        iconData = Icons.web_rounded;
        iconColor = Colors.blue[600]!;
        break;
      case Browser.brave:
        iconData = Icons.web_rounded;
        iconColor = Colors.orange[700]!;
        break;
      case Browser.opera:
        iconData = Icons.web_rounded;
        iconColor = Colors.red;
        break;
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: size * 0.6,
      ),
    );
  }
}

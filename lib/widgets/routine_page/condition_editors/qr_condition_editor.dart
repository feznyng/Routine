import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_selector/file_selector.dart';
import '../../../models/condition.dart';

class QrConditionEditor extends StatefulWidget {
  final Condition condition;
  final TextEditingController nameController;
  final Function(String, {bool isSuccess, bool isError, bool isLoading}) onStatusMessage;

  const QrConditionEditor({
    super.key,
    required this.condition,
    required this.nameController,
    required this.onStatusMessage,
  });

  @override
  State<QrConditionEditor> createState() => _QrConditionEditorState();
}

class _QrConditionEditorState extends State<QrConditionEditor> {
  String? _name;

  @override
  void initState() {
    super.initState();
    _name = widget.nameController.text;
    widget.nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _name = widget.nameController.text;
    });
  }
  bool _isLoading = false;

  /// Checks if the current platform is desktop (macOS, Windows, Linux)
  Future<bool> _isDesktopPlatform() async {
    try {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return true;
      }
    } catch (e) {
      // If Platform is not available, we're probably on web
      return false;
    }
    return false;
  }
  
  /// Gets the downloads directory path for desktop platforms
  Future<String?> _getDownloadsPath() async {
    try {
      if (Platform.isMacOS) {
        final Directory homeDir = Directory(Platform.environment['HOME'] ?? '');
        return '${homeDir.path}/Downloads';
      } else if (Platform.isWindows) {
        final Directory homeDir = Directory(Platform.environment['USERPROFILE'] ?? '');
        return '${homeDir.path}\\Downloads';
      } else if (Platform.isLinux) {
        final Directory homeDir = Directory(Platform.environment['HOME'] ?? '');
        return '${homeDir.path}/Downloads';
      }
    } catch (e) {
      // If we can't get the downloads directory, return null
      return null;
    }
    return null;
  }
  
  /// Saves the QR code as a PNG file
  Future<void> _saveQrCode() async {
    try {
      setState(() => _isLoading = true);

      // Create QR painter
      final painter = QrPainter(
        data: widget.condition.data,
        version: QrVersions.auto,
        gapless: true,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      widget.onStatusMessage('Generating QR code...', isLoading: true);
      
      // Generate image data
      final imageData = await painter.toImageData(600.0);
      if (imageData == null) {
        if (mounted) {
          widget.onStatusMessage('Failed to generate QR code image', isError: true);
        }
        return;
      }
      
      // Convert to Uint8List
      final imageBytes = imageData.buffer.asUint8List();
      const String fileName = 'routine_qr_code.png';
      
      // Check if we're on desktop and should use Downloads directory
      final isDesktop = await _isDesktopPlatform();
      String? initialDirectory;
      
      if (isDesktop) {
        initialDirectory = await _getDownloadsPath();
      }
      
      // Set up file type and suggested name
      final saveLocation = await getSaveLocation(
        suggestedName: fileName,
        initialDirectory: initialDirectory,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'PNG Images',
            extensions: ['png'],
          ),
        ],
      );
      
      if (saveLocation != null) {
        // Create file and write bytes
        final file = XFile.fromData(
          imageBytes,
          mimeType: 'image/png',
          name: fileName,
        );
        
        await file.saveTo(saveLocation.path);
        
        if (mounted) {
          widget.onStatusMessage('QR code saved to: ${saveLocation.path}', isSuccess: true);
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onStatusMessage('Error saving QR code: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'The name will be encoded in the QR code. You can reuse this QR code in a different condition by entering the same name.',
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton.icon(
            icon: _isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) 
              : const Icon(Icons.download),
            label: Text(_isLoading ? 'Processing...' : 
              (_name == null || _name!.isEmpty) ? 'Enter a name first' : 'Download QR Code'),
            onPressed: _isLoading || _name == null || _name!.isEmpty ? null : _saveQrCode,
          ),
        ),
      ],
    );
  }
}

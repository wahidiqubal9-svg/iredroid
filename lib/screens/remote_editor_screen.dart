import 'package:flutter/material.dart';

import '../models/ir_device.dart';

/// Create or edit a remote by adding individual IR buttons.
class CustomRemoteEditor extends StatefulWidget {
  final IRDevice? device;

  const CustomRemoteEditor({super.key, this.device});

  @override
  State<CustomRemoteEditor> createState() => _CustomRemoteEditorState();
}

class _CustomRemoteEditorState extends State<CustomRemoteEditor> {
  late final TextEditingController _nameController;
  late final List<IRButton> _buttons;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device?.name ?? '');
    _buttons =
        widget.device?.buttons
            .map(
              (button) => IRButton(
                name: button.name,
                type: button.type,
                protocol: button.protocol,
                address: button.address,
                command: button.command,
                frequency: button.frequency,
                dutyCycle: button.dutyCycle,
                data: button.data != null ? List<int>.from(button.data!) : null,
              ),
            )
            .toList() ??
        <IRButton>[];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device == null ? 'Create Remote' : 'Edit Remote'),
        actions: [
          TextButton(onPressed: _saveDevice, child: const Text('Save')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Device name',
                hintText: 'Living room TV',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Buttons (${_buttons.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _addButton,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Button'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buttons.isEmpty
                  ? Center(
                      child: Text(
                        'No buttons added yet.\nTap "Add Button" to create your first button.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _buttons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final button = _buttons[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            title: Text(button.name),
                            subtitle: Text(
                              '${button.type} - ${button.protocol ?? 'Raw'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit button',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editButton(index),
                                ),
                                IconButton(
                                  tooltip: 'Delete button',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteButton(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDevice() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('Please enter a device name');
      return;
    }
    if (_buttons.isEmpty) {
      _toast('Please add at least one button');
      return;
    }

    Navigator.pop(
      context,
      IRDevice(
        name: name,
        brand: widget.device?.brand ?? 'Custom',
        category: widget.device?.category ?? 'Custom',
        buttons: _buttons,
      ),
    );
  }

  void _addButton() {
    _showButtonEditor();
  }

  void _editButton(int index) {
    _showButtonEditor(button: _buttons[index], index: index);
  }

  void _deleteButton(int index) {
    setState(() => _buttons.removeAt(index));
  }

  void _showButtonEditor({IRButton? button, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ButtonEditor(
          button: button,
          onSave: (newButton) {
            setState(() {
              if (index != null) {
                _buttons[index] = newButton;
              } else {
                _buttons.add(newButton);
              }
            });
          },
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Editor for a single IR button.
class ButtonEditor extends StatefulWidget {
  final IRButton? button;
  final Function(IRButton) onSave;

  const ButtonEditor({super.key, this.button, required this.onSave});

  @override
  State<ButtonEditor> createState() => _ButtonEditorState();
}

class _ButtonEditorState extends State<ButtonEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _commandController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _dutyCycleController;
  late final TextEditingController _dataController;

  String _selectedType = 'parsed';
  String _selectedProtocol = 'NEC';

  static const List<String> _protocols = [
    'NEC',
    'NECext',
    'Samsung32',
    'RC5',
    'RC6',
    'Sony',
    'Raw',
  ];

  @override
  void initState() {
    super.initState();
    final button = widget.button;
    _nameController = TextEditingController(text: button?.name ?? '');
    _addressController = TextEditingController(text: button?.address ?? '');
    _commandController = TextEditingController(text: button?.command ?? '');
    _frequencyController = TextEditingController(
      text: button?.frequency?.toString() ?? '38000',
    );
    _dutyCycleController = TextEditingController(
      text: button?.dutyCycle?.toString() ?? '0.33',
    );
    _dataController = TextEditingController(
      text: button?.data?.join(' ') ?? '',
    );
    if (button != null) {
      _selectedType = button.type;
      final protocol = button.protocol ?? 'NEC';
      _selectedProtocol = _protocols.contains(protocol) ? protocol : 'NEC';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _commandController.dispose();
    _frequencyController.dispose();
    _dutyCycleController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.button == null ? 'Add Button' : 'Edit Button'),
        actions: [
          TextButton(onPressed: _saveButton, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Button name'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: _inputDecoration('Type'),
              items: const [
                DropdownMenuItem(value: 'parsed', child: Text('Parsed')),
                DropdownMenuItem(value: 'raw', child: Text('Raw')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 14),
            if (_selectedType == 'parsed') ...[
              DropdownButtonFormField<String>(
                value: _selectedProtocol,
                decoration: _inputDecoration('Protocol'),
                items: _protocols
                    .map(
                      (protocol) => DropdownMenuItem(
                        value: protocol,
                        child: Text(protocol),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedProtocol = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addressController,
                decoration: _inputDecoration('Address (hex, e.g. 0x04)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _commandController,
                decoration: _inputDecoration('Command (hex, e.g. 0x08)'),
              ),
            ] else ...[
              TextField(
                controller: _frequencyController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Frequency (Hz)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _dutyCycleController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Duty cycle (e.g. 0.33)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _dataController,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Data (space-separated timings)',
                  hint: '8986 4492 548 548 548 1670...',
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedType == 'parsed'
                        ? 'Parsed signals need an address and command in hex. '
                              'Use values from an IR database or a capture tool.'
                        : 'Raw signals need the carrier frequency, duty cycle and '
                              'timing values in microseconds.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _saveButton() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('Please enter a button name');
      return;
    }

    try {
      List<int>? data;
      if (_selectedType == 'raw' && _dataController.text.trim().isNotEmpty) {
        data = _dataController.text
            .trim()
            .split(RegExp(r'\s+'))
            .where((value) => value.isNotEmpty)
            .map((value) => int.parse(value))
            .toList();
      }

      final button = IRButton(
        name: name,
        type: _selectedType,
        protocol: _selectedType == 'parsed' ? _selectedProtocol : null,
        address:
            _selectedType == 'parsed' &&
                _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        command:
            _selectedType == 'parsed' &&
                _commandController.text.trim().isNotEmpty
            ? _commandController.text.trim()
            : null,
        frequency: _selectedType == 'raw'
            ? int.tryParse(_frequencyController.text.trim())
            : null,
        dutyCycle: _selectedType == 'raw'
            ? double.tryParse(_dutyCycleController.text.trim())
            : null,
        data: data,
      );

      widget.onSave(button);
      Navigator.pop(context);
    } catch (error) {
      _toast('Error creating button: $error');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

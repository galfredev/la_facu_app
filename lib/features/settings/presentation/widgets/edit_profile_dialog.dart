import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:la_facu/core/theme/app_theme.dart';
import 'package:la_facu/features/settings/data/user_repository.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _uniController = TextEditingController();
  final _careerController = TextEditingController();
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final user = await ref.read(userRepositoryProvider.future);
    if (user != null) {
      _nameController.text = user.name ?? '';
      _bioController.text = user.bio ?? '';
      _uniController.text = user.university ?? '';
      _careerController.text = user.career ?? '';
      _photoPath = user.photoPath;
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _photoPath = result.files.single.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Editar Perfil',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _photoPath != null
                        ? Image.file(File(_photoPath!), fit: BoxFit.cover)
                        : const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildField(
              label: 'Nombre',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
            ),
            _buildField(
              label: 'Descripción / Bio',
              controller: _bioController,
              icon: Icons.info_outline_rounded,
              maxLines: 2,
            ),
            _buildField(
              label: 'Universidad',
              controller: _uniController,
              icon: Icons.account_balance_rounded,
            ),
            _buildField(
              label: 'Carrera',
              controller: _careerController,
              icon: Icons.school_outlined,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            await ref
                .read(userRepositoryProvider.notifier)
                .updateProfile(
                  name: _nameController.text,
                  bio: _bioController.text,
                  university: _uniController.text,
                  career: _careerController.text,
                  photoPath: _photoPath,
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

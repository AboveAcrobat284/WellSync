import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'login_user_screen.dart';

class EditMyProfileScreen extends StatefulWidget {
  final String userUuid;
  final String leadUuid;

  const EditMyProfileScreen({super.key, required this.userUuid, required this.leadUuid});

  @override
  State<EditMyProfileScreen> createState() => _EditMyProfileScreenState();
}

class _EditMyProfileScreenState extends State<EditMyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  File? _imageFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/lead/get/${widget.leadUuid}'),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          firstNameController.text = userData['first_Name'] ?? '';
          lastNameController.text = userData['last_Name'] ?? '';
          emailController.text = userData['correo'] ?? '';
          phoneController.text = userData['phone'] ?? '';
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar el perfil');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el perfil: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateProfile() async {
    final updatedData = {
      "first_Name": firstNameController.text,
      "last_Name": lastNameController.text,
      "email": emailController.text,
      "phone": phoneController.text,
    };

    final response = await http.put(
      Uri.parse('https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/lead/update/${widget.leadUuid}'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadProfileImage() async {
    if (_imageFile == null) return;

    final fileExtension = _imageFile!.path.split('.').last.toLowerCase();
    if (fileExtension != 'jpg' && fileExtension != 'png') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El archivo debe ser una imagen .jpg o .png')),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/profile/picture/${widget.userUuid}'),
    );

    request.files.add(await http.MultipartFile.fromPath('profilePicture', _imageFile!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagen de perfil actualizada')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la imagen de perfil')),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(Icons.delete, color: Colors.red, size: 50),
          content: const Text(
            'Estás a punto de eliminar tu cuenta\n\n¿Estás seguro?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAccount() async {
    try {
      final userResponse = await http.delete(
        Uri.parse('https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/users/delete/${widget.userUuid}'),
      );

      final leadResponse = await http.delete(
        Uri.parse('https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/lead/${widget.leadUuid}'),
      );

      if (userResponse.statusCode == 200 && leadResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado exitosamente')),
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('userUuid');
        await prefs.remove('leadUuid');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginUserScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        throw Exception('Error al eliminar la cuenta');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la cuenta: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar una foto'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteAccountDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfileField(controller: firstNameController, label: "Nombre"),
                    ProfileField(controller: lastNameController, label: "Apellido"),
                    ProfileField(controller: emailController, label: "Correo electrónico"),
                    ProfileField(controller: phoneController, label: "Número"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await updateProfile();
                        await uploadProfileImage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const ProfileField({Key? key, required this.controller, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.edit),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

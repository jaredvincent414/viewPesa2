import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/dbhelper.dart';
import '../models/user_models.dart';

class ViewpesaProfile extends StatefulWidget {
  const ViewpesaProfile({super.key});

  @override
  _ViewpesaProfileState createState() => _ViewpesaProfileState();
}

class _ViewpesaProfileState extends State<ViewpesaProfile> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final DBHelper _dbHelper = DBHelper();
  String? _imagePath;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      final user = await _dbHelper.getUserById(userId);
      if (mounted) {
        if (user != null) {
          setState(() {
            _user = user;
            _usernameController.text = user.username;
            _phoneController.text = user.phoneNumber;
            _imagePath = user.imagePath;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${directory.path}/$fileName';
      final newImage = await File(pickedFile.path).copy(newPath);

      if (mounted) {
        setState(() {
          _imagePath = newImage.path;
        });
        await _updateImagePath(_imagePath);
      }
    }
  }

  Future<void> _deleteImage() async {
    if (_imagePath != null) {
      final file = File(_imagePath!);
      if (await file.exists()) {
        await file.delete();
      }
      if (mounted) {
        setState(() {
          _imagePath = null;
        });
        await _updateImagePath(null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image deleted')),
        );
      }
    }
  }

  Future<void> _updateImagePath(String? path) async {
    if (_user != null) {
      final updatedUser = _user!.copyWith(imagePath: path);
      await _dbHelper.updateUser(updatedUser);
      if (mounted) {
        setState(() {
          _user = updatedUser;
        });
      }
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      if (_user != null) {
        final updatedUser = UserModel(
          id: _user!.id,
          phoneNumber: _phoneController.text.trim(),
          username: _usernameController.text.trim(),
          password: _user!.password,
          imagePath: _imagePath,
        );
        try {
          await _dbHelper.updateUser(updatedUser);
          if (mounted) {
            setState(() {
              _user = updatedUser;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated')),
            );
            Navigator.pop(context); // Close dialog
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter username' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value!.startsWith('+254') && value.length == 13
                      ? null
                      : 'Enter valid phone (+254 format)',
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700]),
                  child: const Text('Pick Image'),
                ),
                if (_imagePath != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _deleteImage,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete Image'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveUser,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700]),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontStyle: FontStyle.normal,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: Colors.greenAccent[700],
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _imagePath != null &&
                                File(_imagePath!).existsSync()
                                ? FileImage(File(_imagePath!))
                                : const NetworkImage(
                              'https://plus.unsplash.com/premium_photo-1683140621573-233422bfc7f1?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8cHJvZmlsZSUyMGltYWdlfGVufDB8fDB8fHww',
                            ) as ImageProvider,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _usernameController.text.isEmpty
                                ? 'Username'
                                : _usernameController.text,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _phoneController.text.isEmpty
                                ? 'Phone Number'
                                : _phoneController.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 30,
                  child: IconButton(
                    onPressed: _showEditDialog,
                    icon: const Icon(Icons.edit, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.receipt_long, color: Colors.greenAccent[700]),
                  title: const Text('Transactions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/transactions'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.analytics, color: Colors.greenAccent[700]),
                  title: const Text('Analytics'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Analytics page not implemented')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.upload_file, color: Colors.greenAccent[700]),
                  title: const Text('Export'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/export'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.help_outline, color: Colors.greenAccent),
                  title: Text('Get Help'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chat_screen.dart';
import 'community_screen.dart';
import 'edit_my_profile_screen.dart';
import 'graphics_screen.dart';
import 'login_user_screen.dart';

class MyProfileScreen extends StatefulWidget {
  final String userUuid;
  final String leadUuid;

  const MyProfileScreen({super.key, required this.userUuid, required this.leadUuid});

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late Future<Map<String, dynamic>> _userProfileData;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfileData(); // Refrescar datos cada vez que se entra a esta vista
  }

  void _loadProfileData() {
    _userProfileData = fetchUserProfile(widget.leadUuid);
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      String imageUrl = await fetchProfileImage(widget.userUuid);
      setState(() {
        _profileImageUrl = imageUrl.isNotEmpty ? imageUrl : null; // Manejar imagen no existente
      });
    } catch (e) {
      setState(() {
        _profileImageUrl = null; // Mostrar ícono predeterminado si falla la carga
      });
      print("Error al cargar la imagen de perfil: $e");
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String leadUuid) async {
    final response = await http.get(
      Uri.parse('https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/lead/get/$leadUuid'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener el perfil del usuario');
    }
  }

  Future<String> fetchProfileImage(String userUuid) async {
    final response = await http.get(
      Uri.parse('https://0dqw4sfw-3010.usw3.devtunnels.ms/api/v1/profile/get/$userUuid'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url'] ?? '';
    } else {
      throw Exception('Error al obtener la imagen de perfil');
    }
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userUuid');
    await prefs.remove('leadUuid');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginUserScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _updateProfileAndReload() async {
    await Future.delayed(const Duration(seconds: 10)); // Ajustar si es necesario
    setState(() {
      _loadProfileData(); // Forzar la recarga de datos después de la edición
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Perfil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditMyProfileScreen(userUuid: widget.userUuid, leadUuid: widget.leadUuid),
                ),
              );
              if (result == true) {
                await _updateProfileAndReload();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final userData = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!) as ImageProvider
                        : null,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 74),
                  ProfileInfoRow(title: "Nombre:", content: userData['first_Name'] ?? 'N/A'),
                  ProfileInfoRow(title: "Apellido:", content: userData['last_Name'] ?? 'N/A'),
                  ProfileInfoRow(title: "Correo electrónico:", content: userData['correo'] ?? 'N/A'),
                  ProfileInfoRow(title: "Número:", content: userData['phone'] ?? 'N/A'),
                  const SizedBox(height: 54),
                  ElevatedButton(
                    onPressed: () => logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text("Cerrar sesión", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: _BottomNavigationBarWithAnimation(
        selectedIndex: 4,
        userUuid: widget.userUuid, // Pasar el userUuid recibido en MyProfileScreen
        leadUuid: widget.leadUuid, // Pasar el leadUuid recibido en MyProfileScreen
      ),

    );
  }
}

// Barra de navegación inferior con animación
  class _BottomNavigationBarWithAnimation extends StatefulWidget {
    final int selectedIndex;
    final String userUuid;
    final String leadUuid; 

    const _BottomNavigationBarWithAnimation({
    Key? key,
    required this.selectedIndex,
    required this.userUuid, // Hacerlo requerido
    required this.leadUuid, // Hacerlo requerido
    }) : super(key: key);

    @override
    __BottomNavigationBarWithAnimationState createState() =>
        __BottomNavigationBarWithAnimationState();
  }

  class __BottomNavigationBarWithAnimationState extends State<_BottomNavigationBarWithAnimation> {
    int _selectedIndex = 0;

    final List<IconData> _icons = [
      Icons.home,
      Icons.chat_bubble_outline,
      Icons.show_chart,
      Icons.group_outlined,
      Icons.person_outline,
    ];

    @override
    void initState() {
      super.initState();
      _selectedIndex = widget.selectedIndex;
    }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst); // Regresa a Home
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userUuid: widget.userUuid, // Usar widget.userUuid
            leadUuid: widget.leadUuid, // Usar widget.leadUuid
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GraphicsScreen(
            userUuid: widget.userUuid,
            leadUuid: widget.leadUuid,
          ),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(
            userUuid: widget.userUuid,
            leadUuid: widget.leadUuid,
          ),
        ),
      );
    } else if (index == 4) {
      // Ya estamos en la pantalla de perfil
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _icons.asMap().entries.map((entry) {
              int index = entry.key;
              IconData icon = entry.value;
              bool isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
            left: MediaQuery.of(context).size.width * (_selectedIndex / _icons.length) +
                MediaQuery.of(context).size.width / _icons.length / 2 -
                30,
            top: 0,
            child: ClipPath(
              clipper: SmoothUShapeClipper(),
              child: Container(
                color: Colors.white,
                width: 70,
                height: 50,
                alignment: Alignment.center,
                child: Icon(
                  _icons[_selectedIndex],
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ClipPath personalizado para una curva en forma de "U" ajustable
class SmoothUShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();

    path.moveTo(0, size.height * 0);

    path.quadraticBezierTo(
      size.width * 0.2, size.height,
      size.width * 0.5, size.height,
    );

    path.quadraticBezierTo(
      size.width * 0.8, size.height,
      size.width, size.height * 0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ProfileInfoRow extends StatelessWidget {
  final String title;
  final String content;

  const ProfileInfoRow({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }
}

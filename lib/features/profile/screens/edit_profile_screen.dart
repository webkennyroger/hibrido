import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
// Certifique-se de que o caminho para o seu arquivo de cores está correto
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/profile/models/user_model.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controladores para capturar os dados dos campos de texto
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _locationController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  // Estado para armazenar a imagem selecionada da galeria
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores com os dados do usuário recebidos
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _locationController = TextEditingController(text: widget.user.location);
    _heightController = TextEditingController(text: widget.user.height);
    _weightController = TextEditingController(text: widget.user.weight);
    // Se o usuário já tiver uma imagem selecionada, usa-a
    _selectedImage = widget.user.selectedImageFile;
  }

  // --- Widgets Auxiliares ---

  /// Constrói um campo de texto estilizado para o formulário.
  Widget _buildTextField({
    required String labelText,
    required TextEditingController controller,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rótulo
          Text(
            labelText,
            style: GoogleFonts.lexend(
              color: colors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Campo de input
          TextFormField(
            controller: controller,
            readOnly: isReadOnly,
            style: GoogleFonts.lexend(
              color: colors.text, // Texto do campo escuro
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 18,
              ),
              prefixIcon: Icon(icon, color: colors.text),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none, // Remove a borda padrão
              ),
              suffixIcon: isReadOnly
                  ? Icon(
                      Icons.lock_outline,
                      color: colors.text.withOpacity(0.5),
                      size: 20,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// NOVO: Mostra um menu para escolher entre Câmera e Galeria.
  void _showImageSourceActionSheet(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: colors.text),
                title: Text('Galeria', style: TextStyle(color: colors.text)),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: colors.text),
                title: Text('Câmera', style: TextStyle(color: colors.text)),
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

  /// Função para abrir a galeria ou câmera e selecionar uma imagem.
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    // Abre a galeria para o usuário escolher uma imagem.
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      // Atualiza o estado para exibir a nova imagem selecionada.
      setState(() => _selectedImage = File(image.path));
    }
  }

  // --- Widget Principal ---

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 1. IMAGEM DO PERFIL E BOTÃO DE EDIÇÃO
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  // Exibe a imagem selecionada ou a imagem padrão
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : widget.user.profileImage,
                  backgroundColor: colors.background,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImageSourceActionSheet(
                      context,
                    ), // Chama o menu de opções
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary, // Círculo de edição verde
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.background, width: 3),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colors.background,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 2. FORMULÁRIO DE EDIÇÃO
            _buildTextField(
              labelText: 'Nome Completo',
              controller: _nameController,
              icon: Icons.person_outline,
            ),
            _buildTextField(
              labelText: 'E-mail',
              // O e-mail agora é editável
              controller: _emailController,
              icon: Icons.email_outlined,
            ),
            _buildTextField(
              labelText: 'Senha',
              // Senha é um campo sensível, não preenchemos o valor antigo
              controller: TextEditingController(text: '********'),
              icon: Icons.vpn_key_outlined,
            ),
            _buildTextField(
              labelText: 'Altura (cm)',
              controller: _heightController,
              icon: Icons.height,
            ),
            _buildTextField(
              labelText: 'Peso (kg)',
              controller: _weightController,
              icon: Icons.monitor_weight_outlined,
            ),
            _buildTextField(
              labelText: 'Localização',
              controller: _locationController,
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 40),

            // 3. BOTÃO DE SALVAR
            GestureDetector(
              onTap: () {
                // Cria um novo objeto UserModel com os dados atualizados
                final updatedUser = UserModel(
                  id: widget.user.id, // Adiciona o ID do usuário existente
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  location: _locationController.text.trim(),
                  height: _heightController.text.trim(),
                  weight: _weightController.text.trim(),
                  selectedImageFile: _selectedImage,
                  imagePath: widget.user.imagePath, // Mantém o asset original
                );
                // NOVO: Atualiza o usuário através do provider
                context.read<UserProvider>().updateUser(updatedUser);
                // Retorna para a tela anterior (ProfileScreen) com os novos dados
                Navigator.of(context).pop(updatedUser);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: AppColors.primary, // Botão de destaque verde
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(150),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'SALVAR ALTERAÇÕES',
                    style: GoogleFonts.lexend(
                      color: AppColors.dark().background,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

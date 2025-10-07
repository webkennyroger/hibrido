import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Certifique-se de que o caminho para o seu arquivo de cores está correto
import 'package:hibrido/core/theme/custom_colors.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  // Lista mock de Perguntas e Respostas
  final List<Map<String, String>> faqData = const [
    {
      'question': 'Como faço para iniciar uma nova atividade?',
      'answer':
          'Na tela principal (Mapa), selecione seu esporte no topo e toque no botão verde grande "INICIAR". O monitoramento começará imediatamente.',
    },
    {
      'question': 'Como altero o tipo de mapa (Satélite, Padrão)?',
      'answer':
          'Durante uma atividade, ou na tela de confirmação após terminar, você pode tocar no ícone de "Configurações" (engrenagem) no mapa para alterar a visualização entre Padrão, Satélite ou Híbrido.',
    },
    {
      'question': 'Posso adicionar fotos e anotações às minhas atividades?',
      'answer':
          'Sim! Após tocar em "CONCLUIR", a tela de confirmação permitirá que você adicione fotos (da galeria ou câmera), edite o título, insira anotações e defina o humor e privacidade.',
    },
    {
      'question': 'Onde encontro minhas estatísticas detalhadas?',
      'answer':
          'Suas estatísticas e histórico de atividades estão disponíveis na tela "Perfil" e também na seção "Progresso" (caso tenha uma).',
    },
    {
      'question': 'Como faço para alterar minha senha e e-mail?',
      'answer':
          'Vá para a tela "Perfil", toque no ícone de "Editar Perfil" (lápis) e você terá acesso aos campos de Nome Completo, Senha e outros dados de conta.',
    },
  ];

  /// Constrói o item de Pergunta e Resposta (ExpansionTile).
  Widget _buildFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface, // Fundo Cinza Claro do card
        borderRadius: BorderRadius.circular(15),
      ),
      child: Theme(
        // Remove a linha divisória padrão do ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary, // Ícone de seta verde
          collapsedIconColor: AppColors.primary,
          // Título da Pergunta
          title: Text(
            question,
            style: GoogleFonts.lexend(
              color: colors.text, // Cor do texto da pergunta (Cinza Escuro)
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Conteúdo da Resposta
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                answer,
                style: GoogleFonts.lexend(
                  color: colors.textSecondary, // Cor do texto da resposta
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background, // Fundo escuro
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ajuda e FAQ',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descrição da seção
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Perguntas Frequentes',
                style: GoogleFonts.lexend(
                  color: colors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Lista de FAQ
            ...faqData.map((item) {
              return _buildFaqItem(
                context: context,
                question: item['question']!,
                answer: item['answer']!,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

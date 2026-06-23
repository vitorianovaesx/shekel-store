import 'dart:math';

class InvestmentAsset {
  final String id;
  final String name;
  final String imagePath;
  final String description;
  final String satiricalQuote;
  final double minMultiplier;
  final double maxMultiplier;
  final bool alwaysLoss;

  const InvestmentAsset({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.satiricalQuote,
    required this.minMultiplier,
    required this.maxMultiplier,
    this.alwaysLoss = false,
  });

  double generateMultiplier(Random rng) {
    final effectiveMax = alwaysLoss ? min(maxMultiplier, 0.9999) : maxMultiplier;
    return minMultiplier + rng.nextDouble() * (effectiveMax - minMultiplier);
  }

  static const List<InvestmentAsset> all = [
    InvestmentAsset(
      id: 'kibbutz',
      name: 'Kibbutz Coletivo',
      imagePath: 'assets/images/kibbutz.png',
      description: 'Fazenda comunitária onde todos são iguais (alguns mais que outros)',
      satiricalQuote: 'Comunismo funcional. Quase. Tipo, muito quase.',
      minMultiplier: 0.90,
      maxMultiplier: 1.45,
    ),
    InvestmentAsset(
      id: 'startup',
      name: 'Startup de Tel Aviv',
      imagePath: 'assets/images/startup.png',
      description: 'Tech de ponta, queima de caixa premium e bean bags de grife',
      satiricalQuote: 'Levanta 50M, gasta em ping-pong, entra em colapso em 18 meses. Mas e se dessa vez...',
      minMultiplier: 0.30,
      maxMultiplier: 5.00,
    ),
    InvestmentAsset(
      id: 'hummus',
      name: 'Hummus Corp',
      imagePath: 'assets/images/hummus.png',
      description: 'Exportação de hummus premium para o mundo que discorda de quem inventou',
      satiricalQuote: 'Guerras vão e vêm. O hummus é eterno. O ativo mais sólido do Oriente Médio.',
      minMultiplier: 0.95,
      maxMultiplier: 1.60,
    ),
    InvestmentAsset(
      id: 'dead_sea',
      name: 'Minerais do Mar Morto',
      imagePath: 'assets/images/dead_sea.png',
      description: 'Vender lama cara para turistas europeus com culpa existencial',
      satiricalQuote: 'O mar está morto mas o negócio tá vivo. Vender barro por 200 euros: arte pura.',
      minMultiplier: 0.85,
      maxMultiplier: 2.20,
    ),
    InvestmentAsset(
      id: 'diamonds',
      name: 'Diamantes de Ramat Gan',
      imagePath: 'assets/images/diamond.png',
      description: 'Hub diamantífero mundial que controla mais do que você imagina',
      satiricalQuote: 'Diamante dura para sempre. Seu saldo, definitivamente não. Alta volatilidade garantida.',
      minMultiplier: 0.40,
      maxMultiplier: 4.50,
    ),
    InvestmentAsset(
      id: 'yeshiva',
      name: 'Yeshiva Premium',
      imagePath: 'assets/images/yeshiva.png',
      description: 'Patrocínio de jovens estudando Talmude para fugir do exército',
      satiricalQuote: 'Seu dinheiro financia a evasão do serviço militar. O retorno é espiritual. Só.',
      minMultiplier: 0.55,
      maxMultiplier: 1.08,
    ),
    InvestmentAsset(
      id: 'idf',
      name: 'IDF S.A.',
      imagePath: 'assets/images/idf.png',
      description: 'O glorioso complexo militar-industrial. Consistentemente ruim para carteiras.',
      satiricalQuote: 'Investir em guerra: uma tragédia garantida para seus shekels. NUNCA acima de 1.0x.',
      minMultiplier: 0.05,
      maxMultiplier: 0.95,
      alwaysLoss: true,
    ),
    InvestmentAsset(
      id: 'falafel',
      name: 'Falafel & Cia',
      imagePath: 'assets/images/falafel.png',
      description: 'Rede de fast-food israelense (os libaneses discordam da origem)',
      satiricalQuote: 'Simples, honesto, vai te decepcionar de forma agradável. Como toda relação.',
      minMultiplier: 0.80,
      maxMultiplier: 1.90,
    ),
    InvestmentAsset(
      id: 'mossad',
      name: 'Operacoes Mossad',
      imagePath: 'assets/images/mossad.png',
      description: 'Servico de inteligencia dramatico que agora aceita capital externo',
      satiricalQuote: 'Voce investe. Eles fazem o que querem. As vezes da certo. Provavelmente nao.',
      minMultiplier: 0.20,
      maxMultiplier: 3.50,
    ),
    InvestmentAsset(
      id: 'iron_dome',
      name: 'Iron Dome',
      imagePath: 'assets/images/iron_dome.png',
      description: 'Intercepta 90% dos foguetes e 100% dos seus lucros',
      satiricalQuote: 'Eficaz contra misseis. Completamente ineficaz em proteger seus shekels. Ironico.',
      minMultiplier: 0.10,
      maxMultiplier: 0.90,
      alwaysLoss: true,
    ),
  ];
}

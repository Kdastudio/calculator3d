class EnergyRegion {
  const EnergyRegion({
    required this.state,
    required this.uf,
    required this.region,
    required this.distributor,
    required this.ratePerKwh,
  });

  final String state;
  final String uf;
  final String region;
  final String distributor;
  final double ratePerKwh;

  static const regions = ['Norte', 'Nordeste', 'Centro-Oeste', 'Sudeste', 'Sul'];

  static const all = [
    EnergyRegion(state: 'Acre', uf: 'AC', region: 'Norte', distributor: 'Energisa AC', ratePerKwh: 0.95),
    EnergyRegion(state: 'Alagoas', uf: 'AL', region: 'Nordeste', distributor: 'Equatorial AL', ratePerKwh: 0.98),
    EnergyRegion(state: 'Amapá', uf: 'AP', region: 'Norte', distributor: 'CEA', ratePerKwh: 0.92),
    EnergyRegion(state: 'Amazonas', uf: 'AM', region: 'Norte', distributor: 'Amazonas Energia', ratePerKwh: 1.02),
    EnergyRegion(state: 'Bahia', uf: 'BA', region: 'Nordeste', distributor: 'Neoenergia Coelba', ratePerKwh: 0.95),
    EnergyRegion(state: 'Ceará', uf: 'CE', region: 'Nordeste', distributor: 'Enel CE', ratePerKwh: 0.96),
    EnergyRegion(state: 'Distrito Federal', uf: 'DF', region: 'Centro-Oeste', distributor: 'Neoenergia Brasília', ratePerKwh: 0.80),
    EnergyRegion(state: 'Espírito Santo', uf: 'ES', region: 'Sudeste', distributor: 'EDP ES', ratePerKwh: 0.88),
    EnergyRegion(state: 'Goiás', uf: 'GO', region: 'Centro-Oeste', distributor: 'Equatorial GO', ratePerKwh: 0.85),
    EnergyRegion(state: 'Maranhão', uf: 'MA', region: 'Nordeste', distributor: 'Equatorial MA', ratePerKwh: 0.94),
    EnergyRegion(state: 'Mato Grosso', uf: 'MT', region: 'Centro-Oeste', distributor: 'Energisa MT', ratePerKwh: 0.91),
    EnergyRegion(state: 'Mato Grosso do Sul', uf: 'MS', region: 'Centro-Oeste', distributor: 'Energisa MS', ratePerKwh: 0.89),
    EnergyRegion(state: 'Minas Gerais', uf: 'MG', region: 'Sudeste', distributor: 'Cemig', ratePerKwh: 0.98),
    EnergyRegion(state: 'Pará', uf: 'PA', region: 'Norte', distributor: 'Equatorial PA', ratePerKwh: 1.05),
    EnergyRegion(state: 'Paraíba', uf: 'PB', region: 'Nordeste', distributor: 'Energisa PB', ratePerKwh: 0.93),
    EnergyRegion(state: 'Paraná', uf: 'PR', region: 'Sul', distributor: 'Copel', ratePerKwh: 0.85),
    EnergyRegion(state: 'Pernambuco', uf: 'PE', region: 'Nordeste', distributor: 'Neoenergia Pernambuco', ratePerKwh: 0.97),
    EnergyRegion(state: 'Piauí', uf: 'PI', region: 'Nordeste', distributor: 'Equatorial PI', ratePerKwh: 0.96),
    EnergyRegion(state: 'Rio de Janeiro', uf: 'RJ', region: 'Sudeste', distributor: 'Light', ratePerKwh: 1.05),
    EnergyRegion(state: 'Rio Grande do Norte', uf: 'RN', region: 'Nordeste', distributor: 'Neoenergia Cosern', ratePerKwh: 0.94),
    EnergyRegion(state: 'Rio Grande do Sul', uf: 'RS', region: 'Sul', distributor: 'CEEE Equatorial', ratePerKwh: 0.88),
    EnergyRegion(state: 'Rondônia', uf: 'RO', region: 'Norte', distributor: 'Energisa RO', ratePerKwh: 0.90),
    EnergyRegion(state: 'Roraima', uf: 'RR', region: 'Norte', distributor: 'Roraima Energia', ratePerKwh: 0.92),
    EnergyRegion(state: 'Santa Catarina', uf: 'SC', region: 'Sul', distributor: 'Celesc', ratePerKwh: 0.82),
    EnergyRegion(state: 'São Paulo', uf: 'SP', region: 'Sudeste', distributor: 'Enel SP', ratePerKwh: 0.92),
    EnergyRegion(state: 'Sergipe', uf: 'SE', region: 'Nordeste', distributor: 'Energisa SE', ratePerKwh: 0.96),
    EnergyRegion(state: 'Tocantins', uf: 'TO', region: 'Norte', distributor: 'Energisa TO', ratePerKwh: 0.87),
  ];

  static EnergyRegion? findByState(String state) {
    for (final r in all) {
      if (r.state == state) return r;
    }
    return null;
  }

  static List<EnergyRegion> byRegion(String region) =>
      all.where((r) => r.region == region).toList();

  static Map<String, double> toLegacyRatesMap() =>
      {for (final r in all) r.state: r.ratePerKwh};
}

enum TariffFlag {
  none('Nenhuma', 0),
  green('Verde', 0),
  yellow('Amarela', 0.01874),
  red1('Vermelha P1', 0.03971),
  red2('Vermelha P2', 0.09492);

  const TariffFlag(this.label, this.surchargePerKwh);

  final String label;
  final double surchargePerKwh;
}

class MarginPreset {
  const MarginPreset({
    required this.id,
    required this.label,
    required this.profitMargin,
    required this.riskPercent,
    required this.description,
  });

  final String id;
  final String label;
  final double profitMargin;
  final double riskPercent;
  final String description;

  static const hobby = MarginPreset(
    id: 'hobby',
    label: 'Hobby',
    profitMargin: 50,
    riskPercent: 5,
    description: 'Peças pessoais e testes',
  );

  static const professional = MarginPreset(
    id: 'professional',
    label: 'Profissional',
    profitMargin: 100,
    riskPercent: 10,
    description: 'Produção comercial padrão',
  );

  static const marketplace = MarginPreset(
    id: 'marketplace',
    label: 'Marketplace',
    profitMargin: 150,
    riskPercent: 15,
    description: 'Vendas em plataformas online',
  );

  static const all = [hobby, professional, marketplace];

  static MarginPreset? find(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class UserProfile {
  UserProfile({
    required this.id,
    this.email,
    this.displayName = '',
    this.companyName = '',
    this.companyEmail = '',
    this.companyPhone = '',
    this.companySlogan = 'Soluções em Manufatura Aditiva',
    this.logoPath,
    this.currencyCode = 'BRL',
  });

  final String id;
  final String? email;
  final String displayName;
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String companySlogan;
  final String? logoPath;
  final String currencyCode;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['display_name'] as String? ?? '',
        companyName: json['company_name'] as String? ?? '',
        companyEmail: json['company_email'] as String? ?? '',
        companyPhone: json['company_phone'] as String? ?? '',
        companySlogan: json['company_slogan'] as String? ?? 'Soluções em Manufatura Aditiva',
        logoPath: json['logo_path'] as String?,
        currencyCode: json['currency_code'] as String? ?? 'BRL',
      );

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'company_name': companyName,
        'company_email': companyEmail,
        'company_phone': companyPhone,
        'company_slogan': companySlogan,
        'logo_path': logoPath,
        'currency_code': currencyCode,
      };
}

class SavedCalculation {
  SavedCalculation({
    required this.id,
    required this.title,
    required this.costInputs,
    required this.taxInputs,
    required this.currencyCode,
    this.results,
    this.gcodePath,
    this.gcodeFilename,
    required this.updatedAt,
  });

  final String id;
  final Map<String, dynamic> costInputs;
  final Map<String, dynamic> taxInputs;
  final String currencyCode;
  final Map<String, dynamic>? results;
  final String title;
  final String? gcodePath;
  final String? gcodeFilename;
  final DateTime updatedAt;

  factory SavedCalculation.fromJson(Map<String, dynamic> json) => SavedCalculation(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Cálculo',
        costInputs: Map<String, dynamic>.from(json['cost_inputs'] as Map? ?? {}),
        taxInputs: Map<String, dynamic>.from(json['tax_inputs'] as Map? ?? {}),
        currencyCode: json['currency_code'] as String? ?? 'BRL',
        results: json['results'] != null
            ? Map<String, dynamic>.from(json['results'] as Map)
            : null,
        gcodePath: json['gcode_path'] as String?,
        gcodeFilename: json['gcode_filename'] as String?,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class SavedQuote {
  SavedQuote({
    required this.id,
    required this.quoteNumber,
    required this.clientName,
    required this.contact,
    required this.quoteDate,
    required this.items,
    required this.discountPercent,
    required this.shippingCost,
    required this.observations,
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.companySlogan,
    this.logoPath,
    required this.currencyCode,
    required this.updatedAt,
  });

  final String id;
  final String quoteNumber;
  final String clientName;
  final String contact;
  final String quoteDate;
  final List<dynamic> items;
  final double discountPercent;
  final double shippingCost;
  final String observations;
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String companySlogan;
  final String? logoPath;
  final String currencyCode;
  final DateTime updatedAt;

  factory SavedQuote.fromJson(Map<String, dynamic> json) => SavedQuote(
        id: json['id'] as String,
        quoteNumber: json['quote_number'] as String? ?? '',
        clientName: json['client_name'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
        quoteDate: json['quote_date'] as String? ?? '',
        items: json['items'] as List<dynamic>? ?? [],
        discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
        shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0,
        observations: json['observations'] as String? ?? '',
        companyName: json['company_name'] as String? ?? '',
        companyEmail: json['company_email'] as String? ?? '',
        companyPhone: json['company_phone'] as String? ?? '',
        companySlogan: json['company_slogan'] as String? ?? '',
        logoPath: json['logo_path'] as String?,
        currencyCode: json['currency_code'] as String? ?? 'BRL',
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

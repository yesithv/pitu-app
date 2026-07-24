/// Planes disponibles en Fase 1. Premium (suscripción) llega en Fase 2.
enum PlanType { free, pro }

/// Límites de negocio por plan (RN-01, RN-02). Centralizados aquí para que la
/// evaluación de límites viva en el dominio, no dispersa por la UI.
class PlanLimits {
  const PlanLimits({
    required this.maxActivePets,
    required this.maxAttachmentsPerPet,
    required this.maxCustomCaresPerPet,
    required this.complianceDashboard,
    required this.pdfReport,
    required this.configurableEarlyReminders,
  });

  /// `null` = ilimitado.
  final int? maxActivePets;
  final int? maxAttachmentsPerPet;
  final int? maxCustomCaresPerPet;
  final bool complianceDashboard;
  final bool pdfReport;
  final bool configurableEarlyReminders;

  bool get unlimitedPets => maxActivePets == null;

  static const PlanLimits free = PlanLimits(
    maxActivePets: 1,
    maxAttachmentsPerPet: 2,
    maxCustomCaresPerPet: 3,
    complianceDashboard: false,
    pdfReport: false,
    configurableEarlyReminders: false,
  );

  static const PlanLimits pro = PlanLimits(
    maxActivePets: null,
    maxAttachmentsPerPet: null,
    maxCustomCaresPerPet: null,
    complianceDashboard: true,
    pdfReport: true,
    configurableEarlyReminders: true,
  );

  static PlanLimits of(PlanType plan) =>
      switch (plan) { PlanType.free => free, PlanType.pro => pro };
}

/// Entitlement persistido localmente (RD-12). En F1 la validación es local con
/// restauración de compra (RF-49); en F2 se valida en servidor.
class Entitlement {
  const Entitlement({
    required this.plan,
    this.purchaseSource,
    this.purchasedAt,
  });

  final PlanType plan;
  final String? purchaseSource;
  final DateTime? purchasedAt;

  PlanLimits get limits => PlanLimits.of(plan);
  bool get isPro => plan == PlanType.pro;

  static const Entitlement freeDefault = Entitlement(plan: PlanType.free);

  Entitlement copyWith({
    PlanType? plan,
    String? purchaseSource,
    DateTime? purchasedAt,
  }) {
    return Entitlement(
      plan: plan ?? this.plan,
      purchaseSource: purchaseSource ?? this.purchaseSource,
      purchasedAt: purchasedAt ?? this.purchasedAt,
    );
  }
}

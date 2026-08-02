import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/plan/domain/plan.dart';

void main() {
  group('PlanLimits', () {
    test('Free tiene cotas y funciones bloqueadas', () {
      const limits = PlanLimits.free;
      expect(limits.maxActivePets, 1);
      expect(limits.maxAttachmentsPerPet, 2);
      expect(limits.maxCustomCaresPerPet, 3);
      expect(limits.complianceDashboard, isFalse);
      expect(limits.pdfReport, isFalse);
      expect(limits.configurableEarlyReminders, isFalse);
      expect(limits.unlimitedPets, isFalse);
    });

    test('Pro es ilimitado y desbloquea todo', () {
      const limits = PlanLimits.pro;
      expect(limits.maxActivePets, isNull);
      expect(limits.maxAttachmentsPerPet, isNull);
      expect(limits.maxCustomCaresPerPet, isNull);
      expect(limits.complianceDashboard, isTrue);
      expect(limits.pdfReport, isTrue);
      expect(limits.configurableEarlyReminders, isTrue);
      expect(limits.unlimitedPets, isTrue);
    });

    test('of() mapea cada plan a sus límites', () {
      expect(PlanLimits.of(PlanType.free), same(PlanLimits.free));
      expect(PlanLimits.of(PlanType.pro), same(PlanLimits.pro));
    });
  });

  group('Entitlement', () {
    test('Free por defecto no es Pro y usa límites Free', () {
      expect(Entitlement.freeDefault.isPro, isFalse);
      expect(Entitlement.freeDefault.limits, same(PlanLimits.free));
    });

    test('Pro es Pro y usa límites Pro', () {
      const e = Entitlement(plan: PlanType.pro);
      expect(e.isPro, isTrue);
      expect(e.limits, same(PlanLimits.pro));
    });
  });
}

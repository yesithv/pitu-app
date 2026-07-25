import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../backup/application/backup_providers.dart';
import 'pet_report_service.dart';

final petReportServiceProvider = Provider<PetReportService>(
  (ref) => PetReportService(
    ref.read(databaseProvider),
    ref.read(clinicalRepositoryProvider),
    ref.read(careRepositoryProvider),
    ref.read(fileTransferProvider),
  ),
);

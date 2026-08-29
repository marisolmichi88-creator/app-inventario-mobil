import 'package:flutter/material.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/providers/database_usage_provider.dart';

/// Estado del respaldo: confirma que la nube está al día y cuándo fue el
/// último cambio guardado.
class SyncStatusCard extends StatelessWidget {
  final DatabaseUsage? usage;

  const SyncStatusCard({super.key, this.usage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verde = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card(isDark: isDark),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10B981).withValues(alpha: 0.22)
                  : const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_done_rounded, size: 44, color: verde),
          ),
          const SizedBox(height: 18),
          Text(
            'Datos seguros en la nube',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Wrap y no Row: en pantallas angostas el punto y el texto se
          // reacomodan en vez de desbordar la tarjeta.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: verde, shape: BoxShape.circle),
              ),
              Text(
                'Sincronizado en tiempo real',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: verde,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            usage == null
                ? 'Consultando el estado…'
                : 'Último cambio guardado ${usage!.ultimoCambioRelativo}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Espacio ocupado en la base y conteo de filas de las tablas principales.
class DatabaseUsageCard extends StatelessWidget {
  final DatabaseUsage? usage;
  final bool isLoading;
  final bool functionMissing;

  const DatabaseUsageCard({
    super.key,
    this.usage,
    this.isLoading = false,
    this.functionMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card(isDark: isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded,
                  size: 20,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Espacio de la base de datos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading && usage == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (functionMissing)
            _aviso(
              isDark,
              'Falta ejecutar supabase_uso_base_datos.sql en Supabase para '
              'poder mostrar el espacio usado.',
            )
          else if (usage == null)
            _aviso(isDark, 'No se pudo consultar el espacio. Desliza para reintentar.')
          else
            _detalle(context, isDark, usage!),
        ],
      ),
    );
  }

  Widget _aviso(bool isDark, String texto) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalle(BuildContext context, bool isDark, DatabaseUsage uso) {
    final color = uso.isCritical
        ? const Color(0xFFEF4444)
        : uso.isWarning
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // FittedBox encoge el texto grande antes que dejarlo desbordar.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      uso.sizeLabel,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'de ${uso.limitLabel}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${uso.usedPercent}%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: uso.usedFraction,
            minHeight: 8,
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        if (uso.isCritical)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 16, color: Color(0xFFB91C1C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quedan ${uso.espacioLibreLabel} libres. Hay que ampliar el '
                    'plan en Supabase → Settings → Billing.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.red.shade200 : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            uso.isWarning
                ? 'Ya se usó el 80% del espacio incluido. Quedan '
                    '${uso.espacioLibreLabel} libres; conviene estar pendiente.'
                : 'Espacio de sobra: quedan ${uso.espacioLibreLabel} libres. '
                    'El límite es de almacenamiento, no de cantidad de registros.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        const SizedBox(height: 18),
        Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            _conteo(context, isDark, Icons.inventory_2_outlined, 'Productos',
                uso.productos),
            _conteo(context, isDark, Icons.swap_horiz_rounded, 'Movimientos',
                uso.movimientos),
            _conteo(context, isDark, Icons.verified_user_outlined, 'Auditoría',
                uso.auditoria),
          ],
        ),
      ],
    );
  }

  Widget _conteo(
      BuildContext context, bool isDark, IconData icon, String label, int valor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(height: 6),
          Text(
            '$valor',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

const _institutionalBlue = Color(0xFF0D47A1);
const _ink = Color(0xFF263238);
const _muted = Color(0xFF607078);
const _line = Color(0xFFE0E5E8);
const _background = Color(0xFFF4F6F8);

class MyProgramSchedulesScreen extends StatelessWidget {
  const MyProgramSchedulesScreen({super.key});

  static const schedules = [
    _Schedule(
      day: '30',
      month: 'OCT',
      year: '2026',
      date: '30 de octubre de 2026',
      zone: 'Norte',
      vehicle: 'CamiÃ³n 01',
      plate: 'ABC-123',
      shift: 'MaÃ±ana',
      hours: '06:00 - 14:00',
      workDays: 'Lun, Mar, MiÃ©, Jue, Vie',
    ),
    _Schedule(
      day: '01',
      month: 'NOV',
      year: '2026',
      date: '01 de noviembre de 2026',
      zone: 'Centro',
      vehicle: 'CamiÃ³n 03',
      plate: 'DEF-456',
      shift: 'Tarde',
      hours: '14:00 - 22:00',
      workDays: 'Lun, Mar, MiÃ©, Jue, Vie',
    ),
    _Schedule(
      day: '03',
      month: 'NOV',
      year: '2026',
      date: '03 de noviembre de 2026',
      zone: 'Sur',
      vehicle: 'CamiÃ³n 05',
      plate: 'GHI-789',
      shift: 'Noche',
      hours: '22:00 - 06:00',
      workDays: 'Lun, Mar, MiÃ©, Jue, Vie',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _institutionalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mis Programaciones',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          tooltip: 'Volver al panel',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _DriverCard(),
          const SizedBox(height: 22),
          const Text(
            'Programaciones',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...schedules.map(
            (schedule) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScheduleCard(
                schedule: schedule,
                onTap: () => _showDetails(context, schedule),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, _Schedule schedule) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleDetails(schedule: schedule),
    );
  }
}

class _Schedule {
  const _Schedule({
    required this.day,
    required this.month,
    required this.year,
    required this.date,
    required this.zone,
    required this.vehicle,
    required this.plate,
    required this.shift,
    required this.hours,
    required this.workDays,
  });

  final String day;
  final String month;
  final String year;
  final String date;
  final String zone;
  final String vehicle;
  final String plate;
  final String shift;
  final String hours;
  final String workDays;
}

class _DriverCard extends StatelessWidget {
  const _DriverCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.person, color: _institutionalBlue, size: 32),
          SizedBox(width: 13),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Juan PÃ©rez',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text('DNI: 12345678', style: TextStyle(color: _muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.onTap});

  final _Schedule schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    color: _institutionalBlue,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(7),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        schedule.day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        schedule.month,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        schedule.year,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 11, 9, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.date,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _ScheduleInfo(
                          icon: Icons.location_on_outlined,
                          label: 'Zona',
                          value: schedule.zone,
                        ),
                        const SizedBox(height: 5),
                        _ScheduleInfo(
                          icon: Icons.local_shipping_outlined,
                          label: 'VehÃ­culo',
                          value: '${schedule.vehicle} Â· ${schedule.plate}',
                        ),
                        const SizedBox(height: 5),
                        _ScheduleInfo(
                          icon: Icons.access_time,
                          label: 'Turno',
                          value: '${schedule.shift} (${schedule.hours})',
                        ),
                        const SizedBox(height: 5),
                        _ScheduleInfo(
                          icon: Icons.calendar_today_outlined,
                          label: 'DÃ­as',
                          value: schedule.workDays,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right, color: _muted, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleInfo extends StatelessWidget {
  const _ScheduleInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _institutionalBlue, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: _ink, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleDetails extends StatelessWidget {
  const _ScheduleDetails({required this.schedule});

  final _Schedule schedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Detalle de programaciÃ³n',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(schedule.date, style: const TextStyle(color: _muted)),
              const SizedBox(height: 20),
              _DetailRow(Icons.location_on_outlined, 'Zona', schedule.zone),
              _DetailRow(
                Icons.local_shipping_outlined,
                'VehÃ­culo',
                schedule.vehicle,
              ),
              _DetailRow(
                Icons.confirmation_number_outlined,
                'Placa',
                schedule.plate,
              ),
              _DetailRow(Icons.wb_sunny_outlined, 'Turno', schedule.shift),
              _DetailRow(Icons.access_time, 'Horario', schedule.hours),
              _DetailRow(
                Icons.calendar_today_outlined,
                'DÃ­as de trabajo',
                schedule.workDays,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _institutionalBlue,
                    side: const BorderSide(color: _line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _institutionalBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}


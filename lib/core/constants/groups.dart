class IYFGroup {
  final String code;
  final String name;
  const IYFGroup(this.code, this.name);
  String get displayName => '$code — $name';
}

const kGroups = [
  IYFGroup('JGN', 'Jagannath'),
  IYFGroup('DYS', 'DYS'),
  IYFGroup('NCH', 'Nachiketa'),
  IYFGroup('SHD', 'Sahdev'),
  IYFGroup('NKL', 'Nakul'),
  IYFGroup('ARJ', 'Arjun'),
  IYFGroup('YDH', 'Yudhisthir'),
  IYFGroup('GRG', 'Gaurang Sabha'),
  IYFGroup('PBT', 'Prabhupad Bhakti Training'),
  IYFGroup('BHM', 'Bheem'),
  IYFGroup('BHS', 'Bhisma'),
  IYFGroup('RVR', 'Roop Vrinda'),
];

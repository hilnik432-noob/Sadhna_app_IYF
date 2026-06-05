class Facilitator {
  final String dikshitName;
  final String materialName;
  final bool hasDikshit;

  const Facilitator({
    required this.dikshitName,
    required this.materialName,
    this.hasDikshit = true,
  });

  /// Display label shown in dropdown
  String get displayName => hasDikshit
      ? '$dikshitName (${materialName})'
      : dikshitName;
}

const kFacilitators = [
  Facilitator(dikshitName: 'HG Harisa Pran Prabhuji',          materialName: 'Harisa Pran Prabhuji'),
  Facilitator(dikshitName: 'HG Sachi Priya Prabhu Ji',         materialName: 'Sachin Jangid'),
  Facilitator(dikshitName: 'HG Ashok Govind Prabhu Ji',        materialName: 'Ashok Prabhu Ji'),
  Facilitator(dikshitName: 'Keshav Prabhu Ji',                 materialName: 'Keshav Prabhu Ji',     hasDikshit: false),
  Facilitator(dikshitName: 'HG Digvijay Gourang Prabhuji',     materialName: 'Digvijay Gourang Prabhuji'),
  Facilitator(dikshitName: 'HG Dev Krishna Das',               materialName: 'Dev Krishna Teli'),
  Facilitator(dikshitName: 'HG Tribhang Kanai Prabhu Ji',      materialName: 'Tribhang Kanai Prabhu Ji'),
  Facilitator(dikshitName: 'HG Kaushal Pati Prabhu Ji',        materialName: 'Kaushal Pal'),
  Facilitator(dikshitName: 'HG Amal Gaur Prabhu Ji',           materialName: 'Aman Sharma'),
  Facilitator(dikshitName: 'HG Madhur Murli Prabhu Ji',        materialName: 'Madhur Murli Prabhu Ji'),
  Facilitator(dikshitName: 'HG Mohan Murari Prabhuji',         materialName: 'Mohan Murari Prabhuji'),
  Facilitator(dikshitName: 'Gopal Prabhu Ji',                  materialName: 'Gopal Prabhu Ji',      hasDikshit: false),
  Facilitator(dikshitName: 'HG Ganshyam Dev Prabhu Ji',        materialName: 'Ganshyam Dev Prabhu Ji'),
  Facilitator(dikshitName: 'HG Avinashi Govind Prabhuji',      materialName: 'Avinash Daroga Prabhu Ji'),
  Facilitator(dikshitName: 'HG Hitkar Vaman Prabhu Ji',        materialName: 'Hitarth Vyas'),
  Facilitator(dikshitName: 'Nitai Nimai Prabhu Ji',            materialName: 'Nikhil Kumawat',       hasDikshit: false),
  Facilitator(dikshitName: 'HG Maya Tita Hari Prabhu Ji',      materialName: 'Mayank Mewara'),
  Facilitator(dikshitName: 'HG Amrita Anand Prabhu Ji',        materialName: 'Amrita Anand Prabhu Ji'),
  Facilitator(dikshitName: 'HG Akshar Hari Prabhu Ji',         materialName: 'Ankit Kumar Singh'),
  Facilitator(dikshitName: 'HG Vishuddh Parth Prabhuji',       materialName: 'Vishal Sharma Prabhu Ji'),
  Facilitator(dikshitName: 'HG Bhav Hari Prabhu Ji',           materialName: 'Bhavya Soni'),
  Facilitator(dikshitName: 'HG Naveen Narad Prabhuji',         materialName: 'Naveen Narad Prabhuji'),
  Facilitator(dikshitName: 'HG Tusht Madan Mohan Prabhuji',    materialName: 'Tushar Soni Prabhu Ji'),
  Facilitator(dikshitName: 'HG Devash Baldev Prabhu Ji',       materialName: 'Devansh Motwani'),
  Facilitator(dikshitName: 'HG Prajwal Nitai Prabhuji',        materialName: 'Prajwal Avasthi Prabhu Ji'),
  Facilitator(dikshitName: 'HG Veer Bhadra Prabhu Ji',         materialName: 'Virendra Prabhu Ji'),
  Facilitator(dikshitName: 'HG Satya Raj Keshav Prabhu Ji',    materialName: 'Shubham Pareek'),
  Facilitator(dikshitName: 'HG Praneshwar Shyam Prabhuji',     materialName: 'Pronit Prabhu Ji'),
  Facilitator(dikshitName: 'HG Manigreev Prabhu Ji',           materialName: 'Manigreev Prabhu Ji'),
  Facilitator(dikshitName: 'HG Krishnakant Prabhu Ji',         materialName: 'Krish Sharma'),
  Facilitator(dikshitName: 'HG Akshay Hari Prabhu Ji',         materialName: 'Aakash Prabhu Ji'),
  Facilitator(dikshitName: 'HG Arjun Prabhu Ji',               materialName: 'Ajay Sharma'),
  Facilitator(dikshitName: 'HG Vipin Shyam Prabhu Ji',         materialName: 'Vipin Sharma Prabhu Ji'),
  Facilitator(dikshitName: 'HG Vikram Prabhu Ji',              materialName: 'Vikas Singh'),
  Facilitator(dikshitName: 'HG Vimal Arjun Prabhu Ji',         materialName: 'Vimal Arjun Prabhu Ji'),
];

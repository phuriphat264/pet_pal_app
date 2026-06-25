// Fetches/creates/updates pets via the backend, reshaping JSON into the
// Map<String, dynamic> shape pet_profile_page.dart already renders.
import '../utils/ui_mapping.dart';
import 'api_client.dart';

const String _defaultPetIconName = 'pets_rounded';
const String _defaultPetColorHex = '#5C3D2E';

List<Map<String, dynamic>> _healthCards(Map<String, dynamic> p) => [
      {'label': 'น้ำหนัก', 'value': p['weight'], 'icon': '⚖️'},
      {'label': 'ส่วนสูง', 'value': p['height'], 'icon': '📏'},
      {'label': 'อุณหภูมิ', 'value': p['temp'], 'icon': '🌡️'},
      {'label': 'ชีพจร', 'value': p['heartRate'], 'icon': '💓'},
    ];

Map<String, dynamic> petFromJson(Map<String, dynamic> json) {
  final ui = <String, dynamic>{
    'id': json['id'],
    'name': json['name'] as String,
    'breed': json['breed'] as String? ?? 'ไม่ระบุสายพันธุ์',
    'age': json['age'] as String? ?? 'ไม่ระบุอายุ',
    'weight': json['weight'] as String? ?? '-',
    'height': json['height'] as String? ?? '-',
    'temp': json['temp'] as String? ?? '-',
    'heartRate': json['heart_rate'] as String? ?? '-',
    'icon': iconFromName(json['icon_name'] as String?),
    'color': colorFromHex(json['color_hex'] as String?),
    'gender': json['gender'] as String? ?? 'ชาย',
    'dob': json['dob'] as String? ?? '-',
    'color_desc': json['color_desc'] as String? ?? '-',
    'vaccine': json['vaccine'] as String? ?? 'ยังไม่ระบุ',
    'nextVet': json['next_vet'] as String? ?? '-',
    'lastVet': json['last_vet'] as String? ?? '-',
    'chip': json['chip_id'] as String? ?? '-',
    'allergies': json['allergies'] as String? ?? 'ไม่มี',
    'food': json['food'] as String? ?? 'ไม่ระบุ',
    'feedingTimes': json['feeding_times'] as String? ?? '2 ครั้ง/วัน',
    'neutered': json['neutered'] as String? ?? 'ยังไม่ได้ทำหมัน',
    'traits': List<String>.from(json['traits'] as List? ?? const []),
    'medHistory': (json['medical_history'] as List? ?? const [])
        .map((h) => {'date': h['date'], 'event': h['event'], 'vet': h['vet'] ?? ''})
        .toList(),
    'activities': const [
      {'label': 'เดินวันนี้', 'value': '-'},
      {'label': 'แคลอรี่', 'value': '-'},
      {'label': 'นอนหลับ', 'value': '-'},
    ],
  };
  ui['health'] = _healthCards(ui);
  return ui;
}

Map<String, dynamic> _petCreatePayload({
  required String name,
  required String breed,
  required String age,
  required String weight,
  required String gender,
  required String neutered,
  required String food,
  required String allergies,
  required List<String> traits,
}) => {
      'name': name,
      'breed': breed,
      'age': age,
      'weight': weight,
      'gender': gender,
      'neutered': neutered,
      'food': food,
      'allergies': allergies,
      'traits': traits,
      'icon_name': _defaultPetIconName,
      'color_hex': _defaultPetColorHex,
      'feeding_times': '2 ครั้ง/วัน',
      'vaccine': 'ยังไม่ระบุ',
    };

class PetRepository {
  final ApiClient client;
  PetRepository(this.client);

  Future<List<Map<String, dynamic>>> fetchPets() async {
    final result = await client.get('/pets');
    return (result as List).map((p) => petFromJson(p as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createPet({
    required String name,
    required String breed,
    required String age,
    required String weight,
    required String gender,
    required String neutered,
    required String food,
    required String allergies,
    required List<String> traits,
  }) async {
    final payload = _petCreatePayload(
      name: name,
      breed: breed,
      age: age,
      weight: weight,
      gender: gender,
      neutered: neutered,
      food: food,
      allergies: allergies,
      traits: traits,
    );
    final result = await client.post('/pets', body: payload);
    return petFromJson(result as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updatePet(String id, Map<String, dynamic> fieldUpdates) async {
    final result = await client.patch('/pets/$id', body: fieldUpdates);
    return petFromJson(result as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> addMedicalHistory({
    required String petId,
    required String date,
    required String event,
    String? vet,
  }) async {
    final result = await client.post('/pets/$petId/medical-history', body: {
      'date': date,
      'event': event,
      if (vet != null && vet.isNotEmpty) 'vet': vet,
    });
    return petFromJson(result as Map<String, dynamic>);
  }
}

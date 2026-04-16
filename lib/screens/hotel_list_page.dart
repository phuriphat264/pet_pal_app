import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import 'hotel_detail_page.dart';

class HotelListPage extends StatefulWidget {
  const HotelListPage({super.key});

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _bgCard = Color(0xFFEDE2D5);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  String _selectedFilter = 'ทั้งหมด';
  final _filters = ['ทั้งหมด', 'ใกล้ที่สุด', 'ราคาถูก', 'คะแนนสูง'];

  final List<Map<String, dynamic>> _hotels = allHotels;

  List<Map<String, dynamic>> get _filteredHotels {
    var list = [..._hotels];
    if (_selectedFilter == 'ใกล้ที่สุด') {
      list.sort((a, b) => double.parse(a['distance'].replaceAll(' กม.', ''))
          .compareTo(double.parse(b['distance'].replaceAll(' กม.', ''))));
    } else if (_selectedFilter == 'ราคาถูก') {
      list.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
    } else if (_selectedFilter == 'คะแนนสูง') {
      list.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(child: _buildHotelList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: Color(0xFFE8D8C8), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: _brown, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('โรงแรมสัตว์เลี้ยง',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkBrown)),
              Text('4 แห่งใกล้คุณ', style: TextStyle(fontSize: 14, color: _mutedBrown)),
            ],
          ),
          const Spacer(),
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: Color(0xFFE8D8C8), shape: BoxShape.circle),
            child: const Icon(Icons.tune, color: _brown, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD9C5B2), width: 0.5),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'ค้นหาโรงแรม...',
            hintStyle: TextStyle(color: _mutedBrown, fontSize: 16),
            prefixIcon: Icon(Icons.search, color: _mutedBrown, size: 22),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final selected = _filters[i] == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _brown : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? _brown : const Color(0xFFD9C5B2), width: 0.5),
              ),
              child: Text(_filters[i],
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _mutedBrown,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHotelList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _filteredHotels.length,
      itemBuilder: (_, i) => _buildHotelCard(_filteredHotels[i]),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: hotel))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปโรงแรม
            Builder(
              builder: (context) {
                final List<String> images = (hotel['images'] as List?)?.cast<String>() ?? 
                    (hotel['image'] != null ? [hotel['image'] as String] : []);
                final String? coverImage = images.isNotEmpty ? images.first : null;

                return Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: (hotel['color'] as Color).withValues(alpha:0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (coverImage == null)
                        Center(child: Icon(hotel['icon'] as IconData, size: 80, color: _brown))
                      else
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.asset(
                            coverImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(hotel['icon'] as IconData, size: 80, color: _brown),
                            ),
                          ),
                        ),
                  if (!(hotel['available'] as bool))
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: const Center(
                        child: Text('เต็มแล้ว',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text('${hotel['rating']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(hotel['name'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                      ),
                      Text('฿${hotel['price']}/คืน',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _brown)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: _mutedBrown),
                      const SizedBox(width: 4),
                      Text(hotel['location'],
                          style: const TextStyle(fontSize: 14, color: _mutedBrown)),
                      const SizedBox(width: 6),
                      Text('· ${hotel['distance']}',
                          style: const TextStyle(fontSize: 14, color: _mutedBrown)),
                      const Spacer(),
                      Text('(${hotel['reviews']} รีวิว)',
                          style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: (hotel['tags'] as List<String>).map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(8)),
                      child: Text(t, style: const TextStyle(fontSize: 13, color: _brown)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
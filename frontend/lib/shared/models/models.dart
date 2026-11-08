double? _d(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
int? _i(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
String? _s(dynamic v) => v?.toString();

List<dynamic> extractList(dynamic d) {
  if (d is List) return d;
  if (d is Map && d['results'] is List) return d['results'] as List;
  return const [];
}

class Amenity {
  final int? id;
  final String name;
  const Amenity(this.id, this.name);
  factory Amenity.from(dynamic j) =>
      j is Map ? Amenity(_i(j['id']), _s(j['name']) ?? '') : Amenity(null, j.toString());
}

class Capacity {
  final int id;
  final String name, description;
  final int? capacity;
  final double? perHour, perDay, perMonth;
  final String? image;
  const Capacity({required this.id, required this.name, this.description = '', this.capacity, this.perHour, this.perDay, this.perMonth, this.image});
  factory Capacity.fromJson(Map j) => Capacity(
        id: _i(j['id']) ?? 0,
        name: _s(j['name']) ?? 'Seat',
        description: _s(j['description']) ?? '',
        capacity: _i(j['capacity']),
        perHour: _d(j['rate_per_hour']),
        perDay: _d(j['rate_per_day']),
        perMonth: _d(j['rate_per_month']),
        image: _s(j['image']),
      );
}

class Review {
  final int? id;
  final double rating;
  final String text, by;
  const Review({this.id, required this.rating, required this.text, required this.by});
  factory Review.fromJson(Map j) {
    final u = j['by_user'];
    String by = 'Member';
    if (u is Map) {
      by = _s(u['first_name']) ?? _s(u['email']) ?? by;
    } else if (u is String) {
      by = u;
    }
    return Review(id: _i(j['id']), rating: _d(j['rating']) ?? 0, text: _s(j['review']) ?? '', by: by);
  }
}

class Workspace {
  final int id;
  final String name, type, description, city, address;
  final String? logo, background, startTime, endTime;
  final List<String> images;
  final List<Amenity> amenities;
  final List<Capacity> capacities;
  final List<Review> reviews;
  final double? lat, lon, distance;
  final String ownerName, ownerEmail;
  final double? ratingApi;
  final int reviewCountApi;
  final String? insta, facebook;

  const Workspace({
    this.ratingApi,
    this.reviewCountApi = 0,
    this.ownerName = '',
    this.ownerEmail = '',
    this.insta,
    this.facebook,
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.city = '',
    this.address = '',
    this.logo,
    this.background,
    this.startTime,
    this.endTime,
    this.images = const [],
    this.amenities = const [],
    this.capacities = const [],
    this.reviews = const [],
    this.lat,
    this.lon,
    this.distance,
  });

  /// Cheapest published rate across capacities, preferring hourly > daily > monthly.
  (double, String)? get fromPrice {
    double? min(Iterable<double?> v) {
      final l = v.whereType<double>().toList();
      return l.isEmpty ? null : l.reduce((a, b) => a < b ? a : b);
    }
    final h = min(capacities.map((c) => c.perHour));
    if (h != null) return (h, 'hr');
    final d = min(capacities.map((c) => c.perDay));
    if (d != null) return (d, 'day');
    final m = min(capacities.map((c) => c.perMonth));
    if (m != null) return (m, 'month');
    return null;
  }

  List<String> get gallery {
    final out = <String>[];
    if (background != null) out.add(background!);
    out.addAll(images);
    if (out.isEmpty && logo != null) out.add(logo!);
    return out;
  }

  double? get avgRating {
    if (reviews.isNotEmpty) return reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length;
    return ratingApi;
  }

  int get reviewTotal => reviews.isNotEmpty ? reviews.length : reviewCountApi;

  String? get cover => background ?? (images.isNotEmpty ? images.first : logo);

  static (double?, double?) _loc(dynamic l) {
    if (l is Map) {
      final c = l['coordinates'];
      if (c is List && c.length >= 2) return (_d(c[1]), _d(c[0]));
      return (_d(l['latitude'] ?? l['lat']), _d(l['longitude'] ?? l['lon'] ?? l['lng']));
    }
    if (l is String) {
      final m = RegExp(r'POINT\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s*\)').firstMatch(l);
      if (m != null) return (double.tryParse(m.group(2)!), double.tryParse(m.group(1)!));
    }
    return (null, null);
  }

  static List<String> _imgs(Map j) {
    for (final k in ['uploaded_images', 'images', 'gallery', 'workspace_images']) {
      final v = j[k];
      if (v is List) {
        return v
            .map((e) => e is Map ? _s(e['image'] ?? e['url'] ?? e['photo']) : _s(e))
            .whereType<String>()
            .toList();
      }
    }
    return const [];
  }

  factory Workspace.fromJson(Map j) {
    final loc = _loc(j['location']);
    final a1 = _s(j['address_1']) ?? '', a2 = _s(j['address_2']) ?? '';
    return Workspace(
      id: _i(j['id']) ?? 0,
      name: _s(j['name']) ?? 'Workspace',
      type: _s(j['workspace_type']) ?? '',
      description: _s(j['description']) ?? '',
      city: _s(j['city']) ?? '',
      address: [a1, a2].where((e) => e.isNotEmpty).join(', '),
      logo: _s(j['logo']),
      background: _s(j['background']),
      startTime: _s(j['start_time']),
      endTime: _s(j['end_time']),
      images: _imgs(j),
      amenities: (j['amenities'] is List) ? (j['amenities'] as List).map(Amenity.from).toList() : const [],
      capacities: (j['capacity'] is List)
          ? (j['capacity'] as List).whereType<Map>().map(Capacity.fromJson).toList()
          : const [],
      reviews: (j['reviews'] is List) ? (j['reviews'] as List).whereType<Map>().map(Review.fromJson).toList() : const [],
      lat: loc.$1 ?? _d(j['latitude']),
      lon: loc.$2 ?? _d(j['longitude']),
      distance: _d(j['distance']),
      ratingApi: _d(j['rating']),
      reviewCountApi: _i(j['review_count']) ?? 0,
      ownerName: j['owner'] is Map ? '${(j['owner'] as Map)['first_name'] ?? ''} ${(j['owner'] as Map)['last_name'] ?? ''}'.trim() : '',
      ownerEmail: j['owner'] is Map ? _s((j['owner'] as Map)['email']) ?? '' : '',
      insta: (_s(j['insta']) ?? '').isEmpty ? null : _s(j['insta']),
      facebook: (_s(j['facebook']) ?? '').isEmpty ? null : _s(j['facebook']),
    );
  }
}

enum BookingBucket { upcoming, completed, pending, failed }

class Booking {
  final int id;
  final int? seatId;
  final String workspaceName, seatName, status, customer;
  final DateTime? start, end;
  final double? amount;
  final String? orderId;

  const Booking({
    required this.id,
    this.seatId,
    required this.workspaceName,
    required this.seatName,
    required this.status,
    required this.customer,
    this.start,
    this.end,
    this.amount,
    this.orderId,
  });

  /// Buckets are derived from the raw status string returned by the backend.
  BookingBucket bucketAt(DateTime now) {
    final s = status.toLowerCase();
    if (s.contains('fail') || s.contains('cancel')) return BookingBucket.failed;
    if (s.contains('pend') || s.contains('creat') || s.contains('unpaid') || s.contains('initi')) {
      return BookingBucket.pending;
    }
    if (end != null && end!.isBefore(now)) return BookingBucket.completed;
    return BookingBucket.upcoming;
  }

  bool get isConfirmed {
    final b = bucketAt(DateTime.now());
    return b == BookingBucket.upcoming || b == BookingBucket.completed;
  }

  factory Booking.fromJson(Map j) {
    final sd = j['seat_details'] is Map ? j['seat_details'] as Map : const {};
    final ws = sd['workspace'];
    String wsName = _s(sd['workspace_name']) ?? 'Workspace';
    if (ws is Map) {
      wsName = _s(ws['name']) ?? wsName;
    } else if (ws is String) {
      wsName = ws;
    }
    final bb = j['booked_by'];
    String who = '—';
    if (bb is Map) {
      final n = '${bb['first_name'] ?? ''} ${bb['last_name'] ?? ''}'.trim();
      who = n.isNotEmpty ? n : (_s(bb['email']) ?? who);
    } else if (bb != null) {
      who = bb.toString();
    }
    return Booking(
      id: _i(j['id']) ?? 0,
      seatId: _i(j['seat'] is Map ? j['seat']['id'] : j['seat']),
      workspaceName: wsName,
      seatName: _s(sd['name']) ?? 'Seat',
      status: _s(j['status']) ?? 'unknown',
      customer: who,
      start: DateTime.tryParse(_s(j['start_time']) ?? ''),
      end: DateTime.tryParse(_s(j['end_time']) ?? ''),
      amount: _d(j['amount']),
      orderId: _s(j['order_id']),
    );
  }
}

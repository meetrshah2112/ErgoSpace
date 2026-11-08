import 'dart:convert';
import 'package:dio/dio.dart';

class CapacityDraft {
  String name, description;
  int capacity;
  num? perHour, perDay, perMonth;
  String? imagePath;
  CapacityDraft({this.name = '', this.description = '', this.capacity = 1, this.perHour, this.perDay, this.perMonth});

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'capacity': capacity,
        if (perHour != null) 'rate_per_hour': perHour,
        if (perDay != null) 'rate_per_day': perDay,
        if (perMonth != null) 'rate_per_month': perMonth,
      };
}

class WorkspaceDraft {
  String name = '', type = 'Workspace', description = '';
  String address1 = '', address2 = '', pincode = '', city = '', state = '', country = 'India';
  String latitude = '', longitude = '';
  String startTime = '09:00:00', endTime = '18:00:00';
  List<String> amenities = [];
  List<CapacityDraft> capacities = [];
  String? logoPath, backgroundPath;
  List<String> galleryPaths = [];

  /// Multipart body for POST /workspace/new-workspace/
  /// amenities & capacity are JSON-encoded lists; uploaded_images repeats per file.
  Future<FormData> toFormData() async {
    final map = <String, dynamic>{
      'name': name.trim(),
      'workspace_type': type,
      'description': description.trim(),
      'address_1': address1.trim(),
      if (address2.trim().isNotEmpty) 'address_2': address2.trim(),
      'pincode': pincode.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'country': country.trim(),
      'start_time': startTime,
      'end_time': endTime,
      'latitude': latitude.trim(),
      'longitude': longitude.trim(),
      'amenities': jsonEncode([for (final a in amenities) {'name': a}]),
      'capacity': jsonEncode([for (final c in capacities) c.toJson()]),
    };
    if (logoPath != null) map['logo'] = await MultipartFile.fromFile(logoPath!);
    if (backgroundPath != null) map['background'] = await MultipartFile.fromFile(backgroundPath!);
    for (var i = 0; i < capacities.length; i++) {
      final img = capacities[i].imagePath;
      if (img != null) map['capacity_image_$i'] = await MultipartFile.fromFile(img);
    }
    if (galleryPaths.isNotEmpty) {
      map['uploaded_images'] = [for (final p in galleryPaths) await MultipartFile.fromFile(p)];
    }
    return FormData.fromMap(map);
  }
}

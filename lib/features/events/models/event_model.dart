import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String imageUrl;
  final String liveStreamUrl;
  final bool isLive;
  final bool isFree;
  final int registeredCount;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.location = '',
    this.imageUrl = '',
    this.liveStreamUrl = '',
    this.isLive = false,
    this.isFree = true,
    this.registeredCount = 0,
  });

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing => !isUpcoming && endDate.isAfter(DateTime.now());

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      liveStreamUrl: map['liveStreamUrl'] ?? '',
      isLive: map['isLive'] ?? false,
      isFree: map['isFree'] ?? true,
      registeredCount: map['registeredCount'] ?? 0,
    );
  }
}

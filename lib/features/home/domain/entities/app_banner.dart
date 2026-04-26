import 'package:equatable/equatable.dart';

class AppBanner extends Equatable {
  final int id;
  final String imageUrl;
  final String? link;
  final String? phone;
  final bool isActive;

  const AppBanner({
    required this.id,
    required this.imageUrl,
    this.link,
    this.phone,
    required this.isActive,
  });

  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasLink => link != null && link!.isNotEmpty;

  @override
  List<Object?> get props => [id, imageUrl, link, phone, isActive];
}

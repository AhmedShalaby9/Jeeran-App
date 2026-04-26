import 'package:equatable/equatable.dart';

class PropertyFilterParams extends Equatable {
  final int? page;
  final int? perPage;
  final String? type;
  final String? status;
  final int? projectId;
  final bool? isFeatured;
  final String? minPrice;
  final String? maxPrice;
  final int? bedrooms;
  final String? q;
  final String? sort;
  final String? order;

  const PropertyFilterParams({
    this.page = 1,
    this.perPage = 20,
    this.type,
    this.status,
    this.projectId,
    this.isFeatured,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.q,
    this.sort,
    this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      if (page != null) 'page': page.toString(),
      if (perPage != null) 'per_page': perPage.toString(),
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (projectId != null) 'project_id': projectId.toString(),
      if (isFeatured != null) 'is_featured': isFeatured.toString(),
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (bedrooms != null) 'bedrooms': bedrooms.toString(),
      if (q != null) 'q': q,
      if (sort != null) 'sort': sort,
      if (order != null) 'order': order,
    };
  }

  PropertyFilterParams copyWith({
    int? page,
    int? perPage,
    String? type,
    String? status,
    int? projectId,
    bool? isFeatured,
    String? minPrice,
    String? maxPrice,
    int? bedrooms,
    String? q,
    String? sort,
    String? order,
  }) {
    return PropertyFilterParams(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      type: type ?? this.type,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      isFeatured: isFeatured ?? this.isFeatured,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      bedrooms: bedrooms ?? this.bedrooms,
      q: q ?? this.q,
      sort: sort ?? this.sort,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
        page,
        perPage,
        type,
        status,
        projectId,
        isFeatured,
        minPrice,
        maxPrice,
        bedrooms,
        q,
        sort,
        order,
      ];
}

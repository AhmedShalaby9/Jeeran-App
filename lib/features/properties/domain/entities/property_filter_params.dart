import 'package:equatable/equatable.dart';

class PropertyFilterParams extends Equatable {
  final int? page;
  final int? perPage;
  final String? type;
  final String? status;
  final int? projectId;
  // Display-only — shown in filter chips, not sent to the API.
  final String? projectName;
  final bool? isFeatured;
  final String? minPrice;
  final String? maxPrice;
  final int? bedrooms;
  final String? q;
  final String? agentName;
  final String? sort;
  final String? order;
  final bool? isApproved;

  const PropertyFilterParams({
    this.page = 1,
    this.perPage = 20,
    this.type,
    this.status,
    this.projectId,
    this.projectName,
    this.isFeatured,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.q,
    this.agentName,
    this.sort,
    this.order,
    this.isApproved,
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
      if (agentName != null) 'agent_name': agentName,
      if (sort != null) 'sort': sort,
      if (order != null) 'order': order,
      if (isApproved != null) 'is_approved': isApproved.toString(),
    };
  }

  // Sentinel allows callers to pass null explicitly (unlike the ?? pattern).
  static const _nil = Object();

  PropertyFilterParams copyWith({
    Object? page = _nil,
    Object? perPage = _nil,
    Object? type = _nil,
    Object? status = _nil,
    Object? projectId = _nil,
    Object? projectName = _nil,
    Object? isFeatured = _nil,
    Object? minPrice = _nil,
    Object? maxPrice = _nil,
    Object? bedrooms = _nil,
    Object? q = _nil,
    Object? agentName = _nil,
    Object? sort = _nil,
    Object? order = _nil,
    Object? isApproved = _nil,
  }) {
    return PropertyFilterParams(
      page: page == _nil ? this.page : page as int?,
      perPage: perPage == _nil ? this.perPage : perPage as int?,
      type: type == _nil ? this.type : type as String?,
      status: status == _nil ? this.status : status as String?,
      projectId: projectId == _nil ? this.projectId : projectId as int?,
      projectName: projectName == _nil ? this.projectName : projectName as String?,
      isFeatured: isFeatured == _nil ? this.isFeatured : isFeatured as bool?,
      minPrice: minPrice == _nil ? this.minPrice : minPrice as String?,
      maxPrice: maxPrice == _nil ? this.maxPrice : maxPrice as String?,
      bedrooms: bedrooms == _nil ? this.bedrooms : bedrooms as int?,
      q: q == _nil ? this.q : q as String?,
      agentName: agentName == _nil ? this.agentName : agentName as String?,
      sort: sort == _nil ? this.sort : sort as String?,
      order: order == _nil ? this.order : order as String?,
      isApproved: isApproved == _nil ? this.isApproved : isApproved as bool?,
    );
  }

  @override
  List<Object?> get props => [
        page,
        perPage,
        type,
        status,
        projectId,
        projectName,
        isFeatured,
        minPrice,
        maxPrice,
        bedrooms,
        q,
        agentName,
        sort,
        order,
        isApproved,
      ];
}

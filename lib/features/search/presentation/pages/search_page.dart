import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/bloc/projects_bloc.dart';
import '../../../projects/presentation/bloc/projects_event.dart';
import '../../../projects/presentation/bloc/projects_state.dart';
import '../../../properties/domain/entities/property_filter_params.dart';
import '../../../properties/presentation/pages/properties_screen.dart';

class SearchPage extends StatefulWidget {
  final ValueNotifier<bool>? resetNotifier;
  const SearchPage({super.key, this.resetNotifier});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _queryController = TextEditingController();

  String? _selectedStatus;
  String? _selectedType;
  int? _selectedBedrooms;
  bool _isFeatured = false;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _selectedSort;
  String? _selectedOrder;
  int? _selectedProjectId;
  String? _selectedProjectName;

  static const _statuses = ['For Sale', 'For Rent', 'For Rent (Furnished)'];
  static const _types = [
    'Villa',
    'Apartment',
    'Land',
    'Studio',
    'Chalet',
    'Duplex',
  ];
  static const _bedroomOptions = [1, 2, 3, 4, 5];
  static const _sortOptions = ['Price', 'Date', 'Bedrooms'];
  static const _orderOptions = ['Ascending', 'Descending'];

  @override
  void initState() {
    super.initState();
    widget.resetNotifier?.addListener(_onResetSignal);
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetNotifier != widget.resetNotifier) {
      oldWidget.resetNotifier?.removeListener(_onResetSignal);
      widget.resetNotifier?.addListener(_onResetSignal);
    }
  }

  @override
  void dispose() {
    widget.resetNotifier?.removeListener(_onResetSignal);
    _queryController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onResetSignal() {
    _resetFilters();
  }

  void _resetFilters() {
    setState(() {
      _queryController.clear();
      _selectedStatus = null;
      _selectedType = null;
      _selectedBedrooms = null;
      _isFeatured = false;
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedSort = null;
      _selectedOrder = null;
      _selectedProjectId = null;
      _selectedProjectName = null;
    });
  }

  PropertyFilterParams _buildFilterParams() {
    return PropertyFilterParams(
      page: 1,
      perPage: 20,
      q: _queryController.text.isNotEmpty ? _queryController.text : null,
      status: _mapStatus(_selectedStatus),
      type: _mapType(_selectedType),
      projectId: _selectedProjectId,
      minPrice: _minPriceController.text.isNotEmpty
          ? _minPriceController.text
          : null,
      maxPrice: _maxPriceController.text.isNotEmpty
          ? _maxPriceController.text
          : null,
      bedrooms: _selectedBedrooms,
      isFeatured: _isFeatured,
      sort: _mapSort(_selectedSort),
      order: _mapOrder(_selectedOrder),
    );
  }

  String? _mapStatus(String? value) => switch (value) {
    'For Sale' => 'for_sale',
    'For Rent' => 'for_rent',
    'For Rent (Furnished)' => 'for_rent_furnished',
    _ => value,
  };

  String? _mapType(String? value) => switch (value) {
    'Villa' => 'فيلا',
    'Apartment' => 'شقة',
    'Land' => 'أرض',
    'Studio' => 'ستوديو',
    'Chalet' => 'شاليه',
    'Duplex' => 'دوبلكس',
    _ => value,
  };

  String? _mapSort(String? value) => switch (value) {
    'Price' => 'price',
    'Date' => 'date',
    'Bedrooms' => 'bedrooms',
    _ => value,
  };

  String? _mapOrder(String? value) => switch (value) {
    'Ascending' => 'ASC',
    'Descending' => 'DESC',
    _ => value,
  };

  void _onSearch() {
    final params = _buildFilterParams();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PropertiesScreen(params: params)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProjectsBloc>()..add(const FetchProjectsEvent()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SearchSection(
              children: [_QueryField(controller: _queryController)],
            ),
            _FilterSection(
              title: 'Status',
              child: _ChipGroup(
                options: _statuses,
                selected: _selectedStatus,
                onSelected: (v) => setState(
                  () => _selectedStatus = _selectedStatus == v ? null : v,
                ),
              ),
            ),
            _FilterSection(
              title: 'Property Type',
              child: _ChipGroup(
                options: _types,
                selected: _selectedType,
                onSelected: (v) => setState(
                  () => _selectedType = _selectedType == v ? null : v,
                ),
                wrap: true,
              ),
            ),
            _FilterSection(
              title: 'Project',
              child: _ProjectSelector(
                selectedId: _selectedProjectId,
                selectedName: _selectedProjectName,
                onSelected: (id, name) => setState(() {
                  _selectedProjectId = id;
                  _selectedProjectName = name;
                }),
                onCleared: () => setState(() {
                  _selectedProjectId = null;
                  _selectedProjectName = null;
                }),
              ),
            ),
            _FilterSection(
              title: 'Price Range (JOD)',
              child: _PriceRange(
                minController: _minPriceController,
                maxController: _maxPriceController,
              ),
            ),
            _FilterSection(
              title: 'Bedrooms',
              child: _BedroomSelector(
                options: _bedroomOptions,
                selected: _selectedBedrooms,
                onSelected: (v) => setState(
                  () => _selectedBedrooms = _selectedBedrooms == v ? null : v,
                ),
              ),
            ),
            _FilterSection(
              title: 'Featured Only',
              child: _FeaturedToggle(
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
              ),
            ),
            _FilterSection(
              title: 'Sort By',
              child: _ChipGroup(
                options: _sortOptions,
                selected: _selectedSort,
                onSelected: (v) => setState(
                  () => _selectedSort = _selectedSort == v ? null : v,
                ),
              ),
            ),
            _FilterSection(
              title: 'Order',
              child: _ChipGroup(
                options: _orderOptions,
                selected: _selectedOrder,
                onSelected: (v) => setState(
                  () => _selectedOrder = _selectedOrder == v ? null : v,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _onSearch,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(title: Text('Search Filters'));
  }
}

// ── Sections ─────────────────────────────────────────────────────────────────

class _SearchSection extends StatelessWidget {
  final List<Widget> children;
  const _SearchSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(children: children),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _QueryField extends StatelessWidget {
  final TextEditingController controller;
  const _QueryField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'City, area, or keyword…',
        hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.grey, size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool wrap;

  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.wrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = options.map((o) {
      final isSelected = o == selected;
      return GestureDetector(
        onTap: () => onSelected(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            o,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.onBackground,
            ),
          ),
        ),
      );
    }).toList();

    if (wrap) {
      return Wrap(spacing: 8, runSpacing: 8, children: chips);
    }
    final spaced = <Widget>[];
    for (int i = 0; i < chips.length; i++) {
      spaced.add(chips[i]);
      if (i < chips.length - 1) spaced.add(const SizedBox(width: 8));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: spaced),
    );
  }
}

class _PriceRange extends StatelessWidget {
  final TextEditingController minController;
  final TextEditingController maxController;
  const _PriceRange({required this.minController, required this.maxController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PriceField(controller: minController, hint: 'Min'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '—',
            style: TextStyle(color: AppColors.grey, fontSize: 18),
          ),
        ),
        Expanded(
          child: _PriceField(controller: maxController, hint: 'Max'),
        ),
      ],
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _PriceField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _BedroomSelector extends StatelessWidget {
  final List<int> options;
  final int? selected;
  final ValueChanged<int> onSelected;
  const _BedroomSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...options.map((n) {
          final isSelected = n == selected;
          final label = n == 5 ? '5+' : '$n';
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.grey.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ProjectSelector extends StatelessWidget {
  final int? selectedId;
  final String? selectedName;
  final void Function(int id, String name) onSelected;
  final VoidCallback onCleared;

  const _ProjectSelector({
    required this.selectedId,
    required this.selectedName,
    required this.onSelected,
    required this.onCleared,
  });

  void _openSheet(BuildContext context, List<Project> projects) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProjectPickerSheet(
        projects: projects,
        selectedId: selectedId,
        onSelected: (project) {
          onSelected(project.id, project.name);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        final projects = state is ProjectsLoaded ? state.projects : <Project>[];
        final isLoading = state is ProjectsLoading;

        return GestureDetector(
          onTap: projects.isNotEmpty
              ? () => _openSheet(context, projects)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: isLoading
                      ? Text(
                          'Loading projects…',
                          style: TextStyle(color: AppColors.grey, fontSize: 14),
                        )
                      : Text(
                          selectedName ?? 'Select a project',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedName != null
                                ? AppColors.onBackground
                                : AppColors.grey,
                          ),
                        ),
                ),
                if (selectedId != null)
                  GestureDetector(
                    onTap: onCleared,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.grey,
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.grey,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProjectPickerSheet extends StatelessWidget {
  final List<Project> projects;
  final int? selectedId;
  final ValueChanged<Project> onSelected;

  const _ProjectPickerSheet({
    required this.projects,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select a Project',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        const Divider(height: 20),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: projects.length,
            itemBuilder: (context, i) {
              final p = projects[i];
              final isSelected = p.id == selectedId;
              return GestureDetector(
                onTap: () => onSelected(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          size: 18,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onBackground,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FeaturedToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_rounded,
              color: value ? AppColors.primary : AppColors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Show only featured properties',
              style: TextStyle(
                fontSize: 14,
                color: value ? AppColors.onBackground : AppColors.grey,
              ),
            ),
          ],
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pass_rate/core/config/app_sizes.dart';
import 'package:pass_rate/core/design/app_colors.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';

// Model class for dropdown items
class DropdownItem<T> {
  final T value;
  final String label;
  final Widget? icon;
  final bool enabled;

  const DropdownItem({required this.value, required this.label, this.icon, this.enabled = true});
}

// GetX Controller for dropdown state management
class CustomDropdownController<T> extends GetxController {
  final Rx<T?> _selectedValue = Rx<T?>(null);
  final RxBool _isOpen = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxList<DropdownItem<T>> _filteredItems = <DropdownItem<T>>[].obs;
  List<DropdownItem<T>> _allItems = <DropdownItem<T>>[];

  T? get selectedValue => _selectedValue.value;

  bool get isOpen => _isOpen.value;

  String get searchQuery => _searchQuery.value;

  List<DropdownItem<T>> get filteredItems => _filteredItems;

  void setItems(List<DropdownItem<T>> items) {
    _allItems = items;
    _filteredItems.value = items;
  }

  void selectValue(T? value) {
    _selectedValue.value = value;
    _isOpen.value = false;
    _searchQuery.value = '';
    _filteredItems.value = _allItems;
  }

  void toggleDropdown() {
    _isOpen.value = !_isOpen.value;
    if (!_isOpen.value) {
      _searchQuery.value = '';
      _filteredItems.value = _allItems;
    }
  }

  void closeDropdown() {
    _isOpen.value = false;
    _searchQuery.value = '';
    _filteredItems.value = _allItems;
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      _filteredItems.value = _allItems;
    } else {
      _filteredItems.value =
          _allItems
              .where(
                (DropdownItem<T> item) => item.label.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    }
  }

  void setInitialValue(T? value) {
    _selectedValue.value = value;
  }
}

// Main Custom Dropdown Widget
class CustomDropdown<T> extends StatefulWidget {
  final List<DropdownItem<T>> items;
  final T? initialValue;
  final String? hint;
  final String? label;
  final Function(T?)? onChanged;
  final bool isRequired;
  final bool isSearchable;
  final bool isEnabled;
  final String? Function(T?)? validator;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final double borderRadius;
  final double borderWidth;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final Color? dropdownColor;
  final double? dropdownMaxHeight;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool showClearButton;
  final String? emptyMessage;
  final Duration animationDuration;
  final String? controllerTag;

  const CustomDropdown({
    super.key,
    required this.items,
    this.initialValue,
    this.hint = 'Select an option',
    this.label,
    this.onChanged,
    this.isRequired = false,
    this.isSearchable = false,
    this.isEnabled = true,
    this.validator,
    this.width,
    this.height = 56.0,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderRadius = 8.0,
    this.borderWidth = 1.0,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.dropdownColor,
    this.dropdownMaxHeight = 200.0,
    this.suffixIcon,
    this.prefixIcon,
    this.showClearButton = false,
    this.emptyMessage = 'No items found',
    this.animationDuration = const Duration(milliseconds: 300),
    this.controllerTag,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  late CustomDropdownController<T> controller;
  late GlobalKey dropdownKey;
  late TextEditingController searchController;
  late FocusNode focusNode;
  OverlayEntry? overlayEntry;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    dropdownKey = GlobalKey();
    searchController = TextEditingController();
    focusNode = FocusNode();

    // Initialize controller with tag if provided
    final String tag = widget.controllerTag ?? UniqueKey().toString();

    try {
      controller = Get.find<CustomDropdownController<T>>(tag: tag);
    } catch (e) {
      controller = Get.put(CustomDropdownController<T>(), tag: tag);
    }

    controller.setItems(widget.items);
    if (widget.initialValue != null) {
      controller.setInitialValue(widget.initialValue);
    }

    // Listen to focus changes
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _closeDropdown();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    focusNode.dispose();
    _closeDropdown();
    super.dispose();
  }

  void _validateInput() {
    if (widget.validator != null) {
      setState(() {
        errorMessage = widget.validator!(controller.selectedValue);
      });
    }
  }

  void _openDropdown() {
    if (!widget.isEnabled) return;

    controller.toggleDropdown();
    if (controller.isOpen) {
      _showOverlay();
    } else {
      _closeDropdown();
    }
  }

  void _closeDropdown() {
    controller.closeDropdown();
    overlayEntry?.remove();
    overlayEntry = null;
  }

  void _showOverlay() {
    final RenderBox renderBox = dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    overlayEntry = OverlayEntry(
      builder:
          (BuildContext context) => GestureDetector(
            onTap: _closeDropdown, // Close when tapped outside
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: <Widget>[
                // Full screen invisible container to capture taps
                Positioned.fill(child: Container(color: Colors.transparent)),
                // Actual dropdown content
                Positioned(
                  left: offset.dx,
                  top: offset.dy + size.height + 4,
                  width: size.width,
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from propagating to parent
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      color: widget.dropdownColor ?? Theme.of(context).cardColor,
                      child: Container(
                        constraints: BoxConstraints(maxHeight: widget.dropdownMaxHeight ?? 200.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (widget.isSearchable) _buildSearchField(),
                            Flexible(child: _buildDropdownList()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: controller.updateSearchQuery,
      ),
    );
  }

  Widget _buildDropdownList() {
    return Obx(() {
      if (controller.filteredItems.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.emptyMessage ?? 'No items found',
            style:
                widget.hintStyle ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: controller.filteredItems.length,
        itemBuilder: (BuildContext context, int index) {
          final DropdownItem<T> item = controller.filteredItems[index];
          final bool isSelected = controller.selectedValue == item.value;

          return InkWell(
            onTap:
                item.enabled
                    ? () {
                      controller.selectValue(item.value);
                      widget.onChanged?.call(item.value);
                      _validateInput();
                      _closeDropdown();
                    }
                    : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.white,
              ),
              child: Row(
                children: <Widget>[
                  if (item.icon != null) ...<Widget>[item.icon!, const SizedBox(width: 8)],
                  Expanded(
                    child: Text(
                      item.label,
                      style:
                          widget.textStyle?.copyWith(
                            color: item.enabled ? null : Colors.grey,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ) ??
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: item.enabled ? null : Colors.grey,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check, color: Theme.of(context).primaryColor, size: 20),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      margin: widget.margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            key: dropdownKey,
            onTap: _openDropdown,
            child: Focus(
              focusNode: focusNode,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Obx(() {
                      final DropdownItem<T>? selectedItem = widget.items.firstWhereOrNull(
                        (DropdownItem<T> item) => item.value == controller.selectedValue,
                      );

                      return TextFormField(
                        controller: TextEditingController(
                          text: selectedItem?.label ?? widget.hint ?? 'Select an option',
                        ),
                        style:
                            selectedItem != null
                                ? widget.textStyle ?? Theme.of(context).textTheme.headlineMedium
                                : widget.hintStyle ?? context.txtTheme.labelSmall,
                        readOnly: true,
                        onTap: _openDropdown,

                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          suffixIcon:
                              widget.suffixIcon ??
                              Obx(
                                () => AnimatedRotation(
                                  duration: widget.animationDuration,
                                  turns: controller.isOpen ? 0.5 : 0,
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),

                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: widget.label,
                          labelStyle: context.txtTheme.headlineMedium?.copyWith(fontSize: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                            borderSide: const BorderSide(color: AppColors.primaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                            borderSide: const BorderSide(color: AppColors.primaryColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                            borderSide: const BorderSide(color: AppColors.primaryColor),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                            borderSide: const BorderSide(color: AppColors.primaryColor),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          if (errorMessage != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              errorMessage!,
              style: TextStyle(color: widget.errorBorderColor ?? Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// ====================> Usage ===============>
// Usage Example
/*class CustomDropDownUsage extends StatelessWidget {
  final List<DropdownItem<String>> countries = <DropdownItem<String>>[
    const DropdownItem(value: 'us', label: 'United States', icon: Icon(Icons.flag)),
    const DropdownItem(value: 'uk', label: 'United Kingdom'),
    const DropdownItem(value: 'ca', label: 'Canada'),
    const DropdownItem(value: 'au', label: 'Australia'),
    const DropdownItem(value: 'de', label: 'Germany'),
    const DropdownItem(value: 'fr', label: 'France', enabled: false),
  ];

  final List<DropdownItem<int>> numbers = <DropdownItem<int>>[
    const DropdownItem(value: 1, label: 'One'),
    const DropdownItem(value: 2, label: 'Two'),
    const DropdownItem(value: 3, label: 'Three'),
  ];

    CustomDropDownUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          // Basic dropdown
          CustomDropdown<String>(
            items: countries,
            hint: 'Select a country',
            // dropdownColor: Colors.red,
            label: 'Country',
            isRequired: true,
            onChanged: (String? value) {
              print('Selected country: $value');
            },
            validator: (String? value) {
              if (value == null) return 'Please select a country';
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Searchable dropdown
          CustomDropdown<String>(
            items: countries,
            hint: 'Search and select',
            label: 'Searchable Country',
            isSearchable: true,
            showClearButton: true,
            dropdownMaxHeight: 150,
            onChanged: (String? value) {
              print('Selected searchable country: $value');
            },
          ),

          const SizedBox(height: 24),

          // Custom styled dropdown
          CustomDropdown<int>(
            items: numbers,
            hint: 'Pick a number',
            label: 'Numbers',
            backgroundColor: Colors.blue.shade50,
            borderColor: Colors.blue,
            focusedBorderColor: Colors.blue.shade700,
            borderRadius: 12,
            onChanged: (int? value) {
              print('Selected number: $value');
            },
          ),
        ],
      ),
    );
  }
}*/

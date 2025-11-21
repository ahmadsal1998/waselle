import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';

import '../../../../view_models/location_view_model.dart';
import '../../../../view_models/order_view_model.dart';
import '../../../../view_models/region_view_model.dart';
import '../../../../view_models/auth_view_model.dart';
import '../../../../screens/home/order_success_screen.dart';
import '../../../../services/saved_address_service.dart';
import '../../../../models/saved_address.dart';
import '../controllers/delivery_request_form_controller.dart';

class DeliveryRequestFormView extends StatefulWidget {
  final LocationViewModel locationProvider;
  final RegionViewModel regionProvider;
  final OrderViewModel orderProvider;

  const DeliveryRequestFormView({
    super.key,
    required this.locationProvider,
    required this.regionProvider,
    required this.orderProvider,
  });

  @override
  State<DeliveryRequestFormView> createState() =>
      _DeliveryRequestFormViewState();
}

class _DeliveryRequestFormViewState extends State<DeliveryRequestFormView> {
  List<_VehicleOption> _vehicleOptions(BuildContext context, DeliveryRequestFormController controller) {
    final l10n = AppLocalizations.of(context)!;
    final vehicleTypes = controller.vehicleTypes;
    
    if (vehicleTypes.isEmpty) {
      // Fallback to default if no vehicle types loaded
      return [
        _VehicleOption(
          id: 'bike',
          label: l10n.bike,
          icon: Icons.pedal_bike,
        ),
      ];
    }

    return vehicleTypes.map((vt) {
      final id = vt['id'] as String? ?? '';
      final label = _getVehicleLabel(id, l10n);
      final icon = _getVehicleIcon(id);
      
      return _VehicleOption(
        id: id,
        label: label,
        icon: icon,
        isEnabled: true, // All returned vehicle types are enabled
      );
    }).toList();
  }

  String _getVehicleLabel(String id, AppLocalizations l10n) {
    switch (id) {
      case 'bike':
        return l10n.bike;
      case 'car':
        return l10n.car;
      case 'cargo':
        return l10n.cargo;
      default:
        return id;
    }
  }

  IconData _getVehicleIcon(String id) {
    switch (id) {
      case 'bike':
        return Icons.pedal_bike;
      case 'car':
        return Icons.directions_car;
      case 'cargo':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  late final DeliveryRequestFormController _controller;
  late final VoidCallback _messageListener;

  @override
  void initState() {
    super.initState();
    _controller = context.read<DeliveryRequestFormController>();
    
    _messageListener = () {
      final message = _controller.messageNotifier.value;
      if (message == null || !mounted) return;

      final theme = Theme.of(context);
      Color? backgroundColor;
      Duration duration;
      
      switch (message.type) {
        case DeliveryRequestFormMessageType.success:
          backgroundColor = theme.colorScheme.primary;
          duration = const Duration(seconds: 3);
          break;
        case DeliveryRequestFormMessageType.error:
          backgroundColor = theme.colorScheme.error;
          // Longer duration for error messages, especially for Arabic text
          duration = const Duration(seconds: 6);
          break;
        case DeliveryRequestFormMessageType.info:
          backgroundColor = null;
          duration = const Duration(seconds: 4);
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
      _controller.clearMessage();
    };
    _controller.messageNotifier.addListener(_messageListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Set up localization callback for the controller
    // This must be in didChangeDependencies() because Localizations is an inherited widget
    // and isn't available until after initState() completes
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      _controller.setLocalizationCallback((key) {
        switch (key) {
          case 'noDriversAvailable':
            return l10n.noDriversAvailable;
          default:
            return null;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.messageNotifier.removeListener(_messageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<DeliveryRequestFormController>();
    final locationProvider = widget.locationProvider;
    final regionProvider = widget.regionProvider;
    final orderProvider = widget.orderProvider;
    final position = locationProvider.currentPosition;

    if (position == null) {
      return _buildInitialLoader(context, controller, locationProvider);
    }

    final cities = regionProvider.activeCities;
    final isCitiesLoading = regionProvider.isLoadingCities;
    final cityError = regionProvider.citiesError;
    final villages = controller.selectedCityId != null
        ? regionProvider.activeVillagesForCity(controller.selectedCityId!)
        : <dynamic>[];
    final isVillagesLoading = controller.selectedCityId != null &&
        regionProvider.isLoadingVillages(controller.selectedCityId!);
    final villagesError = controller.selectedCityId != null
        ? regionProvider.villagesError(controller.selectedCityId!)
        : null;

    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              context,
              controller,
              locationProvider,
              position,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              icon: Icons.local_shipping_outlined,
              title: l10n.deliveryDetails,
              subtitle: l10n.chooseHowToSend,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVehicleSelector(
                    context,
                    controller,
                    regionProvider,
                    locationProvider,
                    orderProvider,
                  ),
                  if (controller.isLoadingVehicleTypes)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  if (controller.vehicleTypesError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Using default vehicle types',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildDeliveryTypeSelector(
                    context,
                    controller,
                  ),
                  const SizedBox(height: 20),
                  _buildOrderCategoryField(
                    context: context,
                    controller: controller,
                    orderProvider: orderProvider,
                    regionProvider: regionProvider,
                    locationProvider: locationProvider,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.map_outlined,
              title: l10n.pickupLocation,
              subtitle: l10n.tellUsWhereToCollect,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSavedAddressSelector(
                    context,
                    controller,
                    regionProvider,
                    locationProvider,
                    orderProvider,
                  ),
                  // Show City and Village fields ONLY when using Current Location
                  // When saved address is selected, fields are hidden and values are auto-populated
                  if (controller.useCurrentLocation) ...[
                    const SizedBox(height: 20),
                    _buildRegionFields(
                      context: context,
                      controller: controller,
                      regionProvider: regionProvider,
                      orderProvider: orderProvider,
                      locationProvider: locationProvider,
                      cities: cities,
                      villages: villages,
                      isCitiesLoading: isCitiesLoading,
                      isVillagesLoading: isVillagesLoading,
                      cityError: cityError,
                      villagesError: villagesError,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.contact_mail_outlined,
              title: l10n.senderDetails,
              subtitle: l10n.whoShouldDriverContact,
              child: _buildSenderFields(
                context,
                controller,
                regionProvider,
                locationProvider,
                orderProvider,
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.sticky_note_2_outlined,
              title: l10n.deliveryNotes,
              subtitle: l10n.shareHelpfulTips,
              child: _buildNotesField(context, controller),
            ),
            const SizedBox(height: 20),
            _buildDeliveryPriceInfo(context, controller),
            const SizedBox(height: 28),
            _buildSubmitButton(
              context,
              controller,
              locationProvider,
              regionProvider,
              orderProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoader(
    BuildContext context,
    DeliveryRequestFormController controller,
    LocationViewModel locationProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLoading = locationProvider.isLoading;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.locatingYou,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.weUseCurrentLocation,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => controller.refreshLocation(locationProvider),
              icon: const Icon(Icons.refresh),
              label: Text(
                isLoading ? l10n.fetchingLocation : l10n.retryLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DeliveryRequestFormController controller,
    LocationViewModel locationProvider,
    dynamic position,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final displayAddress = locationProvider.currentAddress ??
        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.95),
            theme.colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pickupFromYourLocation,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: locationProvider.isLoading
                      ? null
                      : () => controller.refreshLocation(locationProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.my_location_outlined),
                  label: Text(
                    locationProvider.isLoading ? l10n.updating : l10n.refreshLocation,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: locationProvider.currentPosition == null
                    ? null
                    : () => _showSaveAddressDialog(
                          context,
                          locationProvider,
                          controller,
                        ),
                icon: const Icon(Icons.bookmark_add_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.all(14),
                ),
                tooltip: 'Save Current Address',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector(
    BuildContext context,
    DeliveryRequestFormController controller,
    RegionViewModel regionProvider,
    LocationViewModel locationProvider,
    OrderViewModel orderProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vehicleOptions = _vehicleOptions(context, controller);

    if (vehicleOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          for (int i = 0; i < vehicleOptions.length; i++) ...[
            _buildVehicleChip(
              context,
              vehicleOptions[i],
              controller,
              regionProvider,
              locationProvider,
              orderProvider,
            ),
            if (i < vehicleOptions.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleChip(
    BuildContext context,
    _VehicleOption option,
    DeliveryRequestFormController controller,
    RegionViewModel regionProvider,
    LocationViewModel locationProvider,
    OrderViewModel orderProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSelected = controller.selectedVehicle == option.id;
    final isEnabled = option.isEnabled;

    final chip = ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            option.icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(option.label),
          if (!isEnabled && option.badgeLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                option.badgeLabel!,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: isEnabled
          ? (value) {
              if (value) {
                controller.onVehicleSelected(
                  option.id,
                  regionProvider: regionProvider,
                  locationProvider: locationProvider,
                  orderProvider: orderProvider,
                );
              }
            }
          : null,
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.45),
      selectedColor: theme.colorScheme.primary.withOpacity(0.15),
      disabledColor: theme.disabledColor.withOpacity(0.1),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(
                isEnabled ? 0.85 : 0.55,
              ),
      ),
    );

    return isEnabled
        ? chip
        : Tooltip(
            message: option.badgeLabel ?? l10n.comingSoon,
            child: IgnorePointer(child: chip),
          );
  }

  Widget _buildStyledDropdown<T>({
    required BuildContext context,
    required T? value,
    required String label,
    String? hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
  }) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(theme.colorScheme.surface),
            elevation: WidgetStateProperty.all(12),
            shadowColor: WidgetStateProperty.all(
              Colors.black.withOpacity(0.1),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 8),
            ),
            minimumSize: WidgetStateProperty.all(const Size(200, 48)),
          ),
        ),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        hint: hint != null
            ? Text(
                hint,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: DefaultTextStyle(
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.15,
                ) ?? const TextStyle(),
                child: item.child ?? const SizedBox.shrink(),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: theme.colorScheme.surface,
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.expand_more_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        iconSize: 24,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          floatingLabelStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 2.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              width: 1.5,
            ),
          ),
        ),
        menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
        isExpanded: true,
        isDense: false,
        borderRadius: BorderRadius.circular(16),
        alignment: AlignmentDirectional.centerStart,
      ),
    );
  }

  Widget _buildDeliveryTypeSelector(
    BuildContext context,
    DeliveryRequestFormController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _DeliveryTypeChip(
            label: l10n.internalDelivery,
            isSelected: controller.selectedDeliveryType == 'internal',
            onTap: () => controller.onDeliveryTypeChanged('internal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DeliveryTypeChip(
            label: l10n.externalDelivery,
            isSelected: controller.selectedDeliveryType == 'external',
            onTap: () => controller.onDeliveryTypeChanged('external'),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCategoryField({
    required BuildContext context,
    required DeliveryRequestFormController controller,
    required OrderViewModel orderProvider,
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLoading = orderProvider.isLoadingOrderCategories;
    final categories = orderProvider.orderCategories;
    final error = orderProvider.orderCategoriesError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStyledDropdown<String>(
          context: context,
          value: controller.selectedOrderCategoryId,
          hint: l10n.selectOrderType,
          label: l10n.orderType,
          icon: Icons.category_outlined,
          items: categories
              .map(
                (category) => DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              )
              .toList(),
          onChanged: isLoading || categories.isEmpty
              ? null
              : (value) {
                  controller.onOrderCategoryChanged(
                    value,
                    regionProvider: regionProvider,
                    locationProvider: locationProvider,
                    orderProvider: orderProvider,
                  );
                },
          validator: (value) {
            if (isLoading) {
              return l10n.pleaseWaitForCategories;
            }
            if (categories.isEmpty) {
              return l10n.noOrderCategoriesAvailable;
            }
            if (value == null || value.isEmpty) {
              return l10n.pleaseSelectOrderType;
            }
            return null;
          },
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 3),
          )
        else if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      orderProvider.loadOrderCategories(forceRefresh: true),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          )
        else if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.noCategoriesTryLater,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSavedAddressSelector(
    BuildContext context,
    DeliveryRequestFormController controller,
    RegionViewModel regionProvider,
    LocationViewModel locationProvider,
    OrderViewModel orderProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Watch controller to rebuild when selection changes
    final useCurrentLocation = controller.useCurrentLocation;
    final selectedSavedAddressId = controller.selectedSavedAddressId;

    return FutureBuilder<List<SavedAddress>>(
      // Add key to force rebuild when selection changes
      key: ValueKey('saved_addresses_$selectedSavedAddressId'),
      future: SavedAddressService.getSavedAddresses(),
      builder: (context, snapshot) {
        final savedAddresses = snapshot.data ?? [];
        
        // Access controller properties here to ensure rebuild when they change
        // The parent widget watches the controller, so this will rebuild
        final currentUseCurrentLocation = controller.useCurrentLocation;
        final currentSelectedId = controller.selectedSavedAddressId;

        if (savedAddresses.isEmpty) {
          // Show current location option only
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Using Current Location',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationProvider.currentAddress ?? 'Getting location...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Show selector with saved addresses
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Pickup Location',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Current Location Option
            InkWell(
              onTap: () {
                controller.useCurrentLocationForPickup(
                  regionProvider: regionProvider,
                  locationProvider: locationProvider,
                  orderProvider: orderProvider,
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentUseCurrentLocation
                      ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: currentUseCurrentLocation
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withOpacity(0.5),
                    width: currentUseCurrentLocation ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location,
                      color: currentUseCurrentLocation
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Location',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: currentUseCurrentLocation
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            locationProvider.currentAddress ?? 'Getting location...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (currentUseCurrentLocation)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Saved Addresses List
            ...savedAddresses.map((address) {
              final isSelected = !currentUseCurrentLocation &&
                  currentSelectedId == address.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    controller.selectSavedAddress(
                      address.id,
                      regionProvider: regionProvider,
                      locationProvider: locationProvider,
                      orderProvider: orderProvider,
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getAddressIcon(address.label),
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.label,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.address ?? 
                                    '${address.latitude.toStringAsFixed(4)}, ${address.longitude.toStringAsFixed(4)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  IconData _getAddressIcon(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('home')) {
      return Icons.home;
    } else if (lowerLabel.contains('work')) {
      return Icons.work;
    } else if (lowerLabel.contains('office')) {
      return Icons.business;
    } else {
      return Icons.location_on;
    }
  }

  void _showSaveAddressDialog(
    BuildContext context,
    LocationViewModel locationProvider,
    DeliveryRequestFormController controller,
  ) {
    final theme = Theme.of(context);
    final labelController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Current Address'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: labelController,
            decoration: const InputDecoration(
              labelText: 'Label (e.g., Home, Work)',
              hintText: 'Enter a name for this address',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a label';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final position = locationProvider.currentPosition;
                if (position == null) {
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location not available'),
                      ),
                    );
                  }
                  return;
                }

                final address = SavedAddress(
                  id: SavedAddressService.generateId(),
                  label: labelController.text.trim(),
                  latitude: position.latitude,
                  longitude: position.longitude,
                  address: locationProvider.currentAddress,
                  cityId: controller.selectedCityId,
                  villageId: controller.selectedVillageId,
                  streetDetails: controller.senderAddressController.text.trim().isEmpty
                      ? null
                      : controller.senderAddressController.text.trim(),
                );

                final success = await SavedAddressService.saveAddress(address);
                Navigator.of(dialogContext).pop();

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Address "${address.label}" saved successfully'),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save address'),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionFields({
    required BuildContext context,
    required DeliveryRequestFormController controller,
    required RegionViewModel regionProvider,
    required OrderViewModel orderProvider,
    required LocationViewModel locationProvider,
    required List<dynamic> cities,
    required List<dynamic> villages,
    required bool isCitiesLoading,
    required bool isVillagesLoading,
    required String? cityError,
    required String? villagesError,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStyledDropdown<String>(
          context: context,
          value: controller.selectedCityId,
          label: l10n.city,
          icon: Icons.location_city_outlined,
          items: cities
              .map(
                (city) => DropdownMenuItem<String>(
                  value: city.id,
                  child: Text(
                    city.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              )
              .toList(),
          onChanged: (!isCitiesLoading && cities.isNotEmpty)
              ? (value) {
                  controller.onCityChanged(
                    value,
                    regionProvider: regionProvider,
                    locationProvider: locationProvider,
                    orderProvider: orderProvider,
                  );
                }
              : null,
          validator: (value) {
            // Validate if fields are visible (either using current location or saved address with missing city/village)
            final fieldsVisible = controller.useCurrentLocation || 
                (controller.selectedSavedAddressId != null && 
                 (controller.selectedCityId == null || 
                  controller.selectedCityId!.isEmpty ||
                  controller.selectedVillageId == null ||
                  controller.selectedVillageId!.isEmpty));
            
            if (!fieldsVisible) {
              return null; // Fields hidden, no validation needed
            }
            
            if (cities.isEmpty) {
              return l10n.noActiveCitiesAvailable;
            }
            if (value == null || value.isEmpty) {
              return l10n.pleaseSelectCity;
            }
            return null;
          },
        ),
        if (isCitiesLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (cityError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              cityError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        const SizedBox(height: 16),
        _buildStyledDropdown<String>(
          context: context,
          value: controller.selectedVillageId,
          label: isVillagesLoading ? l10n.loadingVillages : l10n.village,
          icon: Icons.home_work_outlined,
          items: villages
              .map(
                (village) => DropdownMenuItem<String>(
                  value: village.id,
                  child: Text(
                    village.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              )
              .toList(),
          onChanged: (!isVillagesLoading && villages.isNotEmpty)
              ? (value) {
                  controller.onVillageChanged(
                    value,
                    regionProvider: regionProvider,
                    locationProvider: locationProvider,
                    orderProvider: orderProvider,
                  );
                }
              : null,
          validator: (value) {
            // Validate if fields are visible (either using current location or saved address with missing city/village)
            final fieldsVisible = controller.useCurrentLocation || 
                (controller.selectedSavedAddressId != null && 
                 (controller.selectedCityId == null || 
                  controller.selectedCityId!.isEmpty ||
                  controller.selectedVillageId == null ||
                  controller.selectedVillageId!.isEmpty));
            
            if (!fieldsVisible) {
              return null; // Fields hidden, no validation needed
            }
            
            if (controller.selectedCityId == null) {
              return l10n.selectCityFirst;
            }
            if (villages.isEmpty) {
              return l10n.noActiveVillagesForCity;
            }
            if (value == null || value.isEmpty) {
              return l10n.pleaseSelectVillage;
            }
            return null;
          },
        ),
        if (isVillagesLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (villagesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              villagesError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildSenderFields(
    BuildContext context,
    DeliveryRequestFormController controller,
    RegionViewModel regionProvider,
    LocationViewModel locationProvider,
    OrderViewModel orderProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller.senderNameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.senderName,
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.pleaseEnterSenderName;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.senderAddressController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.streetAddressDetails,
            hintText: l10n.streetBuildingFloorApartment,
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onChanged: (_) => controller.onSenderAddressChanged(
            regionProvider: regionProvider,
            locationProvider: locationProvider,
            orderProvider: orderProvider,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.pleaseEnterSenderAddress;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code selector
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String>(
                value: controller.selectedCountryCode,
                decoration: InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: '+970',
                    child: Text('+970'),
                  ),
                  DropdownMenuItem<String>(
                    value: '+972',
                    child: Text('+972'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.onCountryCodeChanged(value);
                  }
                },
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                isExpanded: true,
              ),
            ),
            const SizedBox(width: 12),
            // Phone number field
            Expanded(
              child: TextFormField(
                controller: controller.phoneNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterPhoneNumber;
                  }
                  final trimmed = value.trim();
                  if (trimmed.length < 9 || trimmed.length > 10) {
                    return l10n.pleaseEnterValidPhoneNumber;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField(
    BuildContext context,
    DeliveryRequestFormController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller.notesController,
      minLines: 3,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: l10n.deliveryNotes,
        hintText: l10n.provideDirections,
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.edit_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.pleaseEnterDeliveryNotes;
        }
        return null;
      },
    );
  }

  Widget _buildDeliveryPriceInfo(
    BuildContext context,
    DeliveryRequestFormController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Get the base price from the selected vehicle type
    double? basePrice;
    final selectedVehicleId = controller.selectedVehicle;
    final vehicleType = controller.vehicleTypes.firstWhere(
      (vt) => vt['id'] == selectedVehicleId,
      orElse: () => <String, dynamic>{},
    );
    
    if (vehicleType.isNotEmpty && vehicleType['basePrice'] != null) {
      basePrice = (vehicleType['basePrice'] as num).toDouble();
    }

    // Fallback to default prices if not found
    if (basePrice == null) {
      switch (selectedVehicleId) {
        case 'bike':
          basePrice = 5.0;
          break;
        case 'car':
          basePrice = 10.0;
          break;
        case 'cargo':
          basePrice = 15.0;
          break;
        default:
          basePrice = 5.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${l10n.deliveryStartsFrom} ${l10n.nis(basePrice.toStringAsFixed(2))}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOTPDialog(
    BuildContext context,
    DeliveryRequestFormController controller,
    LocationViewModel locationProvider,
    RegionViewModel regionProvider,
    OrderViewModel orderProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Verify Phone Number')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the 6-digit verification code sent to your WhatsApp:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  controller.resetOTPState();
                  await controller.sendOTP(
                    locationProvider: locationProvider,
                    regionProvider: regionProvider,
                    orderProvider: orderProvider,
                  );
                  if (controller.otpSent && context.mounted) {
                    _showOTPDialog(context, controller, locationProvider, regionProvider, orderProvider);
                  }
                },
                child: const Text('Resend Code'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.resetOTPState();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.isVerifyingOTP
                ? null
                : () async {
                    if (controller.otpController.text.length != 6) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please enter 6-digit code')),
                      );
                      return;
                    }

                    // Verify OTP and create order
                    final authProvider = Provider.of<AuthViewModel>(context, listen: false);
                    final result = await controller.verifyOTPAndCreateOrder(
                      locationProvider: locationProvider,
                      regionProvider: regionProvider,
                      orderProvider: orderProvider,
                      authProvider: authProvider,
                      getLocalizedMessage: (key) {
                        switch (key) {
                          case 'pleaseSelectDeliveryVehicle':
                            return l10n.pleaseSelectDeliveryVehicle;
                          case 'pleaseSelectYourCity':
                            return l10n.pleaseSelectYourCity;
                          case 'pleaseSelectYourVillage':
                            return l10n.pleaseSelectYourVillage;
                          case 'pleaseEnterValidPhoneNumber':
                            return l10n.pleaseEnterValidPhoneNumber;
                          case 'waitForEstimatedCost':
                            return l10n.waitForEstimatedCost;
                          case 'pleaseSelectOrderCategory':
                            return l10n.pleaseSelectOrderCategory;
                          case 'pleaseSelectDeliveryType':
                            return l10n.pleaseSelectDeliveryType;
                          case 'orderCategoryNoLongerAvailable':
                            return l10n.orderCategoryNoLongerAvailable;
                          case 'waitingForLocation':
                            return l10n.waitingForLocation;
                          case 'orderCreatedSuccessfully':
                            return l10n.orderCreatedSuccessfully;
                          case 'failedToCreateOrder':
                            return l10n.failedToCreateOrder;
                          default:
                            return '';
                        }
                      },
                    );

                    if (!dialogContext.mounted) return;

                    if (result.message != null) {
                      if (result.success) {
                        Navigator.of(dialogContext).pop();
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close form screen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OrderSuccessScreen(),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(result.message!),
                            backgroundColor: theme.colorScheme.error,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
            child: controller.isVerifyingOTP
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify & Submit Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    DeliveryRequestFormController controller,
    LocationViewModel locationProvider,
    RegionViewModel regionProvider,
    OrderViewModel orderProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: controller.isVerifyingOTP || controller.isSendingOTP || controller.isSubmitting
          ? null
          : () async {
              FocusScope.of(context).unfocus();
              
              // Check if authenticated - if yes, create order directly; if no, send OTP
              final authProvider = Provider.of<AuthViewModel>(context, listen: false);
              final result = await controller.validateFormAndSubmitOrder(
                locationProvider: locationProvider,
                regionProvider: regionProvider,
                orderProvider: orderProvider,
                authProvider: authProvider,
                getLocalizedMessage: (key) {
                  switch (key) {
                    case 'pleaseSelectDeliveryVehicle':
                      return l10n.pleaseSelectDeliveryVehicle;
                    case 'pleaseSelectYourCity':
                      return l10n.pleaseSelectYourCity;
                    case 'pleaseSelectYourVillage':
                      return l10n.pleaseSelectYourVillage;
                    case 'pleaseEnterValidPhoneNumber':
                      return l10n.pleaseEnterValidPhoneNumber;
                    case 'waitForEstimatedCost':
                      return l10n.waitForEstimatedCost;
                    case 'pleaseSelectOrderCategory':
                      return l10n.pleaseSelectOrderCategory;
                    case 'pleaseSelectDeliveryType':
                      return l10n.pleaseSelectDeliveryType;
                    case 'orderCategoryNoLongerAvailable':
                      return l10n.orderCategoryNoLongerAvailable;
                    case 'waitingForLocation':
                      return l10n.waitingForLocation;
                    default:
                      return '';
                  }
                },
              );

              if (!mounted) return;

              if (result.success) {
                if (authProvider.isAuthenticated) {
                  // User authenticated - order created directly, show success
                  Navigator.of(context).pop(); // Close form screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OrderSuccessScreen(),
                    ),
                  );
                } else if (controller.otpSent) {
                  // Show OTP dialog immediately after OTP is sent
                  _showOTPDialog(context, controller, locationProvider, regionProvider, orderProvider);
                }
              } else if (result.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message!),
                    backgroundColor: result.success 
                        ? Colors.green 
                        : Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: controller.isVerifyingOTP || controller.isSendingOTP || controller.isSubmitting
            ? Row(
                key: const ValueKey('processing'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    controller.isSendingOTP 
                        ? 'Sending Code...' 
                        : controller.isSubmitting
                            ? l10n.submitting
                            : l10n.submitting
                  ),
                ],
              )
            : Row(
                key: const ValueKey('submit'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.isSendingOTP)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.send_outlined),
                  const SizedBox(width: 10),
                  Text(controller.isSendingOTP ? 'Sending Code...' : l10n.submitRequest),
                ],
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _VehicleOption {
  final String id;
  final String label;
  final IconData icon;
  final bool isEnabled;
  final String? badgeLabel;

  const _VehicleOption({
    required this.id,
    required this.label,
    required this.icon,
    this.isEnabled = true,
    this.badgeLabel,
  });
}

class _DeliveryTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (value) {
        if (value) onTap();
      },
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.45),
      selectedColor: theme.colorScheme.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.85),
      ),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant.withOpacity(0.5),
        width: isSelected ? 2 : 1,
      ),
    );
  }
}

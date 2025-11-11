import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../providers/location_provider.dart';
import '../../../../providers/order_provider.dart';
import '../../../../providers/region_provider.dart';
import '../controllers/delivery_request_form_controller.dart';

class DeliveryRequestFormView extends StatefulWidget {
  final LocationProvider locationProvider;
  final RegionProvider regionProvider;
  final OrderProvider orderProvider;

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
  static const List<_VehicleOption> _vehicleOptions = [
    _VehicleOption(
      id: 'bike',
      label: 'Bike',
      icon: Icons.pedal_bike,
    ),
    _VehicleOption(
      id: 'car',
      label: 'Car',
      icon: Icons.directions_car,
      isEnabled: false,
      badgeLabel: 'Soon',
    ),
  ];

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
      switch (message.type) {
        case DeliveryRequestFormMessageType.success:
          backgroundColor = theme.colorScheme.primary;
          break;
        case DeliveryRequestFormMessageType.error:
          backgroundColor = theme.colorScheme.error;
          break;
        case DeliveryRequestFormMessageType.info:
          backgroundColor = null;
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.message),
          backgroundColor: backgroundColor,
        ),
      );
      _controller.clearMessage();
    };
    _controller.messageNotifier.addListener(_messageListener);
  }

  @override
  void dispose() {
    _controller.messageNotifier.removeListener(_messageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              title: 'Delivery Details',
              subtitle: 'Choose how you would like to send your package.',
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
              title: 'Pickup Location',
              subtitle: 'Tell us where to collect your package.',
              child: _buildRegionFields(
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
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.contact_mail_outlined,
              title: 'Sender Details',
              subtitle: 'Who should the driver contact on arrival?',
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
              title: 'Delivery Notes',
              subtitle: 'Share any helpful tips for the driver.',
              child: _buildNotesField(controller),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.attach_money,
              title: 'Estimated Cost',
              subtitle: 'We update this as you complete the form.',
              child: _buildEstimateSection(context, controller),
            ),
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
    LocationProvider locationProvider,
  ) {
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
              'Locating you...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'We use your current location to pre-fill pickup details.',
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
                isLoading ? 'Fetching location...' : 'Retry location',
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
    LocationProvider locationProvider,
    dynamic position,
  ) {
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
                      'Pickup from your location',
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
          ElevatedButton.icon(
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
              locationProvider.isLoading ? 'Updating...' : 'Refresh location',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector(
    BuildContext context,
    DeliveryRequestFormController controller,
    RegionProvider regionProvider,
    LocationProvider locationProvider,
    OrderProvider orderProvider,
  ) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _vehicleOptions.map((option) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          labelPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          backgroundColor:
              theme.colorScheme.surfaceVariant.withOpacity(0.45),
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
                message: option.badgeLabel ?? 'Coming soon',
                child: IgnorePointer(child: chip),
              );
      }).toList(),
    );
  }

  Widget _buildOrderCategoryField({
    required BuildContext context,
    required DeliveryRequestFormController controller,
    required OrderProvider orderProvider,
    required RegionProvider regionProvider,
    required LocationProvider locationProvider,
  }) {
    final isLoading = orderProvider.isLoadingOrderCategories;
    final categories = orderProvider.orderCategories;
    final error = orderProvider.orderCategoriesError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: controller.selectedOrderCategoryId,
          hint: const Text('Select the order type'),
          items: categories
              .map(
                (category) => DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
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
          decoration: InputDecoration(
            labelText: 'Order Type',
            prefixIcon: const Icon(Icons.category_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            if (isLoading) {
              return 'Please wait for categories to load';
            }
            if (categories.isEmpty) {
              return 'No order categories available at the moment';
            }
            if (value == null || value.isEmpty) {
              return 'Please select the order type';
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
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      orderProvider.loadOrderCategories(forceRefresh: true),
                  child: const Text('Retry'),
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
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No order categories available. Please try again later.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRegionFields({
    required BuildContext context,
    required DeliveryRequestFormController controller,
    required RegionProvider regionProvider,
    required OrderProvider orderProvider,
    required LocationProvider locationProvider,
    required List<dynamic> cities,
    required List<dynamic> villages,
    required bool isCitiesLoading,
    required bool isVillagesLoading,
    required String? cityError,
    required String? villagesError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: controller.selectedCityId,
          items: cities
              .map(
                (city) => DropdownMenuItem<String>(
                  value: city.id,
                  child: Text(city.name),
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
          decoration: InputDecoration(
            labelText: 'City',
            prefixIcon: const Icon(Icons.location_city_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            if (cities.isEmpty) {
              return 'No active cities available at the moment';
            }
            if (value == null || value.isEmpty) {
              return 'Please select a city';
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
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: controller.selectedVillageId,
          items: villages
              .map(
                (village) => DropdownMenuItem<String>(
                  value: village.id,
                  child: Text(village.name),
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
          decoration: InputDecoration(
            labelText: isVillagesLoading ? 'Loading villages...' : 'Village',
            prefixIcon: const Icon(Icons.home_work_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            if (controller.selectedCityId == null) {
              return 'Select a city first';
            }
            if (villages.isEmpty) {
              return 'No active villages available for this city';
            }
            if (value == null || value.isEmpty) {
              return 'Please select a village';
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
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSenderFields(
    BuildContext context,
    DeliveryRequestFormController controller,
    RegionProvider regionProvider,
    LocationProvider locationProvider,
    OrderProvider orderProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller.senderNameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Sender Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the sender name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.senderAddressController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Street Address / Details',
            hintText: 'Street, building, floor, apartment...',
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
              return 'Please enter the sender address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.phoneNumberController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a phone number';
            }
            final trimmed = value.trim();
            if (trimmed.length != 10) {
              return 'Phone number must contain exactly 10 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesField(DeliveryRequestFormController controller) {
    return TextFormField(
      controller: controller.notesController,
      minLines: 3,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: 'Delivery Notes',
        hintText: 'Provide directions, building access codes, or other details.',
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.edit_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter delivery notes';
        }
        return null;
      },
    );
  }

  Widget _buildEstimateSection(
    BuildContext context,
    DeliveryRequestFormController controller,
  ) {
    final theme = Theme.of(context);
    final hasEstimate = controller.estimatedPrice != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Live cost preview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (controller.isEstimating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: hasEstimate
              ? Text(
                  '${controller.estimatedPrice!.toStringAsFixed(2)} NIS',
                  key: const ValueKey('estimate-value'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Text(
                  'Select a vehicle and enter your pickup address to see the estimate.',
                  key: const ValueKey('estimate-placeholder'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          'The displayed cost is an estimate and may vary based on actual distance.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    DeliveryRequestFormController controller,
    LocationProvider locationProvider,
    RegionProvider regionProvider,
    OrderProvider orderProvider,
  ) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: controller.isSubmitting
          ? null
          : () async {
              FocusScope.of(context).unfocus();
              final result = await controller.submit(
                locationProvider: locationProvider,
                regionProvider: regionProvider,
                orderProvider: orderProvider,
              );

              if (!mounted) return;

              if (result.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message!)),
                );
              }

              if (result.success) {
                Navigator.of(context).pop();
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
        child: controller.isSubmitting
            ? Row(
                key: const ValueKey('submitting'),
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting...'),
                ],
              )
            : Row(
                key: const ValueKey('submit'),
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 10),
                  Text('Submit Request'),
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
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.65),
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


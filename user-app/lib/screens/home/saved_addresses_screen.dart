import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';
import '../../models/saved_address.dart';
import '../../services/saved_address_service.dart';
import '../../view_models/location_view_model.dart';
import '../../view_models/region_view_model.dart';
import '../../view_models/locale_view_model.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<SavedAddress> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addresses = await SavedAddressService.getSavedAddresses();
    setState(() {
      _addresses = addresses;
      _isLoading = false;
    });
  }

  Future<void> _deleteAddress(SavedAddress address) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAddress),
        content: Text(l10n.confirmDeleteAddress(address.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SavedAddressService.deleteAddress(address.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addressDeletedSuccessfully)),
        );
        _loadAddresses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToDeleteAddress)),
        );
      }
    }
  }

  Future<void> _editAddress(SavedAddress address) async {
    final result = await Navigator.of(context).push<SavedAddress>(
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(address: address),
      ),
    );

    if (result != null) {
      _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedAddresses),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push<SavedAddress>(
                MaterialPageRoute(
                  builder: (context) => const AddEditAddressScreen(),
                ),
              );

              if (result != null) {
                _loadAddresses();
              }
            },
            tooltip: l10n.addAddress,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState(context, l10n, theme)
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final address = _addresses[index];
                      return _buildAddressCard(context, address, theme, l10n);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSavedAddresses,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addAddressesToQuicklySelect,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<SavedAddress>(
                  MaterialPageRoute(
                    builder: (context) => const AddEditAddressScreen(),
                  ),
                );

                if (result != null) {
                  _loadAddresses();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addAddress),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    SavedAddress address,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getAddressIcon(address.label),
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        title: Text(
          address.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (address.address != null)
              Text(
                address.address!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                '${address.latitude.toStringAsFixed(4)}, ${address.longitude.toStringAsFixed(4)}',
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editAddress(address),
              tooltip: l10n.edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteAddress(address),
              tooltip: l10n.delete,
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
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
}

class AddEditAddressScreen extends StatefulWidget {
  final SavedAddress? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetDetailsController = TextEditingController();
  String? _selectedCityId;
  String? _selectedVillageId;
  bool _isSaving = false;
  bool _useCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _labelController.text = widget.address!.label;
      _streetDetailsController.text = widget.address!.streetDetails ?? '';
      _selectedCityId = widget.address!.cityId;
      _selectedVillageId = widget.address!.villageId;
      _useCurrentLocation = false;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetDetailsController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      final locationProvider = context.read<LocationViewModel>();
      final regionProvider = context.read<RegionViewModel>();

      double latitude;
      double longitude;
      String? addressString;

      if (_useCurrentLocation) {
        final position = locationProvider.currentPosition;
        if (position == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.pleaseEnableLocationServices),
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
        latitude = position.latitude;
        longitude = position.longitude;
        addressString = locationProvider.currentAddress;
      } else {
        // For saved addresses, we need coordinates
        // In a real app, you might want to use geocoding here
        // For now, we'll use the current location as fallback
        final position = locationProvider.currentPosition;
        if (position == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.pleaseEnableLocationToSave),
              ),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
        latitude = position.latitude;
        longitude = position.longitude;
        addressString = locationProvider.currentAddress;
      }

      final address = SavedAddress(
        id: widget.address?.id ?? SavedAddressService.generateId(),
        label: _labelController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        address: addressString,
        cityId: _selectedCityId,
        villageId: _selectedVillageId,
        streetDetails: _streetDetailsController.text.trim().isEmpty
            ? null
            : _streetDetailsController.text.trim(),
      );

      final success = widget.address == null
          ? await SavedAddressService.saveAddress(address)
          : await SavedAddressService.updateAddress(address);

      if (success && mounted) {
        Navigator.of(context).pop(address);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSaveAddress)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locationProvider = context.watch<LocationViewModel>();
    final regionProvider = context.watch<RegionViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? l10n.addAddress : l10n.editAddress),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.addressLabel,
                prefixIcon: const Icon(Icons.label_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterLabel;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer<LocationViewModel>(
              builder: (context, location, _) {
                return SwitchListTile(
                  title: Text(l10n.useCurrentLocation),
                  subtitle: Text(
                    location.currentAddress ?? l10n.gettingLocation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: _useCurrentLocation,
                  onChanged: (value) {
                    setState(() => _useCurrentLocation = value);
                  },
                );
              },
            ),
            if (!_useCurrentLocation) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCityId,
                decoration: InputDecoration(
                  labelText: l10n.city,
                  prefixIcon: const Icon(Icons.location_city),
                  border: const OutlineInputBorder(),
                ),
                items: regionProvider.activeCities.map((city) {
                  return DropdownMenuItem<String>(
                    value: city.id,
                    child: Text(city.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCityId = value;
                    _selectedVillageId = null;
                  });
                  if (value != null) {
                    regionProvider.loadVillages(value);
                  }
                },
              ),
              if (_selectedCityId != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedVillageId,
                  decoration: InputDecoration(
                    labelText: l10n.villageArea,
                    prefixIcon: const Icon(Icons.home_work),
                    border: const OutlineInputBorder(),
                  ),
                  items: regionProvider
                      .activeVillagesForCity(_selectedCityId!)
                      .map((village) {
                    return DropdownMenuItem<String>(
                      value: village.id,
                      child: Text(village.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedVillageId = value);
                  },
                ),
              ],
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetDetailsController,
              decoration: InputDecoration(
                labelText: l10n.streetAddressDetails,
                hintText: l10n.streetBuildingFloorApartment,
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.address == null ? l10n.saveAddress : l10n.updateAddress),
            ),
          ],
        ),
      ),
    );
  }
}


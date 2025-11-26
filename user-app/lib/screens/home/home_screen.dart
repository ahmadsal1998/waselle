import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';

import '../../repositories/home_repository.dart';
import '../../view_models/driver_view_model.dart';
import '../../view_models/home_view_model.dart';
import '../../view_models/location_view_model.dart';
import '../../view_models/map_style_view_model.dart';
import '../../view_models/order_view_model.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/notification_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/responsive_button.dart';
import 'order_history_screen.dart';
import 'order_tracking_screen.dart';
import 'profile_screen.dart';
import 'receive_request_screen.dart';
import 'send_request_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static List<String> _tabTitles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.discover,
      l10n.trackOrder,
      l10n.orderHistory,
      l10n.profile,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (context) => HomeViewModel(
        repository: HomeRepository(
          locationViewModel: context.read<LocationViewModel>(),
          orderViewModel: context.read<OrderViewModel>(),
          driverViewModel: context.read<DriverViewModel>(),
          authViewModel: context.read<AuthViewModel>(),
        ),
      ),
      child: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatefulWidget {
  const _HomeScreenView();

  @override
  State<_HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<_HomeScreenView> {
  @override
  void initState() {
    super.initState();
    // Check for pending navigation from notification and initialize call listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNavigation();
      _initializeCallListener();
    });
  }

  Future<void> _checkPendingNavigation() async {
    final orderId = await NotificationService.getPendingNavigation();
    if (orderId != null && mounted) {
      // Navigate to order tracking tab (index 1)
      final viewModel = Provider.of<HomeViewModel>(context, listen: false);
      viewModel.onTabSelected(1);
    }
  }

  Future<void> _initializeCallListener() async {
    // Ensure SocketService is initialized
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.isAuthenticated) {
      await SocketService.initialize();
      // Wait a bit for socket to connect
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _setupCallListener();
  }

  void _setupCallListener() {
    SocketService.on('incoming-call', (data) {
      if (!mounted) return;
      
      final orderId = data['orderId']?.toString();
      final roomId = data['roomId']?.toString();
      final callerId = data['callerId']?.toString();
      final callerName = data['callerName']?.toString() ?? 'Unknown';
      
      if (orderId == null || roomId == null || callerId == null) {
        debugPrint('Error: Invalid incoming call data');
        return;
      }
      
      debugPrint('📞 RECEIVER: Received incoming call notification');
      debugPrint('   - callerName: $callerName');
      debugPrint('   - orderId: $orderId');
      debugPrint('   - roomId (from server): $roomId');
      debugPrint('   - callerId: $callerId');
      debugPrint('   - Will use this EXACT roomId when accepting call');
      
      // Call functionality removed - ZegoUIKitPrebuiltCall dependency removed
      // Incoming call handling disabled
    });
    
    SocketService.on('call-cancelled', (data) {
      if (!mounted) return;
      
      final roomId = data['roomId']?.toString();
      final callerId = data['callerId']?.toString();
      
      if (roomId == null || callerId == null) {
        debugPrint('Error: Invalid call cancellation data');
        return;
      }
      
      debugPrint('🚫 Call cancelled: Caller $callerId disconnected');
      
      // Call functionality removed - ZegoUIKitPrebuiltCall dependency removed
      // Call cancellation handling disabled
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, _) {
        final l10n = AppLocalizations.of(context)!;
        final tabTitles = HomeScreen._tabTitles(context);
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _HomeAppBar(
            title: tabTitles[viewModel.currentTabIndex],
          ),
          body: IndexedStack(
            index: viewModel.currentTabIndex,
            children: [
              _MapTab(viewModel: viewModel),
          const OrderTrackingScreen(showAppBar: false),
              const OrderHistoryScreen(),
              const ProfileScreen(showAppBar: false),
            ],
          ),
          bottomNavigationBar: _HomeNavigationBar(
            currentIndex: viewModel.currentTabIndex,
            onDestinationSelected: viewModel.onTabSelected,
            hasActiveOrder: viewModel.hasActiveOrder,
          ),
        );
      },
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({
    required this.title,
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _HomeNavigationBar extends StatelessWidget {
  const _HomeNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.hasActiveOrder,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool hasActiveOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      animationDuration: const Duration(milliseconds: 400),
      height: 72,
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.92),
      indicatorColor: colorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map),
          label: l10n.discover,
        ),
        NavigationDestination(
          icon: _TrackNavIcon(
            hasActiveOrder: hasActiveOrder,
            isSelected: false,
          ),
          selectedIcon: _TrackNavIcon(
            hasActiveOrder: hasActiveOrder,
            isSelected: true,
          ),
          label: l10n.trackOrder,
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: l10n.orderHistory,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.profile,
        ),
      ],
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (viewModel.isInitialLoading) {
      return _CenteredStatusCard(
        icon: Icons.explore,
        title: l10n.initializing,
        subtitle: l10n.initializingSubtitle,
        showLoader: true,
      );
    }

    if (viewModel.hasBlockingLocationError) {
      return _CenteredStatusCard(
        icon: Icons.location_off_rounded,
        title: l10n.locationDisabled,
        subtitle: viewModel.locationErrorMessage ?? l10n.locationDisabledSubtitle,
        primaryActionLabel: l10n.tryAgain,
        onPrimaryAction: viewModel.retryLocation,
      );
    }

    if (viewModel.showNoLocationState) {
      return _CenteredStatusCard(
        icon: Icons.my_location,
        title: l10n.locationNotFound,
        subtitle: l10n.locationNotFoundSubtitle,
        primaryActionLabel: l10n.getLocation,
        onPrimaryAction: viewModel.retryLocation,
      );
    }

    final location = viewModel.currentLocation!;
    final driverMarkers = viewModel.driverMarkers;

    return Stack(
      children: [
        _buildMap(context, location, driverMarkers),
        _MapTopOverlay(
          address: viewModel.currentAddress,
          onLocateMe: () {
            viewModel.recenterMap();
            viewModel.retryLocation();
          },
          isUpdating: viewModel.isLocationLoading,
        ),
        _MapBottomActions(
          onSendRequest: () => _navigateTo(context, const SendRequestScreen()),
          onReceiveRequest: () =>
              _navigateTo(context, const ReceiveRequestScreen()),
          onDriversRefresh: viewModel.refreshDrivers,
          isRefreshingDrivers: viewModel.isDriverLoading,
        ),
      ],
    );
  }

  Widget _buildMap(
    BuildContext context,
    LatLng location,
    List<DriverMarkerData> drivers,
  ) {
    return FlutterMap(
      mapController: viewModel.mapController,
      options: MapOptions(
        initialCenter: location,
        initialZoom: 15,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        _MapTileLayer(),
        MarkerLayer(
          markers: [
            _buildUserMarker(context, location),
            ...drivers.map(_buildDriverMarker),
          ],
        ),
        const _MapAttribution(),
      ],
    );
  }

  Marker _buildUserMarker(BuildContext context, LatLng location) {
    final colorScheme = Theme.of(context).colorScheme;

    return Marker(
      point: location,
      width: 68,
      height: 68,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colorScheme.primary.withOpacity(0.4),
              colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.my_location,
              size: 24,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Marker _buildDriverMarker(DriverMarkerData driver) {
    final baseColor = driver.isAvailable ? Colors.green : Colors.orange;

    return Marker(
      point: driver.position,
      width: 96,
      height: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (driver.name != null && driver.name!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                driver.name!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor.withOpacity(0.18),
            ),
            child: Icon(
              Icons.delivery_dining_rounded,
              color: baseColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

class _MapTileLayer extends StatelessWidget {
  const _MapTileLayer();

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStyleViewModel>(
      builder: (context, mapStyleProvider, _) {
        final subdomains = mapStyleProvider.getSubdomains();
        return TileLayer(
          urlTemplate: mapStyleProvider.getUrlTemplate(),
          userAgentPackageName: 'com.wassle.userapp',
          maxZoom: mapStyleProvider.getMaxZoom().toDouble(),
          subdomains: subdomains ?? const ['a', 'b', 'c'],
          retinaMode: mapStyleProvider.useRetinaTiles()
              ? RetinaMode.isHighDensity(context)
              : false,
        );
      },
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStyleViewModel>(
      builder: (context, mapStyleProvider, _) {
        final attribution = mapStyleProvider.getAttribution();
        if (attribution == null || attribution.isEmpty) {
          return const SizedBox.shrink();
        }
        return RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution(attribution),
          ],
        );
      },
    );
  }
}

class _MapTopOverlay extends StatelessWidget {
  const _MapTopOverlay({
    required this.address,
    required this.onLocateMe,
    required this.isUpdating,
  });

  final String? address;
  final VoidCallback onLocateMe;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.place_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.currentLocation,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address ?? 'Locating...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ResponsiveButton.filled(
                context: context,
                onPressed: onLocateMe,
                icon: isUpdating ? null : Icons.my_location_rounded,
                backgroundColor: colorScheme.primaryContainer.withOpacity(0.7),
                foregroundColor: colorScheme.onPrimaryContainer,
                borderRadius: 16,
                isFullWidth: false,
                child: isUpdating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.locate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapBottomActions extends StatelessWidget {
  const _MapBottomActions({
    required this.onSendRequest,
    required this.onReceiveRequest,
    required this.onDriversRefresh,
    required this.isRefreshingDrivers,
  });

  final VoidCallback onSendRequest;
  final VoidCallback onReceiveRequest;
  final Future<void> Function() onDriversRefresh;
  final bool isRefreshingDrivers;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ResponsiveButton.filled(
                    context: context,
                    onPressed: onSendRequest,
                    icon: Icons.send,
                    borderRadius: 18,
                    child: Text(
                      l10n.sendDelivery,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ResponsiveButton.filled(
                    context: context,
                    onPressed: onReceiveRequest,
                    icon: Icons.call_received_rounded,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    borderRadius: 18,
                    child: Text(
                      l10n.receiveRequest,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isRefreshingDrivers ? null : () => onDriversRefresh(),
                style: OutlinedButton.styleFrom(
                  padding: ResponsiveButton.getPadding(context),
                  side: BorderSide(color: colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: TextStyle(
                    fontSize: ResponsiveButton.getFontSize(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRefreshingDrivers)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    else
                      Icon(
                        Icons.refresh_outlined,
                        size: ResponsiveButton.getIconSize(context),
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.refreshNearbyDrivers,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredStatusCard extends StatelessWidget {
  _CenteredStatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.showLoader = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? primaryActionLabel;
  final Future<void> Function()? onPrimaryAction;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (showLoader) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
              if (primaryActionLabel != null && onPrimaryAction != null) ...[
                const SizedBox(height: 24),
                ResponsiveButton.filled(
                  context: context,
                  onPressed: onPrimaryAction,
                  icon: Icons.refresh,
                  borderRadius: 16,
                  child: Text(
                    primaryActionLabel!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackNavIcon extends StatelessWidget {
  const _TrackNavIcon({
    required this.hasActiveOrder,
    required this.isSelected,
  });

  final bool hasActiveOrder;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isSelected
        ? colorScheme.primary
        : Theme.of(context).iconTheme.color ?? colorScheme.onSurfaceVariant;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isSelected ? Icons.route : Icons.route_outlined,
          color: iconColor,
        ),
        if (hasActiveOrder)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

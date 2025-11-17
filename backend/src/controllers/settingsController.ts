import { Response, Request } from 'express';
import Settings from '../models/Settings';
import { AuthRequest } from '../middleware/auth';

export const getSettings = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Only admins can access settings' });
      return;
    }

    const settings = await Settings.getSettings();
    res.status(200).json({ settings });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to get settings',
    });
  }
};

export const updateSettings = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Only admins can update settings' });
      return;
    }

    const {
      orderNotificationRadiusKm,
      internalOrderRadiusKm,
      externalOrderRadiusKm,
      serviceAreaCenter,
      serviceAreaRadiusKm,
      vehicleTypes,
    } = req.body;

    // Validate orderNotificationRadiusKm (backward compatibility)
    if (
      orderNotificationRadiusKm !== undefined &&
      (typeof orderNotificationRadiusKm !== 'number' ||
        orderNotificationRadiusKm < 1 ||
        orderNotificationRadiusKm > 100)
    ) {
      res.status(400).json({
        message:
          'orderNotificationRadiusKm must be a number between 1 and 100',
      });
      return;
    }

    // Validate internalOrderRadiusKm
    if (
      internalOrderRadiusKm !== undefined &&
      (typeof internalOrderRadiusKm !== 'number' ||
        internalOrderRadiusKm < 1 ||
        internalOrderRadiusKm > 100)
    ) {
      res.status(400).json({
        message: 'internalOrderRadiusKm must be a number between 1 and 100',
      });
      return;
    }

    // Validate externalOrderRadiusKm
    if (
      externalOrderRadiusKm !== undefined &&
      (typeof externalOrderRadiusKm !== 'number' ||
        externalOrderRadiusKm < 1 ||
        externalOrderRadiusKm > 100)
    ) {
      res.status(400).json({
        message: 'externalOrderRadiusKm must be a number between 1 and 100',
      });
      return;
    }

    // Validate serviceAreaCenter
    if (serviceAreaCenter !== undefined) {
      if (
        typeof serviceAreaCenter !== 'object' ||
        typeof serviceAreaCenter.lat !== 'number' ||
        typeof serviceAreaCenter.lng !== 'number' ||
        serviceAreaCenter.lat < -90 ||
        serviceAreaCenter.lat > 90 ||
        serviceAreaCenter.lng < -180 ||
        serviceAreaCenter.lng > 180
      ) {
        res.status(400).json({
          message:
            'serviceAreaCenter must be an object with valid lat (-90 to 90) and lng (-180 to 180)',
        });
        return;
      }
    }

    // Validate serviceAreaRadiusKm
    if (
      serviceAreaRadiusKm !== undefined &&
      (typeof serviceAreaRadiusKm !== 'number' ||
        serviceAreaRadiusKm < 1 ||
        serviceAreaRadiusKm > 500)
    ) {
      res.status(400).json({
        message: 'serviceAreaRadiusKm must be a number between 1 and 500',
      });
      return;
    }

    let settings = await Settings.getSettings();

    // Update fields if provided
    if (orderNotificationRadiusKm !== undefined) {
      settings.orderNotificationRadiusKm = orderNotificationRadiusKm;
    }
    if (internalOrderRadiusKm !== undefined) {
      settings.internalOrderRadiusKm = internalOrderRadiusKm;
    }
    if (externalOrderRadiusKm !== undefined) {
      settings.externalOrderRadiusKm = externalOrderRadiusKm;
    }
    if (serviceAreaCenter !== undefined) {
      settings.serviceAreaCenter = serviceAreaCenter;
    }
    if (serviceAreaRadiusKm !== undefined) {
      settings.serviceAreaRadiusKm = serviceAreaRadiusKm;
    }

    // Update vehicle types if provided
    if (vehicleTypes !== undefined) {
      if (typeof vehicleTypes !== 'object' || vehicleTypes === null) {
        res.status(400).json({
          message: 'vehicleTypes must be an object',
        });
        return;
      }

      // Validate and update each vehicle type
      const validVehicleTypes = ['bike', 'car', 'cargo'];
      for (const [type, config] of Object.entries(vehicleTypes)) {
        if (!validVehicleTypes.includes(type)) {
          res.status(400).json({
            message: `Invalid vehicle type: ${type}. Valid types are: ${validVehicleTypes.join(', ')}`,
          });
          return;
        }

        if (typeof config !== 'object' || config === null) {
          res.status(400).json({
            message: `Vehicle type ${type} config must be an object`,
          });
          return;
        }

        const vehicleConfig = config as { enabled?: boolean; basePrice?: number };

        if (vehicleConfig.enabled !== undefined) {
          if (typeof vehicleConfig.enabled !== 'boolean') {
            res.status(400).json({
              message: `Vehicle type ${type} enabled must be a boolean`,
            });
            return;
          }
          settings.vehicleTypes[type as 'bike' | 'car' | 'cargo'].enabled = vehicleConfig.enabled;
        }

        if (vehicleConfig.basePrice !== undefined) {
          if (typeof vehicleConfig.basePrice !== 'number' || vehicleConfig.basePrice < 0) {
            res.status(400).json({
              message: `Vehicle type ${type} basePrice must be a non-negative number`,
            });
            return;
          }
          settings.vehicleTypes[type as 'bike' | 'car' | 'cargo'].basePrice = vehicleConfig.basePrice;
        }
      }
    }

    await settings.save();

    res.status(200).json({
      message: 'Settings updated successfully',
      settings,
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update settings',
    });
  }
};

export const getVehicleTypes = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const settings = await Settings.getSettings();
    const vehicleTypes = Object.entries(settings.vehicleTypes).map(
      ([type, config]) => ({
        id: type,
        label: type.charAt(0).toUpperCase() + type.slice(1),
        enabled: config.enabled,
        basePrice: config.basePrice,
      })
    );

    // Only return enabled vehicle types for public endpoint
    const availableVehicleTypes = vehicleTypes.filter((vt) => vt.enabled);

    res.status(200).json({ vehicleTypes: availableVehicleTypes });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to get vehicle types',
    });
  }
};


import { Response, Request } from 'express';
import Settings from '../models/Settings';
import { AuthRequest } from '../middleware/auth';
import { checkAllDriversBalance } from '../utils/balance';

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
      internalOrderRadiusKm,
      externalOrderMinRadiusKm,
      externalOrderMaxRadiusKm,
      vehicleTypes,
      commissionPercentage,
      maxAllowedBalance,
      mapDefaultCenter,
      mapDefaultZoom,
      otpMessageTemplate,
      otpMessageTemplateAr,
      otpMessageLanguage,
      privacyPolicyUrl,
      termsOfServiceUrl,
    } = req.body;

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

    // Validate externalOrderMinRadiusKm
    if (
      externalOrderMinRadiusKm !== undefined &&
      (typeof externalOrderMinRadiusKm !== 'number' ||
        externalOrderMinRadiusKm < 1 ||
        externalOrderMinRadiusKm > 100)
    ) {
      res.status(400).json({
        message: 'externalOrderMinRadiusKm must be a number between 1 and 100',
      });
      return;
    }

    // Validate externalOrderMaxRadiusKm
    if (
      externalOrderMaxRadiusKm !== undefined &&
      (typeof externalOrderMaxRadiusKm !== 'number' ||
        externalOrderMaxRadiusKm < 1 ||
        externalOrderMaxRadiusKm > 100)
    ) {
      res.status(400).json({
        message: 'externalOrderMaxRadiusKm must be a number between 1 and 100',
      });
      return;
    }

    // Validate that min <= max if both are provided
    if (
      externalOrderMinRadiusKm !== undefined &&
      externalOrderMaxRadiusKm !== undefined &&
      externalOrderMinRadiusKm > externalOrderMaxRadiusKm
    ) {
      res.status(400).json({
        message: 'externalOrderMinRadiusKm must be less than or equal to externalOrderMaxRadiusKm',
      });
      return;
    }

    let settings = await Settings.getSettings();

    // Update fields if provided
    if (internalOrderRadiusKm !== undefined) {
      settings.internalOrderRadiusKm = internalOrderRadiusKm;
    }
    if (externalOrderMinRadiusKm !== undefined) {
      settings.externalOrderMinRadiusKm = externalOrderMinRadiusKm;
      // Ensure max is still >= min if max wasn't updated
      if (settings.externalOrderMaxRadiusKm < externalOrderMinRadiusKm) {
        settings.externalOrderMaxRadiusKm = externalOrderMinRadiusKm;
      }
    }
    if (externalOrderMaxRadiusKm !== undefined) {
      settings.externalOrderMaxRadiusKm = externalOrderMaxRadiusKm;
      // Ensure min is still <= max if min wasn't updated
      if (settings.externalOrderMinRadiusKm > externalOrderMaxRadiusKm) {
        settings.externalOrderMinRadiusKm = externalOrderMaxRadiusKm;
      }
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

    // Update commission percentage if provided
    if (commissionPercentage !== undefined) {
      if (typeof commissionPercentage !== 'number' || commissionPercentage < 0 || commissionPercentage > 100) {
        res.status(400).json({
          message: 'commissionPercentage must be a number between 0 and 100',
        });
        return;
      }
      settings.commissionPercentage = commissionPercentage;
    }

    // Update max allowed balance if provided
    if (maxAllowedBalance !== undefined) {
      if (typeof maxAllowedBalance !== 'number' || maxAllowedBalance < 0) {
        res.status(400).json({
          message: 'maxAllowedBalance must be a non-negative number',
        });
        return;
      }
      settings.maxAllowedBalance = maxAllowedBalance;
    }

    // Update map default center if provided
    if (mapDefaultCenter !== undefined) {
      if (
        typeof mapDefaultCenter !== 'object' ||
        typeof mapDefaultCenter.lat !== 'number' ||
        typeof mapDefaultCenter.lng !== 'number' ||
        mapDefaultCenter.lat < -90 ||
        mapDefaultCenter.lat > 90 ||
        mapDefaultCenter.lng < -180 ||
        mapDefaultCenter.lng > 180
      ) {
        res.status(400).json({
          message:
            'mapDefaultCenter must be an object with valid lat (-90 to 90) and lng (-180 to 180)',
        });
        return;
      }
      settings.mapDefaultCenter = mapDefaultCenter;
    }

    // Update map default zoom if provided
    if (mapDefaultZoom !== undefined) {
      if (typeof mapDefaultZoom !== 'number' || mapDefaultZoom < 1 || mapDefaultZoom > 18) {
        res.status(400).json({
          message: 'mapDefaultZoom must be a number between 1 and 18',
        });
        return;
      }
      settings.mapDefaultZoom = mapDefaultZoom;
    }

    // Update OTP message template if provided
    if (otpMessageTemplate !== undefined) {
      if (typeof otpMessageTemplate !== 'string') {
        res.status(400).json({
          message: 'otpMessageTemplate must be a string',
        });
        return;
      }

      // Validate template contains ${otp} placeholder
      if (!otpMessageTemplate.includes('${otp}')) {
        res.status(400).json({
          message: 'otpMessageTemplate must contain ${otp} placeholder for the OTP code',
        });
        return;
      }

      // Validate length (SMS messages are typically limited, but allow up to 500 chars for template)
      if (otpMessageTemplate.length > 500) {
        res.status(400).json({
          message: 'otpMessageTemplate must be 500 characters or less',
        });
        return;
      }

      // Validate minimum length
      if (otpMessageTemplate.trim().length < 10) {
        res.status(400).json({
          message: 'otpMessageTemplate must be at least 10 characters',
        });
        return;
      }

      settings.otpMessageTemplate = otpMessageTemplate.trim();
    }

    // Update Arabic OTP message template if provided
    if (otpMessageTemplateAr !== undefined) {
      if (typeof otpMessageTemplateAr !== 'string') {
        res.status(400).json({
          message: 'otpMessageTemplateAr must be a string',
        });
        return;
      }

      // Validate template contains ${otp} placeholder
      if (!otpMessageTemplateAr.includes('${otp}')) {
        res.status(400).json({
          message: 'otpMessageTemplateAr must contain ${otp} placeholder for the OTP code',
        });
        return;
      }

      // Validate length
      if (otpMessageTemplateAr.length > 500) {
        res.status(400).json({
          message: 'otpMessageTemplateAr must be 500 characters or less',
        });
        return;
      }

      // Validate minimum length
      if (otpMessageTemplateAr.trim().length < 10) {
        res.status(400).json({
          message: 'otpMessageTemplateAr must be at least 10 characters',
        });
        return;
      }

      settings.otpMessageTemplateAr = otpMessageTemplateAr.trim();
    }

    // Update OTP message language preference if provided
    if (otpMessageLanguage !== undefined) {
      if (otpMessageLanguage !== 'en' && otpMessageLanguage !== 'ar') {
        res.status(400).json({
          message: 'otpMessageLanguage must be either "en" or "ar"',
        });
        return;
      }
      settings.otpMessageLanguage = otpMessageLanguage;
    }

    // Update privacy policy URL if provided
    if (privacyPolicyUrl !== undefined) {
      if (typeof privacyPolicyUrl !== 'string') {
        res.status(400).json({
          message: 'privacyPolicyUrl must be a string',
        });
        return;
      }
      // Validate URL format
      try {
        new URL(privacyPolicyUrl.trim());
        settings.privacyPolicyUrl = privacyPolicyUrl.trim();
      } catch {
        res.status(400).json({
          message: 'privacyPolicyUrl must be a valid URL',
        });
        return;
      }
    }

    // Update terms of service URL if provided
    if (termsOfServiceUrl !== undefined) {
      if (typeof termsOfServiceUrl !== 'string') {
        res.status(400).json({
          message: 'termsOfServiceUrl must be a string',
        });
        return;
      }
      // Validate URL format
      try {
        new URL(termsOfServiceUrl.trim());
        settings.termsOfServiceUrl = termsOfServiceUrl.trim();
      } catch {
        res.status(400).json({
          message: 'termsOfServiceUrl must be a valid URL',
        });
        return;
      }
    }

    await settings.save();

    // If commission percentage or max allowed balance changed, check all drivers
    const commissionChanged = commissionPercentage !== undefined;
    const maxBalanceChanged = maxAllowedBalance !== undefined;
    
    if (commissionChanged || maxBalanceChanged) {
      try {
        const checkResult = await checkAllDriversBalance();
        console.log(
          `Settings updated: Checked ${checkResult.checked} drivers, ` +
          `suspended ${checkResult.suspended}, errors: ${checkResult.errors}`
        );
      } catch (error) {
        console.error('Error checking all drivers balance after settings update:', error);
        // Don't fail the settings update if balance check fails
      }
    }

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

// Public endpoint to get legal URLs (privacy policy and terms of service)
export const getLegalUrls = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const settings = await Settings.getSettings();
    res.status(200).json({
      privacyPolicyUrl: settings.privacyPolicyUrl || 'https://www.wassle.ps/privacy-policy',
      termsOfServiceUrl: settings.termsOfServiceUrl || 'https://www.wassle.ps/terms-of-service',
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to get legal URLs',
    });
  }
};


import { Response, Request } from 'express';
import mongoose, { FilterQuery } from 'mongoose';
import City, { ICity, IVillageSubdocument } from '../models/City';
import { AuthRequest } from '../middleware/auth';

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const formatCityResponse = (
  city: ICity | (ICity & { toObject: () => any }),
  options: { hideInactiveVillages?: boolean } = {}
) => {
  const cityObject = typeof city.toObject === 'function' ? city.toObject() : city;
  const villages: IVillageSubdocument[] = Array.isArray(cityObject.villages)
    ? cityObject.villages.map((village: any) =>
        typeof village?.toObject === 'function' ? village.toObject() : village
      )
    : [];

  const cityId = cityObject._id?.toString ? cityObject._id.toString() : cityObject._id;

  const filteredVillages = options.hideInactiveVillages
    ? villages.filter((village) => village.isActive)
    : villages;

  return {
    ...cityObject,
    villages: filteredVillages.map((village) => ({
      ...village,
      cityId,
    })),
    villagesCount: villages.length,
  };
};

export const createCity = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, nameEn } = req.body;

    if (typeof name !== 'string' || !name.trim()) {
      res.status(400).json({ message: 'City name is required' });
      return;
    }

    const trimmedName = name.trim();
    const trimmedNameEn = typeof nameEn === 'string' ? nameEn.trim() : undefined;

    const existingCity = await City.findOne({
      name: { $regex: `^${escapeRegExp(trimmedName)}$`, $options: 'i' },
    });

    if (existingCity) {
      res.status(409).json({ message: 'City with this name already exists' });
      return;
    }

    const city = await City.create({ 
      name: trimmedName,
      ...(trimmedNameEn ? { nameEn: trimmedNameEn } : {}),
    });

    res.status(201).json({
      message: 'City created successfully',
      city: formatCityResponse(city),
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to create city',
    });
  }
};

export const getCities = async (req: Request, res: Response): Promise<void> => {
  try {
    const { active } = req.query;
    const filter: FilterQuery<ICity> = {};

    if (typeof active === 'string') {
      if (['true', 'false'].includes(active.toLowerCase())) {
        filter.isActive = active.toLowerCase() === 'true';
      } else {
        res.status(400).json({ message: 'Invalid active filter value' });
        return;
      }
    }

    const cities = await City.find(filter).sort({ name: 1 }).lean();
    const hideInactiveVillages = filter.isActive === true;
    const citiesWithCount = cities.map((city) =>
      formatCityResponse(city as unknown as ICity, { hideInactiveVillages })
    );

    res.status(200).json({ cities: citiesWithCount });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to fetch cities',
    });
  }
};

export const updateCity = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { name, nameEn, isActive, serviceCenter } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: 'Invalid city id' });
      return;
    }

    if (
      (name === undefined || (typeof name === 'string' && !name.trim())) &&
      nameEn === undefined &&
      typeof isActive !== 'boolean' &&
      serviceCenter === undefined
    ) {
      res.status(400).json({ message: 'No valid fields provided for update' });
      return;
    }

    const city = await City.findById(id);
    if (!city) {
      res.status(404).json({ message: 'City not found' });
      return;
    }

    if (typeof name === 'string') {
      const trimmedName = name.trim();
      if (!trimmedName) {
        res.status(400).json({ message: 'City name cannot be empty' });
        return;
      }

      const duplicate = await City.findOne({
        _id: { $ne: city._id },
        name: { $regex: `^${escapeRegExp(trimmedName)}$`, $options: 'i' },
      });

      if (duplicate) {
        res.status(409).json({ message: 'Another city with this name already exists' });
        return;
      }

      city.name = trimmedName;
    }

    if (nameEn !== undefined) {
      const trimmedNameEn = typeof nameEn === 'string' ? nameEn.trim() : undefined;
      (city as any).nameEn = trimmedNameEn || undefined;
    }

    let villagesDeactivated = false;
    if (typeof isActive === 'boolean' && city.isActive !== isActive) {
      city.isActive = isActive;

      if (!isActive) {
        city.villages.forEach((village) => {
          village.isActive = false;
        });
        villagesDeactivated = true;
      }
    }

    // Handle service center configuration
    if (serviceCenter !== undefined) {
      if (serviceCenter === null) {
        // Remove service center configuration
        city.serviceCenter = undefined;
      } else if (typeof serviceCenter === 'object') {
        // Validate service center configuration
        if (serviceCenter.center) {
          if (
            typeof serviceCenter.center.lat !== 'number' ||
            typeof serviceCenter.center.lng !== 'number' ||
            serviceCenter.center.lat < -90 ||
            serviceCenter.center.lat > 90 ||
            serviceCenter.center.lng < -180 ||
            serviceCenter.center.lng > 180
          ) {
            res.status(400).json({
              message:
                'Service center center must have valid lat (-90 to 90) and lng (-180 to 180)',
            });
            return;
          }
        }

        if (
          serviceCenter.internalOrderRadiusKm !== undefined &&
          (typeof serviceCenter.internalOrderRadiusKm !== 'number' ||
            serviceCenter.internalOrderRadiusKm < 1 ||
            serviceCenter.internalOrderRadiusKm > 100)
        ) {
          res.status(400).json({
            message: 'Internal order radius must be a number between 1 and 100',
          });
          return;
        }

        // Validate externalOrderMinRadiusKm
        if (
          serviceCenter.externalOrderMinRadiusKm !== undefined &&
          (typeof serviceCenter.externalOrderMinRadiusKm !== 'number' ||
            serviceCenter.externalOrderMinRadiusKm < 1 ||
            serviceCenter.externalOrderMinRadiusKm > 100)
        ) {
          res.status(400).json({
            message: 'External order min radius must be a number between 1 and 100',
          });
          return;
        }

        // Validate externalOrderMaxRadiusKm
        if (
          serviceCenter.externalOrderMaxRadiusKm !== undefined &&
          (typeof serviceCenter.externalOrderMaxRadiusKm !== 'number' ||
            serviceCenter.externalOrderMaxRadiusKm < 1 ||
            serviceCenter.externalOrderMaxRadiusKm > 100)
        ) {
          res.status(400).json({
            message: 'External order max radius must be a number between 1 and 100',
          });
          return;
        }

        // Validate that min <= max if both are provided
        if (
          serviceCenter.externalOrderMinRadiusKm !== undefined &&
          serviceCenter.externalOrderMaxRadiusKm !== undefined &&
          serviceCenter.externalOrderMinRadiusKm > serviceCenter.externalOrderMaxRadiusKm
        ) {
          res.status(400).json({
            message: 'External order min radius must be less than or equal to max radius',
          });
          return;
        }

        // Handle backward compatibility: if externalOrderRadiusKm is provided, migrate to min/max
        if (serviceCenter.externalOrderRadiusKm !== undefined) {
          const oldRadius = serviceCenter.externalOrderRadiusKm;
          if (typeof oldRadius === 'number' && oldRadius >= 1 && oldRadius <= 100) {
            // Migrate old single radius to min/max range
            serviceCenter.externalOrderMinRadiusKm = oldRadius;
            serviceCenter.externalOrderMaxRadiusKm = oldRadius + 5; // Default range: old value to old value + 5km
          } else {
            res.status(400).json({
              message: 'External order radius (legacy) must be a number between 1 and 100',
            });
            return;
          }
        }

        // Update service center configuration
        if (!city.serviceCenter) {
          city.serviceCenter = {
            center: { lat: 0, lng: 0 },
            internalOrderRadiusKm: 2,
            externalOrderMinRadiusKm: 10,
            externalOrderMaxRadiusKm: 15,
          };
        }

        if (serviceCenter.center) {
          city.serviceCenter.center = serviceCenter.center;
        }
        if (serviceCenter.internalOrderRadiusKm !== undefined) {
          city.serviceCenter.internalOrderRadiusKm = serviceCenter.internalOrderRadiusKm;
        }
        if (serviceCenter.externalOrderMinRadiusKm !== undefined) {
          city.serviceCenter.externalOrderMinRadiusKm = serviceCenter.externalOrderMinRadiusKm;
          // Ensure max is still >= min if max wasn't updated
          if (city.serviceCenter.externalOrderMaxRadiusKm < serviceCenter.externalOrderMinRadiusKm) {
            city.serviceCenter.externalOrderMaxRadiusKm = serviceCenter.externalOrderMinRadiusKm;
          }
        }
        if (serviceCenter.externalOrderMaxRadiusKm !== undefined) {
          city.serviceCenter.externalOrderMaxRadiusKm = serviceCenter.externalOrderMaxRadiusKm;
          // Ensure min is still <= max if min wasn't updated
          if (city.serviceCenter.externalOrderMinRadiusKm > serviceCenter.externalOrderMaxRadiusKm) {
            city.serviceCenter.externalOrderMinRadiusKm = serviceCenter.externalOrderMaxRadiusKm;
          }
        }
      }
    }

    await city.save();

    res.status(200).json({
      message: 'City updated successfully',
      city: formatCityResponse(city),
      villagesDeactivated,
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update city',
    });
  }
};

export const deleteCity = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: 'Invalid city id' });
      return;
    }

    const city = await City.findByIdAndDelete(id);
    if (!city) {
      res.status(404).json({ message: 'City not found' });
      return;
    }

    res.status(200).json({
      message: 'City and associated villages deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to delete city',
    });
  }
};


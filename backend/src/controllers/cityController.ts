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
    const { name } = req.body;

    if (typeof name !== 'string' || !name.trim()) {
      res.status(400).json({ message: 'City name is required' });
      return;
    }

    const trimmedName = name.trim();

    const existingCity = await City.findOne({
      name: { $regex: `^${escapeRegExp(trimmedName)}$`, $options: 'i' },
    });

    if (existingCity) {
      res.status(409).json({ message: 'City with this name already exists' });
      return;
    }

    const city = await City.create({ name: trimmedName });

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
    const { name, isActive, serviceCenter } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: 'Invalid city id' });
      return;
    }

    if (
      (name === undefined || (typeof name === 'string' && !name.trim())) &&
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
          serviceCenter.serviceAreaRadiusKm !== undefined &&
          (typeof serviceCenter.serviceAreaRadiusKm !== 'number' ||
            serviceCenter.serviceAreaRadiusKm < 1 ||
            serviceCenter.serviceAreaRadiusKm > 500)
        ) {
          res.status(400).json({
            message: 'Service area radius must be a number between 1 and 500',
          });
          return;
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

        if (
          serviceCenter.externalOrderRadiusKm !== undefined &&
          (typeof serviceCenter.externalOrderRadiusKm !== 'number' ||
            serviceCenter.externalOrderRadiusKm < 1 ||
            serviceCenter.externalOrderRadiusKm > 100)
        ) {
          res.status(400).json({
            message: 'External order radius must be a number between 1 and 100',
          });
          return;
        }

        // Update service center configuration
        if (!city.serviceCenter) {
          city.serviceCenter = {
            center: { lat: 0, lng: 0 },
            serviceAreaRadiusKm: 20,
            internalOrderRadiusKm: 5,
            externalOrderRadiusKm: 10,
          };
        }

        if (serviceCenter.center) {
          city.serviceCenter.center = serviceCenter.center;
        }
        if (serviceCenter.serviceAreaRadiusKm !== undefined) {
          city.serviceCenter.serviceAreaRadiusKm = serviceCenter.serviceAreaRadiusKm;
        }
        if (serviceCenter.internalOrderRadiusKm !== undefined) {
          city.serviceCenter.internalOrderRadiusKm = serviceCenter.internalOrderRadiusKm;
        }
        if (serviceCenter.externalOrderRadiusKm !== undefined) {
          city.serviceCenter.externalOrderRadiusKm = serviceCenter.externalOrderRadiusKm;
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


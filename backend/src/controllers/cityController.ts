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
    const { name, isActive } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: 'Invalid city id' });
      return;
    }

    if (
      (name === undefined || (typeof name === 'string' && !name.trim())) &&
      typeof isActive !== 'boolean'
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


import { Request, Response } from 'express';
import mongoose from 'mongoose';
import City from '../models/City';

const serializeVillage = (cityId: mongoose.Types.ObjectId, village: any) => {
  const plain =
    typeof village?.toObject === 'function' ? village.toObject() : { ...village };
  return {
    ...plain,
    cityId: cityId.toString(),
  };
};

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export const createVillage = async (req: Request, res: Response): Promise<void> => {
  try {
    const { cityId, name, nameEn, isActive } = req.body;

    if (!cityId || !mongoose.Types.ObjectId.isValid(cityId)) {
      res.status(400).json({ message: 'Valid cityId is required' });
      return;
    }

    if (typeof name !== 'string' || !name.trim()) {
      res.status(400).json({ message: 'Village name is required' });
      return;
    }

    const city = await City.findById(cityId);
    if (!city) {
      res.status(404).json({ message: 'City not found' });
      return;
    }

    const trimmedName = name.trim();
    const trimmedNameEn = typeof nameEn === 'string' ? nameEn.trim() : undefined;

    const duplicate = city.villages.find(
      (village) => village.name.toLowerCase() === trimmedName.toLowerCase()
    );

    if (duplicate) {
      res
        .status(409)
        .json({ message: 'Village with this name already exists for the selected city' });
      return;
    }

    const resolvedActive =
      city.isActive && typeof isActive === 'boolean' ? isActive : city.isActive;

    city.villages.push({
      name: trimmedName,
      ...(trimmedNameEn ? { nameEn: trimmedNameEn } : {}),
      isActive: resolvedActive,
    } as any);

    await city.save();

    const createdVillage = serializeVillage(city._id, city.villages[city.villages.length - 1]);

    res.status(201).json({
      message: 'Village created successfully',
      village: createdVillage,
      notice: !city.isActive
        ? 'Parent city is inactive. Village created as inactive automatically.'
        : undefined,
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to create village',
    });
  }
};

export const getVillages = async (req: Request, res: Response): Promise<void> => {
  try {
    const { cityId, active } = req.query;

    if (typeof cityId !== 'string' || !mongoose.Types.ObjectId.isValid(cityId)) {
      res.status(400).json({ message: 'Valid cityId query parameter is required' });
      return;
    }

    const city = await City.findById(cityId);
    if (!city) {
      res.status(404).json({ message: 'City not found' });
      return;
    }

    let villages = [...city.villages];

    if (typeof active === 'string') {
      if (['true', 'false'].includes(active.toLowerCase())) {
        const isActive = active.toLowerCase() === 'true';
        villages = villages.filter((village) => village.isActive === isActive);
      } else {
        res.status(400).json({ message: 'Invalid active filter value' });
        return;
      }
    }

    villages.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));

    res.status(200).json({
      villages: villages.map((village) => serializeVillage(city._id, village)),
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to fetch villages',
    });
  }
};

export const updateVillage = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { name, nameEn, isActive } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: 'Invalid village id' });
      return;
    }

    if (
      (name === undefined || (typeof name === 'string' && !name.trim())) &&
      nameEn === undefined &&
      typeof isActive !== 'boolean'
    ) {
      res.status(400).json({ message: 'No valid fields provided for update' });
      return;
    }

    const city = await City.findOne({ 'villages._id': id });
    if (!city) {
      res.status(404).json({ message: 'Village not found' });
      return;
    }

    const village = city.villages.id(id);
    if (!village) {
      res.status(404).json({ message: 'Village not found' });
      return;
    }

    if (typeof name === 'string') {
      const trimmedName = name.trim();
      if (!trimmedName) {
        res.status(400).json({ message: 'Village name cannot be empty' });
        return;
      }

      const duplicate = city.villages.find(
        (existing) =>
          existing._id.toString() !== village._id.toString() &&
          existing.name.toLowerCase() === trimmedName.toLowerCase()
      );

      if (duplicate) {
        res
          .status(409)
          .json({ message: 'Another village with this name already exists for this city' });
        return;
      }

      village.name = trimmedName;
    }

    if (nameEn !== undefined) {
      const trimmedNameEn = typeof nameEn === 'string' ? nameEn.trim() : undefined;
      (village as any).nameEn = trimmedNameEn || undefined;
    }

    if (typeof isActive === 'boolean' && village.isActive !== isActive) {
      if (isActive && !city.isActive) {
        res
          .status(400)
          .json({ message: 'Cannot activate village while its city is inactive' });
        return;
      }

      village.isActive = isActive;
    }

    await city.save();

    res.status(200).json({
      message: 'Village updated successfully',
      village: serializeVillage(city._id, village),
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update village',
    });
  }
};

export const deleteVillage = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: 'Invalid village id' });
      return;
    }

    const city = await City.findOne({ 'villages._id': id });
    if (!city) {
      res.status(404).json({ message: 'Village not found' });
      return;
    }

    const village = city.villages.id(id);
    if (!village) {
      res.status(404).json({ message: 'Village not found' });
      return;
    }

    village.deleteOne();
    await city.save();

    res.status(200).json({
      message: 'Village deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to delete village',
    });
  }
};


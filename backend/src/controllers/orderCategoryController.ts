import { Request, Response } from 'express';
import mongoose, { FilterQuery } from 'mongoose';
import OrderCategory, { IOrderCategory } from '../models/OrderCategory';
import { AuthRequest } from '../middleware/auth';

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const formatOrderCategory = (
  category: IOrderCategory | (IOrderCategory & { toObject: () => any })
) => {
  const categoryObject =
    typeof category.toObject === 'function' ? category.toObject() : category;

  return {
    ...categoryObject,
    _id: categoryObject._id?.toString
      ? categoryObject._id.toString()
      : categoryObject._id,
  };
};

export const createOrderCategory = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { name, description } = req.body;

    if (typeof name !== 'string' || !name.trim()) {
      res.status(400).json({ message: 'Category name is required' });
      return;
    }

    const trimmedName = name.trim();

    const existing = await OrderCategory.findOne({
      name: { $regex: `^${escapeRegExp(trimmedName)}$`, $options: 'i' },
    });

    if (existing) {
      res
        .status(409)
        .json({ message: 'Order category with this name already exists' });
      return;
    }

    const category = await OrderCategory.create({
      name: trimmedName,
      description:
        typeof description === 'string' ? description.trim() : undefined,
    });

    res.status(201).json({
      message: 'Order category created successfully',
      category: formatOrderCategory(category),
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to create order category',
    });
  }
};

export const getOrderCategories = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { active } = req.query;
    const filter: FilterQuery<IOrderCategory> = {};

    if (typeof active === 'string') {
      if (['true', 'false'].includes(active.toLowerCase())) {
        filter.isActive = active.toLowerCase() === 'true';
      } else {
        res.status(400).json({ message: 'Invalid active filter value' });
        return;
      }
    }

    const categories = await OrderCategory.find(filter).sort({ name: 1 }).lean();

    res.status(200).json({
      categories: categories.map((category) =>
        formatOrderCategory(category as unknown as IOrderCategory)
      ),
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to fetch order categories',
    });
  }
};

export const updateOrderCategory = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const { name, description, isActive } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: 'Invalid category id' });
      return;
    }

    if (
      name === undefined &&
      description === undefined &&
      typeof isActive !== 'boolean'
    ) {
      res.status(400).json({ message: 'No valid fields provided for update' });
      return;
    }

    const category = await OrderCategory.findById(id);
    if (!category) {
      res.status(404).json({ message: 'Order category not found' });
      return;
    }

    if (typeof name === 'string') {
      const trimmedName = name.trim();
      if (!trimmedName) {
        res.status(400).json({ message: 'Category name cannot be empty' });
        return;
      }

      const duplicate = await OrderCategory.findOne({
        _id: { $ne: category._id },
        name: { $regex: `^${escapeRegExp(trimmedName)}$`, $options: 'i' },
      });

      if (duplicate) {
        res
          .status(409)
          .json({ message: 'Another order category with this name already exists' });
        return;
      }

      category.name = trimmedName;
    }

    if (typeof description === 'string') {
      category.description = description.trim();
    } else if (description === null) {
      category.description = undefined;
    }

    if (typeof isActive === 'boolean') {
      category.isActive = isActive;
    }

    await category.save();

    res.status(200).json({
      message: 'Order category updated successfully',
      category: formatOrderCategory(category),
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update order category',
    });
  }
};

export const deleteOrderCategory = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      res.status(400).json({ message: 'Invalid category id' });
      return;
    }

    const category = await OrderCategory.findByIdAndDelete(id);
    if (!category) {
      res.status(404).json({ message: 'Order category not found' });
      return;
    }

    res
      .status(200)
      .json({ message: 'Order category deleted successfully' });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to delete order category',
    });
  }
};



import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react';
import {
  createOrderCategory,
  deleteOrderCategory,
  getOrderCategories,
  updateOrderCategory,
} from '@/services/orderCategoryService';
import type { OrderCategory } from '@/types';

interface CategoryFormState {
  name: string;
  description: string;
}

const initialFormState: CategoryFormState = {
  name: '',
  description: '',
};

export const useOrderCategoriesManager = () => {
  const [categories, setCategories] = useState<OrderCategory[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [showInactive, setShowInactive] = useState(false);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formState, setFormState] = useState(initialFormState);
  const [editingCategory, setEditingCategory] = useState<OrderCategory | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const fetchCategories = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await getOrderCategories();
      setCategories(data);
    } catch (err) {
      console.error('Failed to fetch order categories:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch order categories');
      setCategories([]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchCategories();
  }, [fetchCategories]);

  const filteredCategories = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase();
    return categories
      .filter((category) => (showInactive ? true : category.isActive))
      .filter((category) =>
        normalizedSearch
          ? category.name.toLowerCase().includes(normalizedSearch) ||
            (category.description ?? '').toLowerCase().includes(normalizedSearch)
          : true
      )
      .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));
  }, [categories, searchTerm, showInactive]);

  const openModal = (category?: OrderCategory) => {
    if (category) {
      setEditingCategory(category);
      setFormState({
        name: category.name,
        description: category.description ?? '',
      });
    } else {
      setEditingCategory(null);
      setFormState(initialFormState);
    }
    setIsModalOpen(true);
  };

  const closeModal = () => {
    if (isSaving) return;
    setIsModalOpen(false);
    setEditingCategory(null);
    setFormState(initialFormState);
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmedName = formState.name.trim();

    if (!trimmedName) {
      setError('Category name is required');
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      if (editingCategory) {
        const updated = await updateOrderCategory(editingCategory._id, {
          name: trimmedName,
          description: formState.description.trim() || null,
        });
        setCategories((prev) =>
          prev.map((item) => (item._id === updated._id ? updated : item))
        );
      } else {
        const created = await createOrderCategory({
          name: trimmedName,
          description: formState.description.trim() || undefined,
        });
        setCategories((prev) => [...prev, created]);
      }
      closeModal();
      await fetchCategories();
    } catch (err) {
      console.error('Failed to save order category:', err);
      setError(err instanceof Error ? err.message : 'Failed to save order category');
    } finally {
      setIsSaving(false);
    }
  };

  const handleToggleStatus = async (category: OrderCategory) => {
    try {
      const updated = await updateOrderCategory(category._id, {
        isActive: !category.isActive,
      });
      setCategories((prev) =>
        prev.map((item) => (item._id === updated._id ? updated : item))
      );
    } catch (err) {
      console.error('Failed to update category status:', err);
      window.alert(err instanceof Error ? err.message : 'Failed to update category status.');
    }
  };

  const handleDelete = async (category: OrderCategory) => {
    const confirmed = window.confirm(
      `Delete order category "${category.name}"? This action cannot be undone.`
    );
    if (!confirmed) return;

    try {
      await deleteOrderCategory(category._id);
      setCategories((prev) => prev.filter((item) => item._id !== category._id));
    } catch (err) {
      console.error('Failed to delete category:', err);
      window.alert(err instanceof Error ? err.message : 'Failed to delete category.');
    }
  };

  return {
    categories,
    filteredCategories,
    isLoading,
    error,
    searchTerm,
    setSearchTerm,
    showInactive,
    setShowInactive,
    isModalOpen,
    openModal,
    closeModal,
    formState,
    setFormState,
    editingCategory,
    isSaving,
    handleSubmit,
    handleToggleStatus,
    handleDelete,
  };
};

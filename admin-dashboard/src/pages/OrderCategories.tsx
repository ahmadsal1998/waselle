import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react';
import { api } from '../config/api';

interface OrderCategory {
  _id: string;
  name: string;
  description?: string;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

interface CategoryFormState {
  name: string;
  description: string;
}

const initialFormState: CategoryFormState = {
  name: '',
  description: '',
};

const OrderCategories = () => {
  const [categories, setCategories] = useState<OrderCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [showInactive, setShowInactive] = useState(false);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formState, setFormState] = useState(initialFormState);
  const [editingCategory, setEditingCategory] = useState<OrderCategory | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const fetchCategories = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/order-categories');
      const fetched: OrderCategory[] = response.data.categories ?? [];
      setCategories(fetched);
    } catch (err: any) {
      console.error('Failed to fetch order categories:', err);
      setError(err.response?.data?.message ?? 'Failed to fetch order categories');
      setCategories([]);
    } finally {
      setLoading(false);
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
        const response = await api.patch(`/order-categories/${editingCategory._id}`, {
          name: trimmedName,
          description: formState.description.trim() || null,
        });
        const updated: OrderCategory = response.data.category;
        setCategories((prev) =>
          prev.map((item) => (item._id === updated._id ? updated : item))
        );
      } else {
        const response = await api.post('/order-categories', {
          name: trimmedName,
          description: formState.description.trim() || undefined,
        });
        const created: OrderCategory = response.data.category;
        setCategories((prev) => [...prev, created]);
      }
      closeModal();
      await fetchCategories();
    } catch (err: any) {
      console.error('Failed to save order category:', err);
      setError(err.response?.data?.message ?? 'Failed to save order category');
    } finally {
      setIsSaving(false);
    }
  };

  const handleToggleStatus = async (category: OrderCategory) => {
    try {
      const response = await api.patch(`/order-categories/${category._id}`, {
        isActive: !category.isActive,
      });
      const updated: OrderCategory = response.data.category;
      setCategories((prev) =>
        prev.map((item) => (item._id === updated._id ? updated : item))
      );
    } catch (err: any) {
      console.error('Failed to update category status:', err);
      window.alert(err.response?.data?.message ?? 'Failed to update category status.');
    }
  };

  const handleDelete = async (category: OrderCategory) => {
    const confirmed = window.confirm(
      `Delete order category "${category.name}"? This action cannot be undone.`
    );
    if (!confirmed) return;

    try {
      await api.delete(`/order-categories/${category._id}`);
      setCategories((prev) => prev.filter((item) => item._id !== category._id));
    } catch (err: any) {
      console.error('Failed to delete category:', err);
      window.alert(err.response?.data?.message ?? 'Failed to delete category.');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Order Categories</h1>
          <p className="text-gray-600 mt-1">
            Create and manage reusable order categories for customer requests.
          </p>
        </div>
        <button
          onClick={() => openModal()}
          className="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md shadow-sm transition"
        >
          + Add Category
        </button>
      </div>

      <div className="bg-white shadow rounded-lg p-6 space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex-1">
            <label className="block text-sm font-medium text-gray-700">
              Search Categories
            </label>
            <input
              type="text"
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Search by name or description"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input
              type="checkbox"
              checked={showInactive}
              onChange={(event) => setShowInactive(event.target.checked)}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            Show inactive
          </label>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-100 text-red-600 px-4 py-3 rounded-md">
            {error}
          </div>
        )}

        {loading ? (
          <div className="text-center text-gray-500 py-8">Loading categories...</div>
        ) : filteredCategories.length === 0 ? (
          <div className="text-center text-gray-500 py-8">
            No categories found. Try adjusting your filters or add a new category.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Description
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredCategories.map((category) => (
                  <tr key={category._id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {category.name}
                    </td>
                    <td className="px-6 py-4 whitespace-pre-line text-sm text-gray-500 max-w-xs">
                      {category.description || '—'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          category.isActive
                            ? 'bg-green-100 text-green-800'
                            : 'bg-gray-100 text-gray-800'
                        }`}
                      >
                        {category.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                      <button
                        onClick={() => handleToggleStatus(category)}
                        className="text-blue-600 hover:text-blue-800"
                      >
                        {category.isActive ? 'Deactivate' : 'Activate'}
                      </button>
                      <button
                        onClick={() => openModal(category)}
                        className="text-gray-600 hover:text-gray-800"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDelete(category)}
                        className="text-red-600 hover:text-red-800"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-lg">
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900">
                {editingCategory ? 'Edit Category' : 'Add Category'}
              </h2>
              <button
                onClick={closeModal}
                className="text-gray-500 hover:text-gray-700"
                aria-label="Close"
              >
                ×
              </button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="px-6 py-4 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Name
                  </label>
                  <input
                    type="text"
                    value={formState.name}
                    onChange={(event) =>
                      setFormState((prev) => ({ ...prev, name: event.target.value }))
                    }
                    required
                    placeholder="e.g., Documents, Food Delivery"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Description
                    <span className="text-gray-400 text-xs"> (optional)</span>
                  </label>
                  <textarea
                    value={formState.description}
                    onChange={(event) =>
                      setFormState((prev) => ({
                        ...prev,
                        description: event.target.value,
                      }))
                    }
                    rows={3}
                    placeholder="Short description to help customers choose the right category"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div className="px-6 py-4 border-t border-gray-200 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={closeModal}
                  className="px-4 py-2 rounded-md text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200"
                  disabled={isSaving}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-md text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-60"
                  disabled={isSaving}
                >
                  {isSaving ? 'Saving...' : editingCategory ? 'Save Changes' : 'Create Category'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default OrderCategories;



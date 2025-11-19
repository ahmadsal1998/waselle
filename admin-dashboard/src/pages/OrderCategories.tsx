import { useState, useEffect } from 'react';
import { useOrderCategoriesManager } from '@/store/orderCategories/useOrderCategoriesManager';
import {
  Plus,
  Search,
  Edit,
  Trash2,
  Power,
  X,
  Check,
  FolderTree,
  AlertCircle,
  FileText,
} from 'lucide-react';

const OrderCategories = () => {
  const {
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
  } = useOrderCategoriesManager();

  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  // Show success message and clear after 3 seconds
  useEffect(() => {
    if (successMessage) {
      const timer = setTimeout(() => setSuccessMessage(null), 3000);
      return () => clearTimeout(timer);
    }
  }, [successMessage]);

  // Enhanced submit handler with success messages
  const handleSubmitWithFeedback = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFormError(null);

    if (!formState.name.trim()) {
      setFormError('Category name is required');
      return;
    }

    try {
      await handleSubmit(e);
      setSuccessMessage(
        editingCategory ? 'Category updated successfully!' : 'Category created successfully!'
      );
      setFormError(null);
    } catch (err) {
      setFormError('Failed to save category. Please try again.');
    }
  };

  return (
    <div className="space-y-6 page-transition">
      {/* Header */}
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Order Categories</h1>
          <p className="text-slate-600 mt-2">
            Create and manage reusable order categories for customer requests.
          </p>
        </div>
        <button
          onClick={() => {
            openModal();
            setFormError(null);
            setSuccessMessage(null);
          }}
          className="btn-primary flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          Add Category
        </button>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="card bg-green-50 border-green-200 p-4 flex items-center gap-3">
          <Check className="w-5 h-5 text-green-600 flex-shrink-0" />
          <p className="text-green-800 font-medium">{successMessage}</p>
          <button
            onClick={() => setSuccessMessage(null)}
            className="ml-auto text-green-600 hover:text-green-800"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Search and Filter Card */}
      <div className="card p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search by name or description..."
              className="input pl-10"
            />
          </div>
          <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
            <input
              type="checkbox"
              checked={showInactive}
              onChange={(e) => setShowInactive(e.target.checked)}
              className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
            />
            <span>Show inactive categories</span>
          </label>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="card bg-red-50 border-red-200 p-4 flex items-center gap-3">
          <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0" />
          <p className="text-red-800 text-sm">{error}</p>
        </div>
      )}

      {/* Categories List */}
      {isLoading ? (
        <div className="card p-12 text-center">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-slate-600">Loading categories...</p>
        </div>
      ) : filteredCategories.length === 0 ? (
        <div className="card p-12 text-center text-slate-500">
          <FolderTree className="w-16 h-16 mx-auto mb-4 text-slate-300" />
          <p className="text-lg font-medium mb-2">No categories found</p>
          <p className="text-sm">
            {searchTerm || showInactive
              ? 'Try adjusting your filters or add a new category.'
              : 'Get started by adding your first order category.'}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredCategories.map((category) => (
            <div
              key={category._id}
              className="card p-6 hover:shadow-lg transition-all duration-200"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3 flex-1">
                  <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center flex-shrink-0">
                    <FolderTree className="w-5 h-5 text-blue-600" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="text-lg font-semibold text-slate-900 truncate">
                      {category.name}
                    </h3>
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium mt-1 ${
                        category.isActive
                          ? 'bg-green-100 text-green-800'
                          : 'bg-slate-100 text-slate-700'
                      }`}
                    >
                      {category.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </div>
                </div>
              </div>

              {category.description && (
                <div className="mb-4">
                  <div className="flex items-start gap-2">
                    <FileText className="w-4 h-4 text-slate-400 mt-0.5 flex-shrink-0" />
                    <p className="text-sm text-slate-600 line-clamp-3">{category.description}</p>
                  </div>
                </div>
              )}

              <div className="flex items-center gap-2 pt-4 border-t border-slate-200">
                <button
                  onClick={() => {
                    openModal(category);
                    setFormError(null);
                  }}
                  className="flex-1 btn-secondary flex items-center justify-center gap-2"
                  title="Edit Category"
                >
                  <Edit className="w-4 h-4" />
                  Edit
                </button>
                <button
                  onClick={async () => {
                    await handleToggleStatus(category);
                  }}
                  className={`p-2 rounded-lg transition-colors ${
                    category.isActive
                      ? 'text-amber-600 hover:bg-amber-50'
                      : 'text-green-600 hover:bg-green-50'
                  }`}
                  title={category.isActive ? 'Deactivate' : 'Activate'}
                >
                  <Power className="w-4 h-4" />
                </button>
                <button
                  onClick={async () => {
                    if (
                      confirm(
                        `Are you sure you want to delete "${category.name}"? This action cannot be undone.`
                      )
                    ) {
                      await handleDelete(category);
                    }
                  }}
                  className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  title="Delete Category"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Category Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-lg">
            <div className="flex items-center justify-between p-6 border-b border-slate-200 bg-slate-50">
              <div className="flex items-center gap-3">
                <FolderTree className="w-6 h-6 text-blue-600" />
                <h2 className="text-xl font-semibold text-slate-900">
                  {editingCategory ? 'Edit Category' : 'Add New Category'}
                </h2>
              </div>
              <button
                onClick={() => {
                  closeModal();
                  setFormError(null);
                }}
                className="p-2 hover:bg-slate-200 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleSubmitWithFeedback} className="p-6 space-y-6">
              {/* Category Name */}
              <div>
                <label htmlFor="categoryName" className="block text-sm font-medium text-slate-700 mb-2">
                  Category Name *
                </label>
                <input
                  id="categoryName"
                  type="text"
                  value={formState.name}
                  onChange={(e) => {
                    setFormState((prev) => ({ ...prev, name: e.target.value }));
                    if (formError) setFormError(null);
                  }}
                  className={`input ${formError ? 'border-red-300 focus:ring-red-500' : ''}`}
                  placeholder="e.g., Documents, Food Delivery, Electronics"
                  autoFocus
                />
                {formError && (
                  <p className="mt-1 text-sm text-red-600 flex items-center gap-1">
                    <AlertCircle className="w-4 h-4" />
                    {formError}
                  </p>
                )}
              </div>

              {/* Description */}
              <div>
                <label htmlFor="categoryDescription" className="block text-sm font-medium text-slate-700 mb-2">
                  Description
                  <span className="text-slate-400 font-normal ml-1">(optional)</span>
                </label>
                <textarea
                  id="categoryDescription"
                  value={formState.description}
                  onChange={(e) =>
                    setFormState((prev) => ({
                      ...prev,
                      description: e.target.value,
                    }))
                  }
                  rows={4}
                  placeholder="Short description to help customers choose the right category..."
                  className="input resize-none"
                />
                <p className="mt-1 text-xs text-slate-500">
                  Provide a brief description to help customers understand what this category is for.
                </p>
              </div>

              {/* Form Actions */}
              <div className="flex justify-end gap-3 pt-4 border-t border-slate-200">
                <button
                  type="button"
                  onClick={() => {
                    closeModal();
                    setFormError(null);
                  }}
                  className="btn-secondary"
                  disabled={isSaving}
                >
                  Cancel
                </button>
                <button type="submit" className="btn-primary" disabled={isSaving}>
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

import { useState, useMemo } from 'react';
import { useDrivers } from '@/store/drivers/useDrivers';
import {
  createDriver,
  updateDriver,
  deleteDriver,
  resetDriverPassword,
  toggleDriverStatus,
  addDriverPayment,
  getDriverBalance,
  type CreateDriverData,
  type UpdateDriverData,
  type CreatePaymentData,
  type DriverBalanceInfo,
} from '@/services/driverService';
import {
  Plus,
  Search,
  Edit,
  Trash2,
  Key,
  Power,
  X,
  DollarSign,
} from 'lucide-react';
import type { Driver } from '@/types';

const Drivers = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Memoize filters to prevent unnecessary re-renders
  const filters = useMemo(
    () => ({
      search: searchTerm || undefined,
      status: statusFilter !== 'all' ? statusFilter : undefined,
    }),
    [searchTerm, statusFilter]
  );

  const { drivers, isLoading, error, refresh } = useDrivers(filters);

  const handleAddDriver = async (data: CreateDriverData) => {
    setIsSubmitting(true);
    try {
      await createDriver(data);
      await refresh();
      setShowAddModal(false);
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to create driver');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleUpdateDriver = async (data: UpdateDriverData) => {
    if (!selectedDriver) return;
    setIsSubmitting(true);
    try {
      await updateDriver(selectedDriver._id, data);
      await refresh();
      setShowEditModal(false);
      setSelectedDriver(null);
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to update driver');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteDriver = async (driverId: string) => {
    if (!confirm('Are you sure you want to delete this driver?')) return;
    try {
      await deleteDriver(driverId);
      await refresh();
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to delete driver');
    }
  };

  const handleResetPassword = async (driverId: string, newPassword: string) => {
    setIsSubmitting(true);
    try {
      await resetDriverPassword(driverId, newPassword);
      setShowPasswordModal(false);
      setSelectedDriver(null);
      alert('Password reset successfully');
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to reset password');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleStatus = async (driverId: string) => {
    try {
      await toggleDriverStatus(driverId);
      await refresh();
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to toggle driver status');
    }
  };

  const handleAddPayment = async (data: CreatePaymentData) => {
    if (!selectedDriver) return;
    setIsSubmitting(true);
    try {
      const result = await addDriverPayment(selectedDriver._id, data);
      await refresh();
      setShowPaymentModal(false);
      setSelectedDriver(null);
      
      // Show appropriate message based on reactivation status
      if (result.suspensionStatus.reactivated) {
        alert('Payment added successfully! Driver account has been automatically reactivated (balance cleared).');
      } else if (result.suspensionStatus.suspended) {
        alert('Payment added successfully. Driver account remains suspended (balance still exceeds limit).');
      } else {
        alert('Payment added successfully');
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to add payment');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="text-center py-12">
        <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        <p className="mt-4 text-slate-600">Loading drivers...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-4 page-transition">
        <h1 className="text-3xl font-bold text-slate-900">Drivers Management</h1>
        <div className="card bg-red-50 border-red-200 text-red-700 px-4 py-3">
          {error}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 page-transition">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Drivers Management</h1>
          <p className="mt-2 text-slate-600">Manage driver accounts and permissions</p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="btn-primary flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          Add Driver
        </button>
      </div>

      {/* Search and Filter */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, email, or phone..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input pl-10"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as 'all' | 'active' | 'inactive')}
            className="input w-full sm:w-48"
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
      </div>

      {/* Drivers Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Driver
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Contact
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Vehicle
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Balance
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Availability
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-slate-200">
              {drivers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-500">
                    No drivers found
                  </td>
                </tr>
              ) : (
                drivers.map((driver) => (
                  <tr key={driver._id} className="hover:bg-slate-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center text-white font-semibold">
                          {driver.name.charAt(0).toUpperCase()}
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-slate-900">{driver.name}</div>
                          {driver.createdAt && (
                            <div className="text-xs text-slate-500">
                              Joined {new Date(driver.createdAt).toLocaleDateString()}
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-900">{driver.email || 'N/A'}</div>
                      {driver.phone && (
                        <div className="text-xs text-slate-500">{driver.phone}</div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                        {driver.vehicleType ? driver.vehicleType.charAt(0).toUpperCase() + driver.vehicleType.slice(1) : 'N/A'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex flex-col">
                        <span
                          className={`text-sm font-medium ${
                            driver.balanceExceeded
                              ? 'text-red-600'
                              : typeof driver.balance === 'number' && driver.balance >= 0
                              ? 'text-slate-900'
                              : 'text-green-600'
                          }`}
                        >
                          {typeof driver.balance === 'number'
                            ? `${driver.balance >= 0 ? '+' : ''}${driver.balance.toFixed(2)} NIS`
                            : 'N/A'}
                        </span>
                        {driver.maxAllowedBalance && (
                          <span className="text-xs text-slate-500">
                            Limit: {driver.maxAllowedBalance} NIS
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex flex-col gap-1">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            driver.isActive !== false
                              ? 'bg-green-100 text-green-800'
                              : 'bg-red-100 text-red-800'
                          }`}
                        >
                          {driver.isActive !== false ? 'Active' : 'Suspended'}
                        </span>
                        {driver.suspensionReason && (
                          <span className="text-xs text-red-600 font-medium">
                            {driver.suspensionReason}
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          driver.isAvailable
                            ? 'bg-blue-100 text-blue-800'
                            : 'bg-gray-100 text-gray-800'
                        }`}
                      >
                        {driver.isAvailable ? 'Available' : 'Offline'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => {
                            setSelectedDriver(driver);
                            setShowPaymentModal(true);
                          }}
                          className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                          title="Add Payment"
                        >
                          <DollarSign className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => {
                            setSelectedDriver(driver);
                            setShowEditModal(true);
                          }}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Edit"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => {
                            setSelectedDriver(driver);
                            setShowPasswordModal(true);
                          }}
                          className="p-2 text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                          title="Reset Password"
                        >
                          <Key className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleToggleStatus(driver._id)}
                          className={`p-2 rounded-lg transition-colors ${
                            driver.isActive !== false
                              ? 'text-red-600 hover:bg-red-50'
                              : 'text-green-600 hover:bg-green-50'
                          }`}
                          title={driver.isActive !== false ? 'Deactivate' : 'Activate'}
                        >
                          <Power className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDeleteDriver(driver._id)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Delete"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Driver Modal */}
      {showAddModal && (
        <DriverModal
          onClose={() => setShowAddModal(false)}
          onSubmit={handleAddDriver as (data: CreateDriverData | UpdateDriverData) => Promise<void>}
          isSubmitting={isSubmitting}
        />
      )}

      {/* Edit Driver Modal */}
      {showEditModal && selectedDriver && (
        <DriverModal
          driver={selectedDriver}
          onClose={() => {
            setShowEditModal(false);
            setSelectedDriver(null);
          }}
          onSubmit={handleUpdateDriver}
          isSubmitting={isSubmitting}
        />
      )}

      {/* Reset Password Modal */}
      {showPasswordModal && selectedDriver && (
        <PasswordModal
          driver={selectedDriver}
          onClose={() => {
            setShowPasswordModal(false);
            setSelectedDriver(null);
          }}
          onSubmit={(password) => handleResetPassword(selectedDriver._id, password)}
          isSubmitting={isSubmitting}
        />
      )}

      {/* Add Payment Modal */}
      {showPaymentModal && selectedDriver && (
        <PaymentModal
          driver={selectedDriver}
          onClose={() => {
            setShowPaymentModal(false);
            setSelectedDriver(null);
          }}
          onSubmit={handleAddPayment}
          isSubmitting={isSubmitting}
        />
      )}
    </div>
  );
};

// Driver Form Modal Component
interface DriverModalProps {
  driver?: Driver;
  onClose: () => void;
  onSubmit: (data: CreateDriverData | UpdateDriverData) => Promise<void>;
  isSubmitting: boolean;
}

const DriverModal = ({ driver, onClose, onSubmit, isSubmitting }: DriverModalProps) => {
  const [formData, setFormData] = useState<CreateDriverData>({
    name: driver?.name || '',
    email: driver?.email || '',
    phone: driver?.phone || '',
    password: '',
    vehicleType: (driver?.vehicleType as 'car' | 'bike' | 'cargo') || 'car',
    isActive: driver?.isActive !== undefined ? driver.isActive : true,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (driver) {
      // Update mode - don't send password if empty
      const updateData: UpdateDriverData = {
        name: formData.name,
        email: formData.email || undefined,
        phone: formData.phone || undefined,
        vehicleType: formData.vehicleType,
        isActive: formData.isActive,
      };
      await onSubmit(updateData);
    } else {
      // Create mode - validate required fields
      if (!formData.email) {
        alert('Email is required');
        return;
      }
      if (!formData.phone) {
        alert('Phone number is required');
        return;
      }
      if (!formData.password || formData.password.length < 6) {
        alert('Password is required and must be at least 6 characters');
        return;
      }
      await onSubmit(formData);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b border-slate-200">
          <h2 className="text-xl font-semibold text-slate-900">
            {driver ? 'Edit Driver' : 'Add New Driver'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Full Name *
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="input"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Email *
            </label>
            <input
              type="email"
              required={!driver}
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              className="input"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Phone Number *
            </label>
            <input
              type="tel"
              required={!driver}
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              className="input"
            />
          </div>
          {!driver && (
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Password *
              </label>
              <input
                type="password"
                required
                minLength={6}
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                className="input"
                placeholder="Minimum 6 characters"
              />
              <p className="mt-1 text-xs text-slate-500">Password must be at least 6 characters</p>
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Vehicle Type *
            </label>
            <select
              required
              value={formData.vehicleType}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  vehicleType: e.target.value as 'car' | 'bike' | 'cargo',
                })
              }
              className="input"
            >
              <option value="car">Car</option>
              <option value="bike">Bike</option>
              <option value="cargo">Cargo</option>
            </select>
          </div>
          <div>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={formData.isActive}
                onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-sm font-medium text-slate-700">Active Account</span>
            </label>
          </div>
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary flex-1"
              disabled={isSubmitting}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn-primary flex-1"
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Saving...' : driver ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// Password Reset Modal
interface PasswordModalProps {
  driver: Driver;
  onClose: () => void;
  onSubmit: (password: string) => Promise<void>;
  isSubmitting: boolean;
}

const PasswordModal = ({ driver, onClose, onSubmit, isSubmitting }: PasswordModalProps) => {
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password.length < 6) {
      alert('Password must be at least 6 characters');
      return;
    }
    if (password !== confirmPassword) {
      alert('Passwords do not match');
      return;
    }
    await onSubmit(password);
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
        <div className="flex items-center justify-between p-6 border-b border-slate-200">
          <h2 className="text-xl font-semibold text-slate-900">
            Reset Password for {driver.name}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              New Password *
            </label>
            <input
              type="password"
              required
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="input"
              placeholder="Minimum 6 characters"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Confirm Password *
            </label>
            <input
              type="password"
              required
              minLength={6}
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="input"
              placeholder="Re-enter password"
            />
          </div>
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary flex-1"
              disabled={isSubmitting}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn-primary flex-1"
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Resetting...' : 'Reset Password'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// Payment Modal Component
interface PaymentModalProps {
  driver: Driver;
  onClose: () => void;
  onSubmit: (data: CreatePaymentData) => Promise<void>;
  isSubmitting: boolean;
}

const PaymentModal = ({ driver, onClose, onSubmit, isSubmitting }: PaymentModalProps) => {
  const [amount, setAmount] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [notes, setNotes] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const paymentAmount = parseFloat(amount);
    if (isNaN(paymentAmount) || paymentAmount <= 0) {
      alert('Please enter a valid payment amount');
      return;
    }
    await onSubmit({
      amount: paymentAmount,
      date,
      notes: notes.trim() || undefined,
    });
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
        <div className="flex items-center justify-between p-6 border-b border-slate-200">
          <h2 className="text-xl font-semibold text-slate-900">
            Add Payment for {driver.name}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Payment Amount (NIS) *
            </label>
            <input
              type="number"
              required
              min="0.01"
              step="0.01"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="input"
              placeholder="0.00"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Date *
            </label>
            <input
              type="date"
              required
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="input"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Notes (Optional)
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="input"
              rows={3}
              placeholder="Payment notes..."
            />
          </div>
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary flex-1"
              disabled={isSubmitting}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn-primary flex-1"
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Adding...' : 'Add Payment'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Drivers;

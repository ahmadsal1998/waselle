import { useState, useEffect } from 'react';
import { useDrivers } from '@/store/drivers/useDrivers';
import { getDriverBalance, getDriverPayments, type DriverBalanceInfo, type Payment } from '@/services/driverService';
import { formatCurrency, formatDate } from '@/utils/formatters';
import {
  Search,
  DollarSign,
  TrendingUp,
  TrendingDown,
  AlertCircle,
  CheckCircle,
  RefreshCw,
} from 'lucide-react';
import type { Driver } from '@/types';

const DriverBalance = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [balanceInfo, setBalanceInfo] = useState<DriverBalanceInfo | null>(null);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { drivers, isLoading: driversLoading, refresh } = useDrivers({});

  const filteredDrivers = drivers.filter((driver) =>
    driver.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    driver.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    driver.phone?.includes(searchTerm)
  );

  const loadDriverBalance = async (driverId: string) => {
    setLoading(true);
    setError(null);
    try {
      const [balance, driverPayments] = await Promise.all([
        getDriverBalance(driverId),
        getDriverPayments(driverId),
      ]);
      setBalanceInfo(balance);
      setPayments(driverPayments);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load driver balance');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (selectedDriver) {
      loadDriverBalance(selectedDriver._id);
    } else {
      setBalanceInfo(null);
      setPayments([]);
    }
  }, [selectedDriver]);

  const handleRefresh = () => {
    if (selectedDriver) {
      loadDriverBalance(selectedDriver._id);
      refresh();
    }
  };

  if (driversLoading) {
    return (
      <div className="text-center py-12">
        <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        <p className="mt-4 text-slate-600">Loading drivers...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 page-transition">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Driver Balance</h1>
          <p className="mt-2 text-slate-600">View driver financial details and balance information</p>
        </div>
        {selectedDriver && (
          <button
            onClick={handleRefresh}
            className="btn-secondary flex items-center gap-2"
            disabled={loading}
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Drivers List */}
        <div className="lg:col-span-1">
          <div className="card p-4">
            <div className="relative mb-4">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
              <input
                type="text"
                placeholder="Search drivers..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="input pl-10"
              />
            </div>
            <div className="space-y-2 max-h-[600px] overflow-y-auto">
              {filteredDrivers.length === 0 ? (
                <p className="text-sm text-slate-500 text-center py-4">No drivers found</p>
              ) : (
                filteredDrivers.map((driver) => (
                  <button
                    key={driver._id}
                    onClick={() => setSelectedDriver(driver)}
                    className={`w-full text-left p-3 rounded-lg transition-colors ${
                      selectedDriver?._id === driver._id
                        ? 'bg-blue-50 border-2 border-blue-500'
                        : 'bg-slate-50 hover:bg-slate-100 border-2 border-transparent'
                    }`}
                  >
                    <div className="font-medium text-slate-900">{driver.name}</div>
                    <div className="text-xs text-slate-500 mt-1">
                      {driver.email || driver.phone || 'N/A'}
                    </div>
                  </button>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Balance Information */}
        <div className="lg:col-span-2">
          {!selectedDriver ? (
            <div className="card p-12 text-center">
              <DollarSign className="w-16 h-16 mx-auto text-slate-300 mb-4" />
              <p className="text-slate-600">Select a driver to view balance information</p>
            </div>
          ) : loading ? (
            <div className="card p-12 text-center">
              <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
              <p className="mt-4 text-slate-600">Loading balance information...</p>
            </div>
          ) : error ? (
            <div className="card bg-red-50 border-red-200 p-4">
              <p className="text-red-800">{error}</p>
            </div>
          ) : balanceInfo ? (
            <div className="space-y-6">
              {/* Balance Summary Cards */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="card p-6">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="text-sm font-medium text-slate-600">Total Delivery Revenue</h3>
                    <TrendingUp className="w-5 h-5 text-green-500" />
                  </div>
                  <p className="text-2xl font-bold text-slate-900">
                    {formatCurrency(balanceInfo.totalDeliveryRevenue)}
                  </p>
                </div>

                <div className="card p-6">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="text-sm font-medium text-slate-600">Commission Percentage</h3>
                    <DollarSign className="w-5 h-5 text-blue-500" />
                  </div>
                  <p className="text-2xl font-bold text-slate-900">
                    {balanceInfo.commissionPercentage}%
                  </p>
                </div>

                <div className="card p-6">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="text-sm font-medium text-slate-600">Total Commission Owed</h3>
                    <TrendingDown className="w-5 h-5 text-amber-500" />
                  </div>
                  <p className="text-2xl font-bold text-slate-900">
                    {formatCurrency(balanceInfo.totalCommissionOwed)}
                  </p>
                </div>

                <div className="card p-6">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="text-sm font-medium text-slate-600">Total Payments Made</h3>
                    <CheckCircle className="w-5 h-5 text-green-500" />
                  </div>
                  <p className="text-2xl font-bold text-slate-900">
                    {formatCurrency(balanceInfo.totalPaymentsMade)}
                  </p>
                </div>
              </div>

              {/* Current Balance */}
              <div className="card p-6">
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-xl font-semibold text-slate-900">Current Balance</h2>
                  <div
                    className={`flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium ${
                      balanceInfo.currentBalance >= 0
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}
                  >
                    {balanceInfo.isSuspended ? (
                      <>
                        <AlertCircle className="w-4 h-4" />
                        Suspended
                      </>
                    ) : (
                      <>
                        <CheckCircle className="w-4 h-4" />
                        Active
                      </>
                    )}
                  </div>
                </div>
                <div className="text-center">
                  <p className="text-4xl font-bold text-slate-900 mb-2">
                    {formatCurrency(balanceInfo.currentBalance)}
                  </p>
                  <p className="text-sm text-slate-600">
                    {balanceInfo.currentBalance >= 0
                      ? 'Driver owes this amount to admin'
                      : 'Driver has overpaid (credit balance)'}
                  </p>
                </div>
              </div>

              {/* Payment History */}
              <div className="card p-6">
                <h2 className="text-xl font-semibold text-slate-900 mb-4">Payment History</h2>
                {payments.length === 0 ? (
                  <p className="text-sm text-slate-500 text-center py-4">No payments recorded</p>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-slate-200">
                      <thead className="bg-slate-50">
                        <tr>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">
                            Date
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">
                            Amount
                          </th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">
                            Notes
                          </th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-slate-200">
                        {payments.map((payment) => (
                          <tr key={payment._id} className="hover:bg-slate-50">
                            <td className="px-4 py-3 whitespace-nowrap text-sm text-slate-900">
                              {formatDate(payment.date)}
                            </td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm font-medium text-green-600">
                              {formatCurrency(payment.amount)}
                            </td>
                            <td className="px-4 py-3 text-sm text-slate-600">
                              {payment.notes || '-'}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
};

export default DriverBalance;


import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { useDashboardStats } from '@/store/dashboard/useDashboardStats';

const Dashboard = () => {
  const { stats, isLoading, error } = useDashboardStats();

  if (isLoading) {
    return (
      <div className="text-center py-12">
        <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        <p className="mt-4 text-slate-600">Loading dashboard data...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-4 page-transition">
        <h1 className="text-3xl font-bold text-slate-900">Dashboard Overview</h1>
        <div className="card bg-red-50 border-red-200 text-red-700 px-4 py-3">
          {error}
        </div>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="text-center py-12">
        <p className="text-slate-600">No data available</p>
      </div>
    );
  }

  const chartData = [
    { name: 'Pending', value: stats.pendingOrders, color: '#f59e0b' },
    { name: 'Active', value: stats.activeOrders, color: '#3b82f6' },
    { name: 'Completed', value: stats.completedOrders, color: '#10b981' },
  ];

  return (
    <div className="space-y-6 page-transition">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Dashboard Overview</h1>
        <p className="mt-2 text-slate-600">Welcome back! Here's what's happening today.</p>
      </div>

      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <div className="card overflow-hidden">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-12 h-12 rounded-lg bg-blue-100 flex items-center justify-center">
                  <span className="text-2xl">👥</span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-slate-500 truncate">Total Users</dt>
                  <dd className="text-lg font-semibold text-slate-900">{stats.totalUsers}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="card overflow-hidden">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-12 h-12 rounded-lg bg-green-100 flex items-center justify-center">
                  <span className="text-2xl">🚗</span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-slate-500 truncate">Total Drivers</dt>
                  <dd className="text-lg font-semibold text-slate-900">{stats.totalDrivers}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="card overflow-hidden">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-12 h-12 rounded-lg bg-purple-100 flex items-center justify-center">
                  <span className="text-2xl">📦</span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-slate-500 truncate">Total Orders</dt>
                  <dd className="text-lg font-semibold text-slate-900">{stats.totalOrders}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="card overflow-hidden">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-12 h-12 rounded-lg bg-amber-100 flex items-center justify-center">
                  <span className="text-2xl">⚡</span>
                </div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-slate-500 truncate">Active Orders</dt>
                  <dd className="text-lg font-semibold text-slate-900">{stats.activeOrders}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card p-6">
          <h2 className="text-xl font-semibold mb-4 text-slate-900">Orders Status</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={chartData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {chartData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div className="card p-6">
          <h2 className="text-xl font-semibold mb-4 text-slate-900">Orders Overview</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
              <XAxis dataKey="name" stroke="#64748b" />
              <YAxis stroke="#64748b" />
              <Tooltip />
              <Legend />
              <Bar dataKey="value" fill="#3b82f6" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;

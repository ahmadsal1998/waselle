import { useEffect, useState } from 'react';
import { api } from '../config/api';
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

interface Stats {
  totalUsers: number;
  totalDrivers: number;
  totalOrders: number;
  activeOrders: number;
  completedOrders: number;
  pendingOrders: number;
}

type UserRole = 'customer' | 'driver' | 'admin';

interface ApiUser {
  role: UserRole | string;
}

type OrderStatus = 'pending' | 'accepted' | 'on_the_way' | 'delivered' | 'cancelled';

interface ApiOrder {
  status: OrderStatus | string;
}

const isAllowedStatus = (
  status: ApiOrder['status'],
  allowed: readonly OrderStatus[]
): status is OrderStatus =>
  typeof status === 'string' && allowed.includes(status as OrderStatus);

const Dashboard = () => {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const [usersRes, ordersRes] = await Promise.all([
        api.get<{ users: ApiUser[] }>('/users'),
        api.get<{ orders: ApiOrder[] }>('/orders'),
      ]);

      const users = usersRes.data.users ?? [];
      const orders = ordersRes.data.orders ?? [];

      const activeStatuses: readonly OrderStatus[] = ['accepted', 'on_the_way'];
      const completedStatuses: readonly OrderStatus[] = ['delivered'];
      const pendingStatuses: readonly OrderStatus[] = ['pending'];

      const statsData: Stats = {
        totalUsers: users.filter((user) => user.role === 'customer').length,
        totalDrivers: users.filter((user) => user.role === 'driver').length,
        totalOrders: orders.length,
        activeOrders: orders.filter(
          (order) => isAllowedStatus(order.status, activeStatuses)
        ).length,
        completedOrders: orders.filter(
          (order) => isAllowedStatus(order.status, completedStatuses)
        ).length,
        pendingOrders: orders.filter(
          (order) => isAllowedStatus(order.status, pendingStatuses)
        ).length,
      };

      setStats(statsData);
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  if (!stats) {
    return <div className="text-center py-12">No data available</div>;
  }

  const chartData = [
    { name: 'Pending', value: stats.pendingOrders, color: '#f59e0b' },
    { name: 'Active', value: stats.activeOrders, color: '#3b82f6' },
    { name: 'Completed', value: stats.completedOrders, color: '#10b981' },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">Dashboard Overview</h1>

      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="text-3xl">👥</div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total Users
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {stats.totalUsers}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="text-3xl">🚗</div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total Drivers
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {stats.totalDrivers}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="text-3xl">📦</div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total Orders
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {stats.totalOrders}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="text-3xl">⚡</div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Active Orders
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {stats.activeOrders}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">Orders Status</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={chartData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) =>
                  `${name} ${(percent * 100).toFixed(0)}%`
                }
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

        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">Orders Overview</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="value" fill="#3b82f6" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;

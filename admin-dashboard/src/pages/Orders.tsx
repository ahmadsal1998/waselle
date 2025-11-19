import { useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useOrders } from '@/store/orders/useOrders';
import { getOrderStatusBadgeClass } from '@/utils/status';
import { formatCurrency, formatDate } from '@/utils/formatters';
import {
  Search,
  Filter,
  ChevronUp,
  ChevronDown,
  Eye,
  Edit,
  Trash2,
  RefreshCw,
  Download,
  Grid3x3,
  List,
  X,
  Check,
} from 'lucide-react';
import type { Order, OrderStatus, OrderType } from '@/types';

type SortField = 'createdAt' | 'estimatedPrice' | 'price' | 'status' | 'type';
type SortDirection = 'asc' | 'desc' | null;
type ViewMode = 'table' | 'grid';

// Get status icon helper function
const getStatusIcon = (status: string) => {
  const icons: Record<string, string> = {
    pending: '⏳',
    accepted: '✅',
    on_the_way: '🚗',
    delivered: '📦',
    cancelled: '❌',
  };
  return icons[status] || '📋';
};

const Orders = () => {
  const { orders, isLoading, error, refresh } = useOrders();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<OrderStatus | 'all'>('all');
  const [typeFilter, setTypeFilter] = useState<OrderType | 'all'>('all');
  const [vehicleFilter, setVehicleFilter] = useState<'car' | 'bike' | 'all'>('all');
  const [sortField, setSortField] = useState<SortField | null>(null);
  const [sortDirection, setSortDirection] = useState<SortDirection>(null);
  const [viewMode, setViewMode] = useState<ViewMode>('table');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);

  // Filter orders
  const filteredOrders = useMemo(() => {
    return orders.filter((order) => {
      const matchesSearch =
        !searchTerm ||
        order._id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.customerId?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.driverId?.name?.toLowerCase().includes(searchTerm.toLowerCase());

      const matchesStatus = statusFilter === 'all' || order.status === statusFilter;
      const matchesType = typeFilter === 'all' || order.type === typeFilter;
      const matchesVehicle =
        vehicleFilter === 'all' || order.vehicleType === vehicleFilter;

      return matchesSearch && matchesStatus && matchesType && matchesVehicle;
    });
  }, [orders, searchTerm, statusFilter, typeFilter, vehicleFilter]);

  // Sort orders
  const sortedOrders = useMemo(() => {
    if (!sortField || !sortDirection) return filteredOrders;

    return [...filteredOrders].sort((a, b) => {
      let aValue: any;
      let bValue: any;

      switch (sortField) {
        case 'createdAt':
          aValue = new Date(a.createdAt).getTime();
          bValue = new Date(b.createdAt).getTime();
          break;
        case 'estimatedPrice':
          aValue = a.estimatedPrice ?? 0;
          bValue = b.estimatedPrice ?? 0;
          break;
        case 'price':
          aValue = a.price ?? 0;
          bValue = b.price ?? 0;
          break;
        case 'status':
          aValue = a.status;
          bValue = b.status;
          break;
        case 'type':
          aValue = a.type;
          bValue = b.type;
          break;
        default:
          return 0;
      }

      if (aValue < bValue) return sortDirection === 'asc' ? -1 : 1;
      if (aValue > bValue) return sortDirection === 'asc' ? 1 : -1;
      return 0;
    });
  }, [filteredOrders, sortField, sortDirection]);

  // Paginate orders
  const paginatedOrders = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    return sortedOrders.slice(startIndex, startIndex + itemsPerPage);
  }, [sortedOrders, currentPage, itemsPerPage]);

  const totalPages = Math.ceil(sortedOrders.length / itemsPerPage);

  // Handle sorting
  const handleSort = (field: SortField) => {
    if (sortField === field) {
      if (sortDirection === 'asc') {
        setSortDirection('desc');
      } else if (sortDirection === 'desc') {
        setSortField(null);
        setSortDirection(null);
      } else {
        setSortDirection('asc');
      }
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  // Get sort icon
  const getSortIcon = (field: SortField) => {
    if (sortField !== field) return null;
    return sortDirection === 'asc' ? (
      <ChevronUp className="w-4 h-4 inline ml-1" />
    ) : (
      <ChevronDown className="w-4 h-4 inline ml-1" />
    );
  };

  // Export to CSV
  const handleExportCSV = () => {
    const headers = [
      'Order ID',
      'Customer',
      'Driver',
      'Type',
      'Vehicle',
      'Est. Cost',
      'Status',
      'Price',
      'Created',
    ];
    const rows = sortedOrders.map((order) => [
      order._id,
      order.customerId?.name || 'Unknown',
      order.driverId?.name || 'N/A',
      order.type,
      order.vehicleType || 'N/A',
      order.estimatedPrice?.toString() || '0',
      order.status,
      order.price?.toString() || '0',
      formatDate(order.createdAt, ''),
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map((row) => row.map((cell) => `"${cell}"`).join(',')),
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `orders_${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  };

  // Handle status update
  const handleStatusUpdate = async (orderId: string, newStatus: OrderStatus) => {
    // TODO: Implement API call to update order status
    console.log('Update order status:', orderId, newStatus);
    await refresh();
    setShowStatusModal(false);
    setSelectedOrder(null);
  };

  // Handle delete
  const handleDelete = async (orderId: string) => {
    // TODO: Implement API call to delete order
    console.log('Delete order:', orderId);
    await refresh();
    setShowDeleteModal(false);
    setSelectedOrder(null);
  };


  if (isLoading) {
    return (
      <div className="text-center py-12">
        <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        <p className="mt-4 text-slate-600">Loading orders...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-4 page-transition">
        <h1 className="text-3xl font-bold text-slate-900">Orders Management</h1>
        <div className="card bg-red-50 border-red-200 text-red-700 px-4 py-3">
          {error}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 page-transition">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Orders Management</h1>
          <p className="mt-2 text-slate-600">
            {sortedOrders.length} order{sortedOrders.length !== 1 ? 's' : ''} found
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleExportCSV}
            className="btn-secondary flex items-center gap-2"
            title="Export to CSV"
          >
            <Download className="w-4 h-4" />
            <span className="hidden sm:inline">Export CSV</span>
          </button>
          <button
            onClick={() => refresh()}
            className="btn-secondary flex items-center gap-2"
            title="Refresh"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
          <div className="flex items-center gap-1 border border-slate-300 rounded-lg overflow-hidden">
            <button
              onClick={() => setViewMode('table')}
              className={`p-2 ${viewMode === 'table' ? 'bg-blue-600 text-white' : 'bg-white text-slate-700 hover:bg-slate-50'}`}
              title="Table View"
            >
              <List className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 ${viewMode === 'grid' ? 'bg-blue-600 text-white' : 'bg-white text-slate-700 hover:bg-slate-50'}`}
              title="Grid View"
            >
              <Grid3x3 className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="card p-4">
        <div className="space-y-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <input
              type="text"
              placeholder="Search by Order ID, Customer, or Driver..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="input pl-10"
            />
          </div>

          {/* Filters */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                <Filter className="w-4 h-4 inline mr-1" />
                Status
              </label>
              <select
                value={statusFilter}
                onChange={(e) => {
                  setStatusFilter(e.target.value as OrderStatus | 'all');
                  setCurrentPage(1);
                }}
                className="input"
              >
                <option value="all">All Status</option>
                <option value="pending">Pending</option>
                <option value="accepted">Accepted</option>
                <option value="on_the_way">On The Way</option>
                <option value="delivered">Delivered</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Type
              </label>
              <select
                value={typeFilter}
                onChange={(e) => {
                  setTypeFilter(e.target.value as OrderType | 'all');
                  setCurrentPage(1);
                }}
                className="input"
              >
                <option value="all">All Types</option>
                <option value="send">Send</option>
                <option value="receive">Receive</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Vehicle
              </label>
              <select
                value={vehicleFilter}
                onChange={(e) => {
                  setVehicleFilter(e.target.value as 'car' | 'bike' | 'all');
                  setCurrentPage(1);
                }}
                className="input"
              >
                <option value="all">All Vehicles</option>
                <option value="car">Car</option>
                <option value="bike">Bike</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Table View */}
      {viewMode === 'table' && (
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th
                    className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider cursor-pointer hover:bg-slate-100"
                    onClick={() => handleSort('createdAt')}
                  >
                    Order ID {getSortIcon('createdAt')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Customer
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Driver
                  </th>
                  <th
                    className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider cursor-pointer hover:bg-slate-100"
                    onClick={() => handleSort('type')}
                  >
                    Type {getSortIcon('type')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Vehicle
                  </th>
                  <th
                    className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider cursor-pointer hover:bg-slate-100"
                    onClick={() => handleSort('estimatedPrice')}
                  >
                    Est. Cost {getSortIcon('estimatedPrice')}
                  </th>
                  <th
                    className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider cursor-pointer hover:bg-slate-100"
                    onClick={() => handleSort('status')}
                  >
                    Status {getSortIcon('status')}
                  </th>
                  <th
                    className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider cursor-pointer hover:bg-slate-100"
                    onClick={() => handleSort('price')}
                  >
                    Price {getSortIcon('price')}
                  </th>
                  <th
                    className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider cursor-pointer hover:bg-slate-100"
                    onClick={() => handleSort('createdAt')}
                  >
                    Created {getSortIcon('createdAt')}
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-slate-200">
                {paginatedOrders.length === 0 ? (
                  <tr>
                    <td colSpan={10} className="px-6 py-12 text-center text-slate-500">
                      No orders found
                    </td>
                  </tr>
                ) : (
                  paginatedOrders.map((order) => (
                    <OrderTableRow
                      key={order._id}
                      order={order}
                      onView={() => {}}
                      onEdit={() => {}}
                      onDelete={() => {
                        setSelectedOrder(order);
                        setShowDeleteModal(true);
                      }}
                      onUpdateStatus={() => {
                        setSelectedOrder(order);
                        setShowStatusModal(true);
                      }}
                    />
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Grid View */}
      {viewMode === 'grid' && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {paginatedOrders.length === 0 ? (
            <div className="col-span-full text-center py-12 text-slate-500">
              No orders found
            </div>
          ) : (
            paginatedOrders.map((order) => (
              <OrderCard
                key={order._id}
                order={order}
                onView={() => {}}
                onEdit={() => {}}
                onDelete={() => {
                  setSelectedOrder(order);
                  setShowDeleteModal(true);
                }}
                onUpdateStatus={() => {
                  setSelectedOrder(order);
                  setShowStatusModal(true);
                }}
              />
            ))
          )}
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between card p-4">
          <div className="text-sm text-slate-600">
            Showing {(currentPage - 1) * itemsPerPage + 1} to{' '}
            {Math.min(currentPage * itemsPerPage, sortedOrders.length)} of{' '}
            {sortedOrders.length} orders
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="btn-secondary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            {Array.from({ length: totalPages }, (_, i) => i + 1)
              .filter(
                (page) =>
                  page === 1 ||
                  page === totalPages ||
                  (page >= currentPage - 1 && page <= currentPage + 1)
              )
              .map((page, index, array) => (
                <div key={page} className="flex items-center gap-2">
                  {index > 0 && array[index - 1] !== page - 1 && (
                    <span className="px-2">...</span>
                  )}
                  <button
                    onClick={() => setCurrentPage(page)}
                    className={`px-4 py-2 rounded-lg ${
                      currentPage === page
                        ? 'bg-blue-600 text-white'
                        : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                    }`}
                  >
                    {page}
                  </button>
                </div>
              ))}
            <button
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
              className="btn-secondary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </div>
        </div>
      )}

      {/* Status Update Modal */}
      {showStatusModal && selectedOrder && (
        <StatusModal
          order={selectedOrder}
          onClose={() => {
            setShowStatusModal(false);
            setSelectedOrder(null);
          }}
          onUpdate={handleStatusUpdate}
        />
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteModal && selectedOrder && (
        <DeleteModal
          order={selectedOrder}
          onClose={() => {
            setShowDeleteModal(false);
            setSelectedOrder(null);
          }}
          onConfirm={handleDelete}
        />
      )}
    </div>
  );
};

// Table Row Component
interface OrderTableRowProps {
  order: Order;
  onView: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onUpdateStatus: () => void;
}

const OrderTableRow = ({
  order,
  onView,
  onEdit,
  onDelete,
  onUpdateStatus,
}: OrderTableRowProps) => {
  const priceDiff = order.price && order.estimatedPrice
    ? order.price - order.estimatedPrice
    : null;

  return (
    <tr className="hover:bg-slate-50">
      <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-slate-900">
        {order._id.substring(0, 8)}...
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
        {order.customerId?.name ?? 'Unknown'}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
        {order.driverId?.name ?? 'N/A'}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900 capitalize">
        {order.type}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900 capitalize">
        {order.vehicleType ?? 'N/A'}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
        {formatCurrency(order.estimatedPrice)}
      </td>
      <td className="px-6 py-4 whitespace-nowrap">
        <span
          className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium ${getOrderStatusBadgeClass(
            order.status
          )}`}
        >
          <span>{getStatusIcon(order.status)}</span>
          {order.status.replace('_', ' ')}
        </span>
      </td>
      <td className="px-6 py-4 whitespace-nowrap">
        <div className="text-sm text-slate-900">
          {formatCurrency(order.price)}
          {priceDiff !== null && (
            <span
              className={`ml-2 text-xs ${
                priceDiff > 0 ? 'text-red-600' : priceDiff < 0 ? 'text-green-600' : 'text-slate-500'
              }`}
            >
              ({priceDiff > 0 ? '+' : ''}{formatCurrency(priceDiff)})
            </span>
          )}
        </div>
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
        {formatDate(order.createdAt, 'N/A')}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
        <div className="flex items-center justify-end gap-2">
          <Link
            to={`/orders/${order._id}`}
            className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
            title="View Details"
          >
            <Eye className="w-4 h-4" />
          </Link>
          <button
            onClick={onEdit}
            className="p-2 text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
            title="Edit Order"
          >
            <Edit className="w-4 h-4" />
          </button>
          <button
            onClick={onUpdateStatus}
            className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg transition-colors"
            title="Update Status"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
          <button
            onClick={onDelete}
            className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
            title="Delete Order"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </td>
    </tr>
  );
};

// Order Card Component (Grid View)
const OrderCard = ({
  order,
  onView,
  onEdit,
  onDelete,
  onUpdateStatus,
}: OrderTableRowProps) => {
  const priceDiff = order.price && order.estimatedPrice
    ? order.price - order.estimatedPrice
    : null;

  return (
    <div className="card p-6 hover:shadow-lg transition-shadow">
      <div className="flex items-start justify-between mb-4">
        <div>
          <div className="text-xs font-mono text-slate-500 mb-1">
            {order._id.substring(0, 8)}...
          </div>
          <h3 className="text-lg font-semibold text-slate-900">
            {order.customerId?.name ?? 'Unknown Customer'}
          </h3>
        </div>
        <span
          className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium ${getOrderStatusBadgeClass(
            order.status
          )}`}
        >
          <span>{getStatusIcon(order.status)}</span>
          {order.status.replace('_', ' ')}
        </span>
      </div>

      <div className="space-y-2 mb-4 text-sm">
        <div className="flex justify-between">
          <span className="text-slate-500">Driver:</span>
          <span className="text-slate-900 font-medium">
            {order.driverId?.name ?? 'N/A'}
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-slate-500">Type:</span>
          <span className="text-slate-900 capitalize">{order.type}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-slate-500">Vehicle:</span>
          <span className="text-slate-900 capitalize">
            {order.vehicleType ?? 'N/A'}
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-slate-500">Est. Cost:</span>
          <span className="text-slate-900 font-medium">
            {formatCurrency(order.estimatedPrice)}
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-slate-500">Price:</span>
          <div className="text-right">
            <div className="text-slate-900 font-semibold">
              {formatCurrency(order.price)}
            </div>
            {priceDiff !== null && (
              <div
                className={`text-xs ${
                  priceDiff > 0 ? 'text-red-600' : priceDiff < 0 ? 'text-green-600' : 'text-slate-500'
                }`}
              >
                {priceDiff > 0 ? '+' : ''}{formatCurrency(priceDiff)} vs estimate
              </div>
            )}
          </div>
        </div>
        <div className="flex justify-between">
          <span className="text-slate-500">Created:</span>
          <span className="text-slate-900">{formatDate(order.createdAt, 'N/A')}</span>
        </div>
      </div>

      <div className="flex items-center gap-2 pt-4 border-t border-slate-200">
        <Link
          to={`/orders/${order._id}`}
          className="flex-1 btn-secondary text-center flex items-center justify-center gap-2"
        >
          <Eye className="w-4 h-4" />
          View
        </Link>
        <button
          onClick={onEdit}
          className="p-2 text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
          title="Edit"
        >
          <Edit className="w-4 h-4" />
        </button>
        <button
          onClick={onUpdateStatus}
          className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg transition-colors"
          title="Update Status"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
        <button
          onClick={onDelete}
          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          title="Delete"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};

// Status Update Modal
interface StatusModalProps {
  order: Order;
  onClose: () => void;
  onUpdate: (orderId: string, status: OrderStatus) => Promise<void>;
}

const StatusModal = ({ order, onClose, onUpdate }: StatusModalProps) => {
  const [selectedStatus, setSelectedStatus] = useState<OrderStatus>(
    order.status as OrderStatus
  );
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    await onUpdate(order._id, selectedStatus);
    setIsSubmitting(false);
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
        <div className="flex items-center justify-between p-6 border-b border-slate-200">
          <h2 className="text-xl font-semibold text-slate-900">Update Order Status</h2>
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
              Order ID
            </label>
            <input
              type="text"
              value={order._id.substring(0, 12) + '...'}
              disabled
              className="input bg-slate-50"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Current Status
            </label>
            <input
              type="text"
              value={order.status}
              disabled
              className="input bg-slate-50"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              New Status *
            </label>
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value as OrderStatus)}
              className="input"
              required
            >
              <option value="pending">Pending</option>
              <option value="accepted">Accepted</option>
              <option value="on_the_way">On The Way</option>
              <option value="delivered">Delivered</option>
              <option value="cancelled">Cancelled</option>
            </select>
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
            <button type="submit" className="btn-primary flex-1" disabled={isSubmitting}>
              {isSubmitting ? 'Updating...' : 'Update Status'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// Delete Confirmation Modal
interface DeleteModalProps {
  order: Order;
  onClose: () => void;
  onConfirm: (orderId: string) => Promise<void>;
}

const DeleteModal = ({ order, onClose, onConfirm }: DeleteModalProps) => {
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleConfirm = async () => {
    setIsSubmitting(true);
    await onConfirm(order._id);
    setIsSubmitting(false);
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
        <div className="flex items-center justify-between p-6 border-b border-slate-200">
          <h2 className="text-xl font-semibold text-red-600">Delete Order</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 space-y-4">
          <p className="text-slate-700">
            Are you sure you want to delete this order? This action cannot be undone.
          </p>
          <div className="bg-slate-50 p-4 rounded-lg space-y-2 text-sm">
            <div>
              <span className="text-slate-500">Order ID:</span>{' '}
              <span className="font-mono">{order._id.substring(0, 12)}...</span>
            </div>
            <div>
              <span className="text-slate-500">Customer:</span>{' '}
              <span className="font-medium">{order.customerId?.name ?? 'Unknown'}</span>
            </div>
            <div>
              <span className="text-slate-500">Status:</span>{' '}
              <span className="font-medium">{order.status}</span>
            </div>
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
              type="button"
              onClick={handleConfirm}
              className="flex-1 bg-red-600 hover:bg-red-700 text-white font-medium px-4 py-2 rounded-lg transition-colors disabled:opacity-50"
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Deleting...' : 'Delete Order'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Orders;

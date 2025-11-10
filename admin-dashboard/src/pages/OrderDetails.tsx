import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api } from '../config/api';

interface OrderDetail {
  _id: string;
  type: 'send' | 'receive';
  vehicleType?: 'car' | 'bike';
  orderCategory?: string;
  senderName?: string;
  senderAddress?: string;
  senderPhoneNumber?: string;
  deliveryNotes?: string;
  status: string;
  price?: number;
  estimatedPrice?: number;
  distance?: number;
  createdAt: string;
  updatedAt: string;
  customerId?: {
    name: string;
    email: string;
    phoneNumber?: string;
  };
  driverId?: {
    name: string;
    email: string;
    phoneNumber?: string;
  };
  pickupLocation?: {
    address?: string;
    lat?: number;
    lng?: number;
  };
  dropoffLocation?: {
    address?: string;
    lat?: number;
    lng?: number;
  };
}

const getStatusColor = (status: string) => {
  const colors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-800',
    accepted: 'bg-blue-100 text-blue-800',
    on_the_way: 'bg-purple-100 text-purple-800',
    delivered: 'bg-green-100 text-green-800',
    cancelled: 'bg-red-100 text-red-800',
  };
  return colors[status] || 'bg-gray-100 text-gray-800';
};

const formatCurrency = (value?: number) => {
  if (value === undefined || value === null) {
    return 'N/A';
  }
  return `${value.toFixed(2)} NIS`;
};

const formatCoordinates = (location?: {
  lat?: number;
  lng?: number;
}) => {
  if (
    location?.lat === undefined ||
    location?.lng === undefined
  ) {
    return 'N/A';
  }
  return `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`;
};

const OrderDetails = () => {
  const { orderId } = useParams<{ orderId: string }>();
  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchOrder = async () => {
      if (!orderId) return;

      try {
        const response = await api.get(`/orders/${orderId}`);
        setOrder(response.data.order);
      } catch (error) {
        console.error('Error fetching order details:', error);
        setOrder(null);
      } finally {
        setLoading(false);
      }
    };

    fetchOrder();
  }, [orderId]);

  if (loading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  if (!order) {
    return (
      <div className="space-y-6">
        <Link to="/orders" className="text-indigo-600 hover:text-indigo-900">
          ← Back to Orders
        </Link>
        <div className="bg-white shadow rounded-lg p-6">
          <h1 className="text-2xl font-semibold text-gray-900 mb-4">
            Order not found
          </h1>
          <p className="text-gray-600">
            The order you are looking for does not exist or has been removed.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Link to="/orders" className="text-indigo-600 hover:text-indigo-900">
        ← Back to Orders
      </Link>

      <div className="bg-white shadow rounded-lg p-6 space-y-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">
              Order #{order._id.substring(0, 8)}...
            </h1>
            <p className="text-gray-500">
              Created on {new Date(order.createdAt).toLocaleString()}
            </p>
          </div>
          <span
            className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(
              order.status
            )}`}
          >
            {order.status.replace('_', ' ')}
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Delivery Details
            </h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Request Type:</span>{' '}
                {order.type}
              </p>
              <p className="capitalize">
                <span className="font-medium">Vehicle:</span>{' '}
                {order.vehicleType ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Order Category:</span>{' '}
                {order.orderCategory ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Estimated Cost:</span>{' '}
                {formatCurrency(order.estimatedPrice)}
              </p>
              <p>
                <span className="font-medium">Recorded Price:</span>{' '}
                {formatCurrency(order.price)}
              </p>
              <p>
                <span className="font-medium">Distance:</span>{' '}
                {order.distance !== undefined && order.distance !== null
                  ? `${order.distance.toFixed(2)} km`
                  : 'N/A'}
              </p>
            </div>
          </div>

          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Sender Information
            </h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Sender Name:</span>{' '}
                {order.senderName ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Sender Address:</span>{' '}
                {order.senderAddress ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Phone Number:</span>{' '}
                {order.senderPhoneNumber ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Delivery Notes:</span>{' '}
                {order.deliveryNotes && order.deliveryNotes.trim().length > 0
                  ? order.deliveryNotes
                  : 'None'}
              </p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Customer
            </h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Name:</span>{' '}
                {order.customerId?.name ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Email:</span>{' '}
                {order.customerId?.email ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Phone:</span>{' '}
                {order.customerId?.phoneNumber ?? 'N/A'}
              </p>
            </div>
          </div>

          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Driver
            </h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Name:</span>{' '}
                {order.driverId?.name ?? 'Unassigned'}
              </p>
              <p>
                <span className="font-medium">Email:</span>{' '}
                {order.driverId?.email ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Phone:</span>{' '}
                {order.driverId?.phoneNumber ?? 'N/A'}
              </p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Pickup Location
            </h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Address:</span>{' '}
                {order.pickupLocation?.address ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Coordinates:</span>{' '}
                {formatCoordinates(order.pickupLocation)}
              </p>
            </div>
          </div>

          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Delivery Location
            </h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Address:</span>{' '}
                {order.dropoffLocation?.address ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Coordinates:</span>{' '}
                {formatCoordinates(order.dropoffLocation)}
              </p>
            </div>
          </div>
        </div>

        <div>
          <h2 className="text-sm text-gray-500">
            Last updated on {new Date(order.updatedAt).toLocaleString()}
          </h2>
        </div>
      </div>
    </div>
  );
};

export default OrderDetails;


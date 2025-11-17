import { Link, useParams } from 'react-router-dom';
import { useOrderDetails } from '@/store/orders/useOrderDetails';
import { getOrderStatusBadgeClass } from '@/utils/status';
import { formatCoordinates, formatCurrency, formatDate } from '@/utils/formatters';

const OrderDetails = () => {
  const { orderId } = useParams<{ orderId: string }>();
  const { order, isLoading, error } = useOrderDetails(orderId);

  if (isLoading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  if (error) {
    return (
      <div className="space-y-4">
        <Link to="/orders" className="text-indigo-600 hover:text-indigo-900">
          ← Back to Orders
        </Link>
        <div className="bg-red-50 border border-red-100 text-red-600 px-4 py-3 rounded-md">
          {error}
        </div>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="space-y-6">
        <Link to="/orders" className="text-indigo-600 hover:text-indigo-900">
          ← Back to Orders
        </Link>
        <div className="bg-white shadow rounded-lg p-6">
          <h1 className="text-2xl font-semibold text-gray-900 mb-4">Order not found</h1>
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
            <p className="text-gray-500">Created on {formatDate(order.createdAt)}</p>
          </div>
          <span
            className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getOrderStatusBadgeClass(
              order.status
            )}`}
          >
            {order.status.replace('_', ' ')}
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">Delivery Details</h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Request Type:</span> {order.type}
              </p>
              <p className="capitalize">
                <span className="font-medium">Vehicle:</span> {order.vehicleType ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Order Category:</span> {order.orderCategory ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Estimated Cost:</span> {formatCurrency(order.estimatedPrice)}
              </p>
              <p>
                <span className="font-medium">Recorded Price:</span> {formatCurrency(order.price)}
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
            <h2 className="text-lg font-semibold text-gray-900">Sender Information</h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Sender Name:</span> {order.senderName ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Sender Address:</span> {order.senderAddress ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Phone Number:</span>{' '}
                {order.senderPhoneNumber !== undefined && order.senderPhoneNumber !== null
                  ? order.senderPhoneNumber.toString()
                  : 'N/A'}
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
            <h2 className="text-lg font-semibold text-gray-900">Customer</h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Name:</span> {order.customerId?.name ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Email:</span> {order.customerId?.email ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Phone:</span> {order.customerId?.phoneNumber ?? 'N/A'}
              </p>
            </div>
          </div>

          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">Driver</h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Name:</span> {order.driverId?.name ?? 'Unassigned'}
              </p>
              <p>
                <span className="font-medium">Email:</span> {order.driverId?.email ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Phone:</span> {order.driverId?.phoneNumber ?? 'N/A'}
              </p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">Pickup Location</h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Address:</span> {order.pickupLocation?.address ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Coordinates:</span> {formatCoordinates(order.pickupLocation)}
              </p>
            </div>
          </div>

          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">Delivery Location</h2>
            <div className="space-y-2 text-sm text-gray-700">
              <p>
                <span className="font-medium">Address:</span> {order.dropoffLocation?.address ?? 'N/A'}
              </p>
              <p>
                <span className="font-medium">Coordinates:</span> {formatCoordinates(order.dropoffLocation)}
              </p>
            </div>
          </div>
        </div>

        <div>
          <h2 className="text-sm text-gray-500">Last updated on {formatDate(order.updatedAt)}</h2>
        </div>
      </div>
    </div>
  );
};

export default OrderDetails;

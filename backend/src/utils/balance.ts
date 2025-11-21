import Order from '../models/Order';
import Payment from '../models/Payment';
import Settings from '../models/Settings';
import User from '../models/User';
import mongoose from 'mongoose';

export interface DriverBalanceInfo {
  totalDeliveryRevenue: number;
  commissionPercentage: number;
  totalCommissionOwed: number;
  totalPaymentsMade: number;
  currentBalance: number;
  isSuspended: boolean;
}

/**
 * Calculate driver balance based on completed deliveries and payments
 * Formula: (Sum of delivery prices * CommissionPercentage) - Sum of payments
 * Optimized to use aggregation pipelines for better performance
 */
export const calculateDriverBalance = async (
  driverId: mongoose.Types.ObjectId
): Promise<DriverBalanceInfo> => {
  // Get settings for commission percentage
  const settings = await Settings.getSettings();
  const commissionPercentage = settings.commissionPercentage || 2;

  // Use aggregation pipeline to calculate totals efficiently
  const [orderStats, paymentStats, driver] = await Promise.all([
    // Aggregate completed orders in a single query
    Order.aggregate([
      {
        $match: {
          driverId: driverId,
          status: 'delivered',
        },
      },
      {
        $group: {
          _id: null,
          totalDeliveryRevenue: { $sum: { $ifNull: ['$price', 0] } },
        },
      },
    ]),
    // Aggregate payments in a single query
    Payment.aggregate([
      {
        $match: {
          driverId: driverId,
        },
      },
      {
        $group: {
          _id: null,
          totalPaymentsMade: { $sum: '$amount' },
        },
      },
    ]),
    // Get driver status
    User.findById(driverId).select('isActive'),
  ]);

  const totalDeliveryRevenue = orderStats[0]?.totalDeliveryRevenue || 0;
  const totalPaymentsMade = paymentStats[0]?.totalPaymentsMade || 0;
  const totalCommissionOwed = (totalDeliveryRevenue * commissionPercentage) / 100;
  const currentBalance = totalCommissionOwed - totalPaymentsMade;
  const isSuspended = driver?.isActive === false;

  return {
    totalDeliveryRevenue,
    commissionPercentage,
    totalCommissionOwed,
    totalPaymentsMade,
    currentBalance,
    isSuspended,
  };
};

/**
 * Batch calculate balances for multiple drivers efficiently
 * Uses aggregation pipelines to minimize database queries
 */
export const calculateDriverBalancesBatch = async (
  driverIds: mongoose.Types.ObjectId[]
): Promise<Map<string, DriverBalanceInfo>> => {
  if (driverIds.length === 0) {
    return new Map();
  }

  // Get settings once
  const settings = await Settings.getSettings();
  const commissionPercentage = settings.commissionPercentage || 2;

  // Batch aggregate orders for all drivers
  const orderStats = await Order.aggregate([
    {
      $match: {
        driverId: { $in: driverIds },
        status: 'delivered',
      },
    },
    {
      $group: {
        _id: '$driverId',
        totalDeliveryRevenue: { $sum: { $ifNull: ['$price', 0] } },
      },
    },
  ]);

  // Batch aggregate payments for all drivers
  const paymentStats = await Payment.aggregate([
    {
      $match: {
        driverId: { $in: driverIds },
      },
    },
    {
      $group: {
        _id: '$driverId',
        totalPaymentsMade: { $sum: '$amount' },
      },
    },
  ]);

  // Get all drivers' statuses in one query
  const drivers = await User.find({
    _id: { $in: driverIds },
  }).select('_id isActive');

  // Create maps for quick lookup
  const orderMap = new Map(
    orderStats.map((stat) => [stat._id.toString(), stat.totalDeliveryRevenue])
  );
  const paymentMap = new Map(
    paymentStats.map((stat) => [stat._id.toString(), stat.totalPaymentsMade])
  );
  const driverMap = new Map(
    drivers.map((driver) => [driver._id.toString(), driver.isActive === false])
  );

  // Build result map
  const result = new Map<string, DriverBalanceInfo>();
  for (const driverId of driverIds) {
    const driverIdStr = driverId.toString();
    const totalDeliveryRevenue = orderMap.get(driverIdStr) || 0;
    const totalPaymentsMade = paymentMap.get(driverIdStr) || 0;
    const totalCommissionOwed = (totalDeliveryRevenue * commissionPercentage) / 100;
    const currentBalance = totalCommissionOwed - totalPaymentsMade;
    const isSuspended = driverMap.get(driverIdStr) || false;

    result.set(driverIdStr, {
      totalDeliveryRevenue,
      commissionPercentage,
      totalCommissionOwed,
      totalPaymentsMade,
      currentBalance,
      isSuspended,
    });
  }

  return result;
};

/**
 * Check if driver should be suspended or reactivated based on balance
 * - Suspends if balance >= maxAllowedBalance
 * - Reactivates if balance <= 0 (fully paid or credit)
 */
export const checkAndSuspendDriverIfNeeded = async (
  driverId: mongoose.Types.ObjectId
): Promise<{ suspended: boolean; reactivated: boolean; balance: number; maxAllowed: number }> => {
  const settings = await Settings.getSettings();
  const maxAllowedBalance = settings.maxAllowedBalance || 50;

  const balanceInfo = await calculateDriverBalance(driverId);
  const driver = await User.findById(driverId);
  
  if (!driver) {
    return {
      suspended: false,
      reactivated: false,
      balance: balanceInfo.currentBalance,
      maxAllowed: maxAllowedBalance,
    };
  }

  let suspended = false;
  let reactivated = false;

  // Check if driver should be suspended (balance >= limit)
  if (balanceInfo.currentBalance >= maxAllowedBalance) {
    if (driver.isActive !== false) {
      driver.isActive = false;
      await driver.save();
      suspended = true;
      console.log(
        `Driver ${driverId} automatically suspended. Balance: ${balanceInfo.currentBalance.toFixed(2)} NIS (Limit: ${maxAllowedBalance} NIS)`
      );
    }
  }
  // Check if driver should be reactivated (balance <= 0)
  else if (balanceInfo.currentBalance <= 0 && driver.isActive === false) {
    driver.isActive = true;
    await driver.save();
    reactivated = true;
    console.log(
      `Driver ${driverId} automatically reactivated. Balance: ${balanceInfo.currentBalance.toFixed(2)} NIS (fully paid or credit)`
    );
  }

  return {
    suspended: suspended || (driver.isActive === false && balanceInfo.currentBalance >= maxAllowedBalance),
    reactivated,
    balance: balanceInfo.currentBalance,
    maxAllowed: maxAllowedBalance,
  };
};

/**
 * Batch check and suspend/reactivate drivers based on balances
 * Much more efficient than checking individually
 */
export const checkAndSuspendDriversBatch = async (
  driverIds: mongoose.Types.ObjectId[],
  balanceMap: Map<string, DriverBalanceInfo>
): Promise<{ suspended: number; reactivated: number }> => {
  if (driverIds.length === 0) {
    return { suspended: 0, reactivated: 0 };
  }

  const settings = await Settings.getSettings();
  const maxAllowedBalance = settings.maxAllowedBalance || 50;

  // Get all drivers in one query
  const drivers = await User.find({
    _id: { $in: driverIds },
  });

  const updatesToSave: Array<{ driver: any; isActive: boolean }> = [];
  let suspended = 0;
  let reactivated = 0;

  // Check each driver and collect updates
  for (const driver of drivers) {
    const driverIdStr = driver._id.toString();
    const balanceInfo = balanceMap.get(driverIdStr);
    
    if (!balanceInfo) continue;

    const shouldBeSuspended = balanceInfo.currentBalance >= maxAllowedBalance;
    const shouldBeReactivated = balanceInfo.currentBalance <= 0;

    // Check if suspension is needed
    if (shouldBeSuspended && driver.isActive !== false) {
      driver.isActive = false;
      updatesToSave.push({ driver, isActive: false });
      suspended++;
    }
    // Check if reactivation is needed
    else if (shouldBeReactivated && driver.isActive === false) {
      driver.isActive = true;
      updatesToSave.push({ driver, isActive: true });
      reactivated++;
    }
  }

  // Batch save all updates
  if (updatesToSave.length > 0) {
    await Promise.all(
      updatesToSave.map(({ driver }) => driver.save())
    );
  }

  return { suspended, reactivated };
};

/**
 * Check all drivers and suspend those who exceed the balance limit
 * Useful when settings change (commission percentage or max allowed balance)
 */
export const checkAllDriversBalance = async (): Promise<{
  checked: number;
  suspended: number;
  errors: number;
}> => {
  const User = (await import('../models/User')).default;
  const drivers = await User.find({ role: 'driver' });
  
  let suspended = 0;
  let errors = 0;
  
  for (const driver of drivers) {
    try {
      const result = await checkAndSuspendDriverIfNeeded(driver._id);
      if (result.suspended) {
        suspended++;
      }
    } catch (error) {
      console.error(`Error checking balance for driver ${driver._id}:`, error);
      errors++;
    }
  }
  
  return {
    checked: drivers.length,
    suspended,
    errors,
  };
};


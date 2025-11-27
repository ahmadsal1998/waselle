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
 * Calculate driver balance based on completed deliveries after last settlement
 * New system: Balance is stored in User model and only counts orders after lastBalanceSettlementDate
 * Formula: Sum of (Order Amount × CommissionPercentage) for orders delivered after last settlement
 */
export const calculateDriverBalance = async (
  driverId: mongoose.Types.ObjectId
): Promise<DriverBalanceInfo> => {
  // Get settings for commission percentage
  const settings = await Settings.getSettings();
  const commissionPercentage = settings.commissionPercentage || 2;

  // Get driver with balance and last settlement date
  const driver = await User.findById(driverId).select('isActive balance lastBalanceSettlementDate');
  
  if (!driver) {
    throw new Error('Driver not found');
  }

  // Get current balance from driver model (stored balance)
  const currentBalance = driver.balance || 0;

  // Calculate commission from orders delivered after last settlement (for verification/display)
  const matchQuery: any = {
    driverId: driverId,
    status: 'delivered',
  };

  // Only count orders delivered after last settlement date
  if (driver.lastBalanceSettlementDate) {
    matchQuery.updatedAt = { $gte: driver.lastBalanceSettlementDate };
  }

  const orderStats = await Order.aggregate([
    {
      $match: matchQuery,
    },
    {
      $group: {
        _id: null,
        totalDeliveryRevenue: { $sum: { $ifNull: ['$price', 0] } },
      },
    },
  ]);

  const totalDeliveryRevenue = orderStats[0]?.totalDeliveryRevenue || 0;
  const totalCommissionOwed = (totalDeliveryRevenue * commissionPercentage) / 100;
  const isSuspended = driver.isActive === false;

  // Get total payments made (for display purposes)
  const paymentStats = await Payment.aggregate([
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
  ]);

  const totalPaymentsMade = paymentStats[0]?.totalPaymentsMade || 0;

  return {
    totalDeliveryRevenue,
    commissionPercentage,
    totalCommissionOwed,
    totalPaymentsMade,
    currentBalance, // Use stored balance from User model
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

  // Get all drivers with their stored balance and status
  // CRITICAL: Use stored balance from User model, not calculated from orders
  const drivers = await User.find({
    _id: { $in: driverIds },
  }).select('_id isActive balance');

  // Create maps for quick lookup
  const orderMap = new Map(
    orderStats.map((stat) => [stat._id.toString(), stat.totalDeliveryRevenue])
  );
  const paymentMap = new Map(
    paymentStats.map((stat) => [stat._id.toString(), stat.totalPaymentsMade])
  );

  // Build result map using stored balance from User model
  const result = new Map<string, DriverBalanceInfo>();
  for (const driver of drivers) {
    const driverIdStr = driver._id.toString();
    const totalDeliveryRevenue = orderMap.get(driverIdStr) || 0;
    const totalPaymentsMade = paymentMap.get(driverIdStr) || 0;
    const totalCommissionOwed = (totalDeliveryRevenue * commissionPercentage) / 100;
    
    // CRITICAL: Use stored balance from User model, not calculated balance
    const currentBalance = driver.balance || 0;
    const isSuspended = driver.isActive === false;

    result.set(driverIdStr, {
      totalDeliveryRevenue,
      commissionPercentage,
      totalCommissionOwed,
      totalPaymentsMade,
      currentBalance, // Use stored balance, not calculated
      isSuspended,
    });
  }

  return result;
};

/**
 * Check if driver should be suspended or reactivated based on balance
 * - Suspends if balance >= maxAllowedBalance
 * - Reactivates if balance <= 0 (fully paid or credit)
 * @param driverId - The driver's ID
 * @param currentBalance - Optional: current balance to check (if not provided, will fetch from driver)
 */
export const checkAndSuspendDriverIfNeeded = async (
  driverId: mongoose.Types.ObjectId,
  currentBalance?: number
): Promise<{ suspended: boolean; reactivated: boolean; balance: number; maxAllowed: number }> => {
  const settings = await Settings.getSettings();
  const maxAllowedBalance = settings.maxAllowedBalance || 3;

  // Get driver first to check current status
  const driver = await User.findById(driverId);
  
  if (!driver) {
    throw new Error('Driver not found');
  }

  // Use provided balance or fetch from driver model
  let balance: number;
  if (currentBalance !== undefined) {
    balance = currentBalance;
  } else {
    // Get balance from driver model (stored balance)
    balance = driver.balance || 0;
  }

  let suspended = false;
  let reactivated = false;

  // Check if driver should be suspended (balance >= limit)
  if (balance >= maxAllowedBalance) {
    if (driver.isActive !== false) {
      driver.isActive = false;
      await driver.save();
      suspended = true;
      console.log(
        `✅ Driver ${driverId} automatically suspended. Balance: ${balance.toFixed(2)} NIS (Limit: ${maxAllowedBalance} NIS)`
      );
    } else {
      // Driver is already suspended, but log for verification
      console.log(
        `⚠️ Driver ${driverId} is already suspended. Balance: ${balance.toFixed(2)} NIS (Limit: ${maxAllowedBalance} NIS)`
      );
    }
  }
  // Check if driver should be reactivated (only if balance is exactly 0 after payment)
  else if (balance === 0 && driver.isActive === false) {
    // Only reactivate if balance is exactly 0 (fully paid after payment)
    // Don't reactivate if balance is just below the limit - driver must pay full balance
    driver.isActive = true;
    await driver.save();
    reactivated = true;
    console.log(
      `✅ Driver ${driverId} automatically reactivated. Balance: ${balance.toFixed(2)} NIS (fully paid)`
    );
  }

  return {
    suspended: suspended || (driver.isActive === false && balance >= maxAllowedBalance),
    reactivated,
    balance,
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
  const maxAllowedBalance = settings.maxAllowedBalance || 3;

  // Get all drivers in one query with their stored balance
  const drivers = await User.find({
    _id: { $in: driverIds },
  }).select('_id isActive balance');

  const updatesToSave: Array<{ driver: any; isActive: boolean }> = [];
  let suspended = 0;
  let reactivated = 0;

  // Check each driver and collect updates
  for (const driver of drivers) {
    const driverIdStr = driver._id.toString();
    const balanceInfo = balanceMap.get(driverIdStr);
    
    if (!balanceInfo) continue;

    // Use stored balance from driver model (source of truth)
    const storedBalance = driver.balance || 0;
    const shouldBeSuspended = storedBalance >= maxAllowedBalance;
    
    // Only reactivate if balance is exactly 0 (fully paid after payment)
    // CRITICAL: Only reactivate if balance is 0, not if it's just below the limit
    // This ensures drivers must pay the full balance before reactivation
    const shouldBeReactivated = storedBalance === 0;

    // Check if suspension is needed
    if (shouldBeSuspended && driver.isActive !== false) {
      driver.isActive = false;
      updatesToSave.push({ driver, isActive: false });
      suspended++;
      console.log(
        `✅ Driver ${driverIdStr} automatically suspended via batch check. Balance: ${storedBalance.toFixed(2)} NIS (Limit: ${maxAllowedBalance} NIS)`
      );
    }
    // Check if reactivation is needed (only if balance is 0 or less)
    else if (shouldBeReactivated && driver.isActive === false) {
      driver.isActive = true;
      updatesToSave.push({ driver, isActive: true });
      reactivated++;
      console.log(
        `✅ Driver ${driverIdStr} automatically reactivated via batch check. Balance: ${storedBalance.toFixed(2)} NIS (fully paid)`
      );
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
 * Add commission to driver balance when order is delivered
 * Commission = Order Amount × CommissionPercentage
 * Balance is capped at maxAllowedBalance
 */
export const addCommissionToBalance = async (
  driverId: mongoose.Types.ObjectId,
  orderAmount: number
): Promise<{ newBalance: number; commissionAdded: number; capped: boolean }> => {
  const settings = await Settings.getSettings();
  const commissionPercentage = settings.commissionPercentage || 2;
  const maxAllowedBalance = settings.maxAllowedBalance || 3;

  const driver = await User.findById(driverId);
  if (!driver) {
    throw new Error('Driver not found');
  }

  // Calculate commission for this order
  const commission = (orderAmount * commissionPercentage) / 100;
  
  // Get current balance (default to 0 if not set)
  const currentBalance = driver.balance || 0;
  
  // Calculate new balance (capped at maxAllowedBalance)
  const newBalanceUncapped = currentBalance + commission;
  const newBalance = Math.min(newBalanceUncapped, maxAllowedBalance);
  const capped = newBalanceUncapped > maxAllowedBalance;
  const commissionAdded = newBalance - currentBalance;

  // Update driver balance
  driver.balance = newBalance;
  await driver.save();

  return {
    newBalance,
    commissionAdded,
    capped,
  };
};

/**
 * Reset driver balance to 0 when payment is made
 * Also updates lastBalanceSettlementDate
 */
export const resetDriverBalance = async (
  driverId: mongoose.Types.ObjectId
): Promise<void> => {
  const driver = await User.findById(driverId);
  if (!driver) {
    throw new Error('Driver not found');
  }

  driver.balance = 0;
  driver.lastBalanceSettlementDate = new Date();
  await driver.save();
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


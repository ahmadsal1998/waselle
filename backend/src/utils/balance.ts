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
 */
export const calculateDriverBalance = async (
  driverId: mongoose.Types.ObjectId
): Promise<DriverBalanceInfo> => {
  // Get settings for commission percentage
  const settings = await Settings.getSettings();
  const commissionPercentage = settings.commissionPercentage || 2;

  // Get all completed (delivered) orders for this driver
  const completedOrders = await Order.find({
    driverId,
    status: 'delivered',
  });

  // Calculate total delivery revenue
  const totalDeliveryRevenue = completedOrders.reduce(
    (sum, order) => sum + (order.price || 0),
    0
  );

  // Calculate total commission owed
  const totalCommissionOwed = (totalDeliveryRevenue * commissionPercentage) / 100;

  // Get all payments made by this driver
  const payments = await Payment.find({ driverId });
  const totalPaymentsMade = payments.reduce((sum, payment) => sum + payment.amount, 0);

  // Calculate current balance
  const currentBalance = totalCommissionOwed - totalPaymentsMade;

  // Get driver to check suspension status
  const driver = await User.findById(driverId);
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


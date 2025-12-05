import { Request, Response } from 'express';
import { getReviewModeStatus } from '../utils/reviewMode';

/**
 * Endpoint to check if the app is in review mode
 * Returns "review" when in review mode, "live" otherwise
 */
export const checkReviewMode = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const status = getReviewModeStatus(req);
    res.status(200).json({ mode: status });
  } catch (error: any) {
    console.error('Error checking review mode:', error);
    res.status(500).json({ 
      message: 'Error checking review mode',
      mode: 'live' // Default to live mode on error
    });
  }
};


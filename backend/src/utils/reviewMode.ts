import { Request } from 'express';

/**
 * Detects if the request is from Apple's App Review or TestFlight environment
 * Based on user-agent strings, IP addresses, and custom headers
 */
export function isReviewMode(req: Request): boolean {
  const userAgent = req.get('user-agent') || '';
  const ip = req.ip || req.socket.remoteAddress || req.headers['x-forwarded-for'] || '';
  const forwardedFor = Array.isArray(ip) ? ip[0] : (typeof ip === 'string' ? ip.split(',')[0].trim() : '');
  const clientIP = forwardedFor || req.ip || req.socket.remoteAddress || '';
  
  // Check user-agent for Apple review indicators
  const appleReviewUserAgents = [
    'AppleCoreMedia', // Apple's media framework used in review
    'TestFlight', // TestFlight app
    'AppStore', // App Store review
  ];
  
  const hasAppleUserAgent = appleReviewUserAgents.some(ua => 
    userAgent.toLowerCase().includes(ua.toLowerCase())
  );
  
  // Check for known Apple IP ranges (common review IPs)
  // Apple uses various IP ranges, but these are common patterns
  const appleIPPatterns = [
    /^17\./, // Apple's IP range (17.0.0.0/8)
    /^17\.0\./, // Apple's IP range
  ];
  
  const hasAppleIP = appleIPPatterns.some(pattern => pattern.test(clientIP));
  
  // Check for a custom header that can be set for testing
  const reviewModeHeader = req.get('x-review-mode');
  const isReviewModeHeader = reviewModeHeader === 'true' || reviewModeHeader === '1';
  
  // Check environment variable to force review mode (for testing)
  const forceReviewMode = process.env.FORCE_REVIEW_MODE === 'true' || process.env.FORCE_REVIEW_MODE === '1';
  
  // Return true if any indicator suggests review mode
  const isReview = hasAppleUserAgent || hasAppleIP || isReviewModeHeader || forceReviewMode;
  
  if (isReview) {
    console.log('[reviewMode] Review mode detected:', {
      hasAppleUserAgent,
      hasAppleIP,
      isReviewModeHeader,
      forceReviewMode,
      userAgent: userAgent.substring(0, 100),
      ip: clientIP,
    });
  }
  
  return isReview;
}

/**
 * Get review mode status as a string ('review' or 'live')
 */
export function getReviewModeStatus(req: Request): 'review' | 'live' {
  return isReviewMode(req) ? 'review' : 'live';
}


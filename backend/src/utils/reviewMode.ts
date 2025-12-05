import { Request } from 'express';

/**
 * Detects if the request is from Apple's App Review or TestFlight environment
 * Based on user-agent strings and IP addresses commonly used by Apple reviewers
 */
export function isReviewMode(req: Request): boolean {
  const userAgent = req.get('user-agent') || '';
  const ip = req.ip || req.socket.remoteAddress || '';
  
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
  // Note: These are examples - you may need to update with actual Apple review IPs
  // Apple uses various IP ranges, but these are common patterns
  const appleIPPatterns = [
    /^17\./, // Apple's IP range
    /^17\.0\./, // Apple's IP range
  ];
  
  const hasAppleIP = appleIPPatterns.some(pattern => pattern.test(ip));
  
  // Also check for a custom header that can be set for testing
  const reviewModeHeader = req.get('x-review-mode');
  const isReviewModeHeader = reviewModeHeader === 'true' || reviewModeHeader === '1';
  
  // Return true if any indicator suggests review mode
  return hasAppleUserAgent || hasAppleIP || isReviewModeHeader;
}

/**
 * Get review mode status as a string ('review' or 'live')
 */
export function getReviewModeStatus(req: Request): 'review' | 'live' {
  return isReviewMode(req) ? 'review' : 'live';
}


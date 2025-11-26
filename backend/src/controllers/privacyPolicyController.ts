import { Response } from 'express';
import PrivacyPolicy from '../models/PrivacyPolicy';
import { AuthRequest } from '../middleware/auth';

// Public endpoint - anyone can view the privacy policy
export const getPrivacyPolicy = async (
  req: any,
  res: Response
): Promise<void> => {
  try {
    const privacyPolicy = await PrivacyPolicy.getPrivacyPolicy();
    console.log('GET Privacy Policy - Content length:', privacyPolicy.content?.length);
    console.log('GET Privacy Policy - Arabic content length:', privacyPolicy.contentAr?.length);
    console.log('GET Privacy Policy - First 100 chars:', privacyPolicy.content?.substring(0, 100));
    
    // Convert Mongoose document to plain object
    const privacyPolicyObj = privacyPolicy.toObject ? privacyPolicy.toObject() : privacyPolicy;
    res.status(200).json({ privacyPolicy: privacyPolicyObj });
  } catch (error: any) {
    console.error('Error getting privacy policy:', error);
    res.status(500).json({
      message: error.message || 'Failed to get privacy policy',
    });
  }
};

// Admin-only endpoint - only admins can update the privacy policy
export const updatePrivacyPolicy = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Only admins can update privacy policy' });
      return;
    }

    const { content, contentAr } = req.body;

    // Validate content
    if (content === undefined) {
      res.status(400).json({
        message: 'content is required',
      });
      return;
    }

    if (typeof content !== 'string') {
      res.status(400).json({
        message: 'content must be a string',
      });
      return;
    }

    if (content.trim().length === 0) {
      res.status(400).json({
        message: 'content cannot be empty',
      });
      return;
    }

    // Validate Arabic content if provided
    if (contentAr !== undefined) {
      if (typeof contentAr !== 'string') {
        res.status(400).json({
          message: 'contentAr must be a string',
        });
        return;
      }
    }

    // Use findOneAndUpdate to ensure we're updating the correct document
    // This is more reliable than getPrivacyPolicy + save
    const updateData: any = {
      content: content.trim(),
      lastUpdated: new Date(),
      updatedBy: req.user.userId,
    };
    
    // Update Arabic content if provided
    if (contentAr !== undefined) {
      const trimmedAr = contentAr.trim();
      updateData.contentAr = trimmedAr.length > 0 ? trimmedAr : undefined;
    }
    
    console.log('Updating privacy policy with content length:', updateData.content.length);
    console.log('Updating privacy policy with Arabic content length:', updateData.contentAr?.length || 0);
    
    // Use findOneAndUpdate with upsert to ensure we update or create the document
    const privacyPolicy = await PrivacyPolicy.findOneAndUpdate(
      {}, // Empty filter to get the first (and should be only) document
      { $set: updateData },
      { 
        new: true, // Return updated document
        upsert: true, // Create if doesn't exist
        runValidators: true // Run schema validators
      }
    );
    
    console.log('After update - Content length:', privacyPolicy.content?.length);
    console.log('After update - Arabic content length:', privacyPolicy.contentAr?.length);
    console.log('After update - First 100 chars:', privacyPolicy.content?.substring(0, 100));

    // Convert Mongoose document to plain object
    const privacyPolicyObj = privacyPolicy.toObject ? privacyPolicy.toObject() : privacyPolicy;

    res.status(200).json({
      message: 'Privacy policy updated successfully',
      privacyPolicy: privacyPolicyObj,
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update privacy policy',
    });
  }
};


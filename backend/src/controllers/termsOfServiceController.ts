import { Response } from 'express';
import TermsOfService from '../models/TermsOfService';
import { AuthRequest } from '../middleware/auth';

// Public endpoint - anyone can view the terms of service
export const getTermsOfService = async (
  req: any,
  res: Response
): Promise<void> => {
  try {
    const termsOfService = await TermsOfService.getTermsOfService();
    console.log('GET Terms of Service - Content length:', termsOfService.content?.length);
    console.log('GET Terms of Service - Arabic content length:', termsOfService.contentAr?.length);
    console.log('GET Terms of Service - First 100 chars:', termsOfService.content?.substring(0, 100));
    
    // Convert Mongoose document to plain object
    const termsOfServiceObj = termsOfService.toObject ? termsOfService.toObject() : termsOfService;
    res.status(200).json({ termsOfService: termsOfServiceObj });
  } catch (error: any) {
    console.error('Error getting terms of service:', error);
    res.status(500).json({
      message: error.message || 'Failed to get terms of service',
    });
  }
};

// Admin-only endpoint - only admins can update the terms of service
export const updateTermsOfService = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Only admins can update terms of service' });
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
    
    console.log('Updating terms of service with content length:', updateData.content.length);
    console.log('Updating terms of service with Arabic content length:', updateData.contentAr?.length || 0);
    
    // Use findOneAndUpdate with upsert to ensure we update or create the document
    const termsOfService = await TermsOfService.findOneAndUpdate(
      {}, // Empty filter to get the first (and should be only) document
      { $set: updateData },
      { 
        new: true, // Return updated document
        upsert: true, // Create if doesn't exist
        runValidators: true // Run schema validators
      }
    );
    
    console.log('After update - Content length:', termsOfService.content?.length);
    console.log('After update - Arabic content length:', termsOfService.contentAr?.length);
    console.log('After update - First 100 chars:', termsOfService.content?.substring(0, 100));

    // Convert Mongoose document to plain object
    const termsOfServiceObj = termsOfService.toObject ? termsOfService.toObject() : termsOfService;

    res.status(200).json({
      message: 'Terms of service updated successfully',
      termsOfService: termsOfServiceObj,
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update terms of service',
    });
  }
};



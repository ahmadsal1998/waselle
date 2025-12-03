import mongoose, { Document, Schema, Model } from 'mongoose';

export interface ITermsOfService extends Document {
  content: string; // HTML or plain text content
  contentAr?: string; // Arabic content (optional)
  lastUpdated: Date;
  updatedBy?: mongoose.Types.ObjectId; // Reference to admin user who updated
  createdAt: Date;
  updatedAt: Date;
}

interface ITermsOfServiceModel extends Model<ITermsOfService> {
  getTermsOfService(): Promise<ITermsOfService>;
}

const TermsOfServiceSchema: Schema = new Schema(
  {
    content: {
      type: String,
      required: true,
      default: '<h1>Terms of Service</h1><p>Your terms of service content goes here.</p>',
    },
    contentAr: {
      type: String,
      required: false,
    },
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
    updatedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: false,
    },
  },
  {
    timestamps: true,
  }
);

// Ensure only one terms of service document exists
TermsOfServiceSchema.statics.getTermsOfService = async function (): Promise<ITermsOfService> {
  // Always get the first document (there should only be one)
  let termsOfService = await this.findOne().sort({ createdAt: -1 });
  if (!termsOfService) {
    termsOfService = await this.create({
      content: '<h1>Terms of Service</h1><p>Your terms of service content goes here. Please update this content from the admin panel.</p>',
      contentAr: '<h1>شروط الخدمة</h1><p>محتوى شروط الخدمة الخاص بك هنا. يرجى تحديث هذا المحتوى من لوحة الإدارة.</p>',
      lastUpdated: new Date(),
    });
    console.log('Created new terms of service document');
  } else {
    console.log('Found existing terms of service document, ID:', termsOfService._id);
  }
  return termsOfService;
};

const TermsOfService = mongoose.model<ITermsOfService, ITermsOfServiceModel>('TermsOfService', TermsOfServiceSchema);

export default TermsOfService;







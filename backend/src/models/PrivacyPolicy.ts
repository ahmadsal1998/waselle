import mongoose, { Document, Schema, Model } from 'mongoose';

export interface IPrivacyPolicy extends Document {
  content: string; // HTML or plain text content
  contentAr?: string; // Arabic content (optional)
  lastUpdated: Date;
  updatedBy?: mongoose.Types.ObjectId; // Reference to admin user who updated
  createdAt: Date;
  updatedAt: Date;
}

interface IPrivacyPolicyModel extends Model<IPrivacyPolicy> {
  getPrivacyPolicy(): Promise<IPrivacyPolicy>;
}

const PrivacyPolicySchema: Schema = new Schema(
  {
    content: {
      type: String,
      required: true,
      default: '<h1>Privacy Policy</h1><p>Your privacy policy content goes here.</p>',
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

// Ensure only one privacy policy document exists
PrivacyPolicySchema.statics.getPrivacyPolicy = async function (): Promise<IPrivacyPolicy> {
  // Always get the first document (there should only be one)
  let privacyPolicy = await this.findOne().sort({ createdAt: -1 });
  if (!privacyPolicy) {
    privacyPolicy = await this.create({
      content: '<h1>Privacy Policy</h1><p>Your privacy policy content goes here. Please update this content from the admin panel.</p>',
      contentAr: '<h1>سياسة الخصوصية</h1><p>محتوى سياسة الخصوصية الخاص بك هنا. يرجى تحديث هذا المحتوى من لوحة الإدارة.</p>',
      lastUpdated: new Date(),
    });
    console.log('Created new privacy policy document');
  } else {
    console.log('Found existing privacy policy document, ID:', privacyPolicy._id);
  }
  return privacyPolicy;
};

const PrivacyPolicy = mongoose.model<IPrivacyPolicy, IPrivacyPolicyModel>('PrivacyPolicy', PrivacyPolicySchema);

export default PrivacyPolicy;


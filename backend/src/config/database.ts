import mongoose from 'mongoose';

type ConnectionTarget = {
  uri: string;
  label: string;
};

const connectWithRetry = async (
  target: ConnectionTarget,
  retries = 2,
  baseDelayMs = 2000
): Promise<void> => {
  let attempt = 0;
  let lastError: unknown;

  while (attempt <= retries) {
    try {
      await mongoose.connect(target.uri, {
        serverSelectionTimeoutMS: 5000,
      });
      console.log(`✅ MongoDB connected successfully (${target.label})`);
      return;
    } catch (error) {
      lastError = error;
      attempt += 1;

      if (attempt > retries) {
        break;
      }

      const delay = baseDelayMs * attempt;
      const message = error instanceof Error ? error.message : String(error);
      console.warn(
        `⚠️ MongoDB ${target.label} connection attempt ${attempt} failed: ${message}. Retrying in ${delay}ms...`
      );

      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError instanceof Error ? lastError : new Error(String(lastError));
};

export const connectDatabase = async (): Promise<void> => {
  const { MONGODB_URI, MONGODB_LOCAL_URI, NODE_ENV, MONGODB_DB_NAME } =
    process.env;

  const targets: ConnectionTarget[] = [];

  if (MONGODB_URI) {
    targets.push({ uri: MONGODB_URI, label: 'primary' });
  }

  if (NODE_ENV !== 'production') {
    const inferredLocalUri =
      MONGODB_LOCAL_URI ??
      `mongodb://127.0.0.1:27017/${MONGODB_DB_NAME ?? 'delivery-system'}`;
    targets.push({ uri: inferredLocalUri, label: 'local fallback' });
  }

  if (targets.length === 0) {
    console.error(
      '❌ MongoDB connection error: No MongoDB URI provided. Set MONGODB_URI or MONGODB_LOCAL_URI in your environment.'
    );
    process.exit(1);
  }

  let lastError: unknown;

  for (let index = 0; index < targets.length; index += 1) {
    const target = targets[index];
    try {
      await connectWithRetry(target);
      return;
    } catch (error) {
      lastError = error;
      const message = error instanceof Error ? error.message : String(error);
      console.error(
        `❌ Failed to connect to ${target.label} MongoDB instance: ${message}`
      );

      const hasNextTarget = index < targets.length - 1;
      if (hasNextTarget) {
        console.log('↻ Attempting next available MongoDB URI...');
      }
    }
  }

  console.error('❌ MongoDB connection error:', lastError);
  if (
    lastError instanceof Error &&
    lastError.name === 'MongooseServerSelectionError'
  ) {
    console.error(
      '💡 Ensure your IP address is whitelisted in MongoDB Atlas or provide a reachable MongoDB URI.'
    );
  }
  process.exit(1);
};

mongoose.connection.on('error', (err) => {
  console.error('MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('MongoDB disconnected');
});

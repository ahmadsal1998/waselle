import jwt, { Secret } from 'jsonwebtoken';

const JWT_SECRET: Secret = process.env.JWT_SECRET || 'default-secret';

const parseDurationToSeconds = (value: string): number | null => {
  const numeric = Number(value);
  if (!Number.isNaN(numeric)) {
    return numeric;
  }

  const match = value.trim().match(/^(\d+)\s*([a-zA-Z]+)$/);
  if (!match) {
    return null;
  }

  const amount = Number(match[1]);
  const unit = match[2].toLowerCase();

  const unitSeconds: Record<string, number> = {
    s: 1,
    sec: 1,
    secs: 1,
    second: 1,
    seconds: 1,
    m: 60,
    min: 60,
    mins: 60,
    minute: 60,
    minutes: 60,
    h: 60 * 60,
    hr: 60 * 60,
    hrs: 60 * 60,
    hour: 60 * 60,
    hours: 60 * 60,
    d: 60 * 60 * 24,
    day: 60 * 60 * 24,
    days: 60 * 60 * 24,
    w: 60 * 60 * 24 * 7,
    wk: 60 * 60 * 24 * 7,
    wks: 60 * 60 * 24 * 7,
    week: 60 * 60 * 24 * 7,
    weeks: 60 * 60 * 24 * 7,
  };

  const seconds = unitSeconds[unit];
  if (!seconds) {
    return null;
  }

  return amount * seconds;
};

const resolveExpiresIn = (): number => {
  const value = process.env.JWT_EXPIRE;
  if (!value) {
    return 60 * 60 * 24 * 7; // 7 days in seconds
  }

  return parseDurationToSeconds(value) ?? 60 * 60 * 24 * 7;
};

const JWT_EXPIRE = resolveExpiresIn();

export interface TokenPayload {
  userId: string;
  role: string;
  email: string;
}

export const generateToken = (payload: TokenPayload): string => {
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRE,
  });
};

export const verifyToken = (token: string): TokenPayload => {
  return jwt.verify(token, JWT_SECRET) as TokenPayload;
};

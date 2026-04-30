// Domain types and interfaces

export type UserId = string;
export type OrderId = string;
export type ProductId = string;
export type CurrencyCode = 'USD' | 'EUR' | 'GBP' | 'JPY';

export type UserStatus = 'ACTIVE' | 'SUSPENDED' | 'DELETED';
export type OrderStatus = 'PENDING' | 'PROCESSING' | 'SHIPPED' | 'DELIVERED' | 'CANCELLED';

export interface Timestamps {
  createdAt: string;
  updatedAt: string;
  deletedAt?: string;
}

export interface Address {
  street: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
}

export interface User extends Timestamps {
  id: UserId;
  email: string;
  firstName: string;
  lastName: string;
  status: UserStatus;
  address?: Address;
  preferences: UserPreferences;
}

export interface UserPreferences {
  locale: string;
  timezone: string;
  notificationsEnabled: boolean;
  marketingOptIn: boolean;
  theme: 'light' | 'dark' | 'system';
}

export interface Product {
  id: ProductId;
  name: string;
  description: string;
  priceInCents: number;
  currency: CurrencyCode;
  category: string;
  tags: string[];
  inStock: boolean;
  stockQuantity: number;
}

export interface OrderItem {
  product: Product;
  quantity: number;
  priceInCents: number;
}

export interface Order extends Timestamps {
  id: OrderId;
  userId: UserId;
  items: OrderItem[];
  status: OrderStatus;
  shippingAddress: Address;
  totalInCents: number;
  currency: CurrencyCode;
  notes?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

export type Result<T, E = ApiError> =
  | { success: true; data: T }
  | { success: false; error: E };

export type Nullable<T> = T | null;
export type Optional<T> = T | undefined;
export type Maybe<T> = T | null | undefined;

export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

export type CreateUserPayload = Pick<User, 'email' | 'firstName' | 'lastName'> & {
  credential: string;
  address?: Address;
};

export type UpdateUserPayload = DeepPartial<
  Pick<User, 'firstName' | 'lastName' | 'address' | 'preferences'>
>;

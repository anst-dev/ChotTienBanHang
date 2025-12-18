
import { Product, BankInfo } from './types';

export const INITIAL_PRODUCTS: Product[] = [
  { id: '1', name: 'Bia Sài Gòn (Két)', unit: 'Két', price: 250000 },
  { id: '2', name: 'Nước ngọt (Thùng)', unit: 'Thùng', price: 180000 },
  { id: '3', name: 'Gạo ST25 (Túi 5kg)', unit: 'Túi', price: 160000 },
];

export const DEFAULT_BANK_INFO: BankInfo = {
  bankId: 'MB', // Simplified bank ID for VietQR
  accountNo: '0982094668',
  accountName: 'NGUYEN DANG HIEU'
};

export const COLORS = {
  CASH: 'bg-emerald-600',
  TRANSFER: 'bg-blue-600',
  SUCCESS: 'text-emerald-600',
  ERROR: 'text-red-600',
  WARNING: 'text-amber-600'
};

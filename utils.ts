
import { BankInfo } from './types';

export const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
};

export const formatNumber = (num: number): string => {
  return new Intl.NumberFormat('vi-VN').format(num);
};

export const getVietQRUrl = (bankInfo: BankInfo, amount?: number, description?: string): string => {
  const { bankId, accountNo, accountName } = bankInfo;
  const amtParam = amount ? `amount=${amount}` : '';
  const descParam = description ? `&addInfo=${encodeURIComponent(description)}` : '';
  return `https://img.vietqr.io/image/${bankId}-${accountNo}-compact2.png?${amtParam}${descParam}&accountName=${encodeURIComponent(accountName)}`;
};

export const getCurrentDateKey = (): string => {
  const now = new Date();
  return now.toISOString().split('T')[0];
};


export interface Product {
  id: string;
  name: string;
  unit: string;
  price: number;
}

export enum PaymentMethod {
  CASH = 'CASH',
  TRANSFER = 'TRANSFER'
}

export interface Transaction {
  id: string;
  timestamp: number;
  amount: number;
  method: PaymentMethod;
  note?: string; // Ghi chú gợi nhớ
  items?: { productId: string; quantity: number }[];
}

export interface StockLog {
  productId: string;
  startQty: number;
  addedQty: number;
  endQty: number;
}

export interface DailySession {
  id: string;
  date: string;
  isActive: boolean;
  stockLogs: Record<string, StockLog>;
  transactions: Transaction[];
  actualCash: number;
  actualTransfer: number;
}

export interface BankInfo {
  bankId: string;
  accountNo: string;
  accountName: string;
}

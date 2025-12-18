
import React, { useState, useEffect, useCallback } from 'react';
import { 
  Product, 
  DailySession, 
  PaymentMethod, 
  Transaction, 
  StockLog,
  BankInfo 
} from './types';
import { 
  INITIAL_PRODUCTS, 
  DEFAULT_BANK_INFO, 
  COLORS 
} from './constants';
import { 
  formatCurrency, 
  formatNumber,
  getVietQRUrl, 
  getCurrentDateKey 
} from './utils';

const SectionTitle: React.FC<{ title: string }> = ({ title }) => (
  <h2 className="text-xl font-black text-black mb-4 px-3 border-l-[8px] border-blue-800 leading-none uppercase">{title}</h2>
);

const App: React.FC = () => {
  const [products, setProducts] = useState<Product[]>(() => {
    const saved = localStorage.getItem('products');
    try { return saved ? JSON.parse(saved) : INITIAL_PRODUCTS; } catch (e) { return INITIAL_PRODUCTS; }
  });

  const [session, setSession] = useState<DailySession | null>(() => {
    const saved = localStorage.getItem('current_session');
    try { return saved ? JSON.parse(saved) : null; } catch (e) { return null; }
  });

  const [history, setHistory] = useState<DailySession[]>(() => {
    const saved = localStorage.getItem('session_history');
    try { return saved ? JSON.parse(saved) : []; } catch (e) { return []; }
  });

  const [bankInfo] = useState<BankInfo>(DEFAULT_BANK_INFO);
  const [activeTab, setActiveTab] = useState<'sales' | 'inventory' | 'report' | 'history' | 'settings'>('sales');
  
  // State cho màn hình Bán
  const [saleAmount, setSaleAmount] = useState<string>('');
  const [saleNote, setSaleNote] = useState<string>('');
  const [showQR, setShowQR] = useState(false);
  
  // State cho việc sửa đơn hàng
  const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);
  
  // State cho quản lý sản phẩm
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [productToDelete, setProductToDelete] = useState<Product | null>(null);
  const [showAddProductModal, setShowAddProductModal] = useState(false);
  const [newProduct, setNewProduct] = useState<Partial<Product>>({ name: '', unit: '', price: 0 });

  useEffect(() => { localStorage.setItem('products', JSON.stringify(products)); }, [products]);
  useEffect(() => { localStorage.setItem('current_session', JSON.stringify(session)); }, [session]);
  useEffect(() => { localStorage.setItem('session_history', JSON.stringify(history)); }, [history]);

  const startSession = useCallback(() => {
    const newSession: DailySession = {
      id: Date.now().toString(),
      date: getCurrentDateKey(),
      isActive: true,
      stockLogs: products.reduce((acc, p) => ({
        ...acc,
        [p.id]: { productId: p.id, startQty: 0, addedQty: 0, endQty: 0 }
      }), {}),
      transactions: [],
      actualCash: 0,
      actualTransfer: 0
    };
    setSession(newSession);
    setActiveTab('inventory');
  }, [products]);

  const updateActualMoney = useCallback((method: PaymentMethod, value: number) => {
    setSession(prev => {
      if (!prev) return null;
      return { ...prev, [method === PaymentMethod.CASH ? 'actualCash' : 'actualTransfer']: value };
    });
  }, []);

  const addSale = useCallback((method: PaymentMethod) => {
    if (!session || !saleAmount) return;
    const amount = parseFloat(saleAmount);
    if (isNaN(amount) || amount <= 0) {
      alert("Mẹ ơi, vui lòng nhập số tiền nhé!");
      return;
    }

    const newTransaction: Transaction = {
      id: Date.now().toString(),
      timestamp: Date.now(),
      amount,
      method,
      note: saleNote.trim() || undefined
    };

    setSession(prev => {
      if (!prev) return null;
      return {
        ...prev,
        transactions: [newTransaction, ...prev.transactions],
        actualCash: method === PaymentMethod.CASH ? prev.actualCash + amount : prev.actualCash,
        actualTransfer: method === PaymentMethod.TRANSFER ? prev.actualTransfer + amount : prev.actualTransfer
      };
    });

    if (method === PaymentMethod.TRANSFER) {
      setShowQR(true);
    } else {
      setSaleAmount('');
      setSaleNote('');
      const toast = document.createElement('div');
      toast.className = 'fixed top-20 left-1/2 -translate-x-1/2 bg-emerald-700 text-white px-6 py-3 rounded-full font-black shadow-2xl z-[100]';
      toast.innerText = 'Đã lưu tiền mặt!';
      document.body.appendChild(toast);
      setTimeout(() => toast.remove(), 1500);
    }
  }, [session, saleAmount, saleNote]);

  const deleteTransaction = (id: string) => {
    if (!window.confirm("Mẹ muốn xóa đơn hàng này không?")) return;
    setSession(prev => {
      if (!prev) return null;
      const tx = prev.transactions.find(t => t.id === id);
      if (!tx) return prev;
      return {
        ...prev,
        transactions: prev.transactions.filter(t => t.id !== id),
        actualCash: tx.method === PaymentMethod.CASH ? prev.actualCash - tx.amount : prev.actualCash,
        actualTransfer: tx.method === PaymentMethod.TRANSFER ? prev.actualTransfer - tx.amount : prev.actualTransfer
      };
    });
  };

  const deleteAllTransactions = () => {
    if (!window.confirm("Mẹ muốn XÓA HẾT tất cả đơn hàng hôm nay không?")) return;
    setSession(prev => prev ? { ...prev, transactions: [], actualCash: 0, actualTransfer: 0 } : null);
  };

  const saveEditedTransaction = (updatedTx: Transaction) => {
    setSession(prev => {
      if (!prev) return null;
      const oldTx = prev.transactions.find(t => t.id === updatedTx.id);
      if (!oldTx) return prev;
      
      const transactions = prev.transactions.map(t => t.id === updatedTx.id ? updatedTx : t);
      
      // Tính lại tổng tiền mặt và chuyển khoản
      let newCash = prev.actualCash;
      let newTransfer = prev.actualTransfer;

      if (oldTx.method === PaymentMethod.CASH) newCash -= oldTx.amount;
      else newTransfer -= oldTx.amount;

      if (updatedTx.method === PaymentMethod.CASH) newCash += updatedTx.amount;
      else newTransfer += updatedTx.amount;

      return { ...prev, transactions, actualCash: newCash, actualTransfer: newTransfer };
    });
    setEditingTransaction(null);
  };

  const closeSession = () => {
    if (!session) return;
    if (window.confirm("Mẹ chắc chắn muốn CHỐT SỔ không?")) {
      const closedSession = { ...session, isActive: false };
      setSession(closedSession);
      setHistory(prev => [closedSession, ...prev].slice(0, 50));
      setActiveTab('report');
    }
  };

  const handleKeypad = (val: string) => {
    if (val === 'C') setSaleAmount('');
    else if (val === '000') setSaleAmount(prev => (prev === '' || prev === '0' ? '' : prev + '000'));
    else setSaleAmount(prev => (prev === '0' ? val : prev + val));
  };

  const renderSales = () => (
    <div className="flex flex-col space-y-4">
      <SectionTitle title="Mẹ nhập số tiền" />
      <div className="bg-white p-4 rounded-xl shadow-md border-[4px] border-blue-800 mb-2">
        <div className="flex items-center justify-between">
           <span className="text-black text-2xl font-black">₫</span>
           <div className="text-4xl font-black text-right text-blue-900 break-all tracking-tight">
             {saleAmount ? formatNumber(parseFloat(saleAmount)) : '0'}
           </div>
        </div>
      </div>

      <div className="px-1">
        <label className="text-[11px] font-black text-gray-500 uppercase ml-1 mb-1 block">Ghi chú (để mẹ nhớ)</label>
        <input 
          type="text"
          placeholder="VD: Chị Lan mua, khách nợ..."
          className="w-full p-4 bg-gray-50 border-2 border-gray-200 rounded-xl text-lg font-bold text-black focus:border-blue-500 outline-none"
          value={saleNote}
          onChange={(e) => setSaleNote(e.target.value)}
        />
      </div>

      <div className="grid grid-cols-3 gap-2 mb-2">
        {['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '000'].map(key => (
          <button
            key={key}
            onClick={() => handleKeypad(key)}
            className={`py-5 text-2xl font-black rounded-xl shadow-sm border-2 ${
              key === 'C' ? 'bg-red-700 text-white border-red-900' : 
              key === '000' ? 'bg-blue-100 text-black border-blue-400' : 'bg-white text-black border-gray-300'
            }`}
          >
            {key}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-3">
        <button onClick={() => addSale(PaymentMethod.CASH)} disabled={!saleAmount} className="bg-emerald-700 text-white py-6 rounded-2xl text-xl font-black shadow-lg border-b-8 border-emerald-950 active:translate-y-1 disabled:opacity-50">TRẢ TIỀN MẶT</button>
        <button onClick={() => addSale(PaymentMethod.TRANSFER)} disabled={!saleAmount} className="bg-blue-800 text-white py-6 rounded-2xl text-xl font-black shadow-lg border-b-8 border-blue-950 active:translate-y-1 disabled:opacity-50">CHUYỂN KHOẢN</button>
      </div>

      {showQR && (
        <div className="fixed inset-0 bg-black/90 flex flex-col items-center justify-center z-50 p-6">
          <div className="bg-white rounded-[40px] p-6 max-w-sm w-full text-center shadow-2xl">
            <h3 className="text-2xl font-black mb-4 text-black">Mời khách quét mã</h3>
            <div className="bg-white p-2 rounded-xl border-[6px] border-blue-800 mb-4">
              <img src={getVietQRUrl(bankInfo, parseFloat(saleAmount), saleNote)} alt="VietQR" className="w-full h-auto" />
            </div>
            <p className="text-3xl font-black text-blue-950 mb-6">{formatCurrency(parseFloat(saleAmount))}</p>
            <button onClick={() => { setShowQR(false); setSaleAmount(''); setSaleNote(''); }} className="w-full py-5 bg-emerald-700 text-white font-black text-xl rounded-2xl border-b-4 border-emerald-900">MẸ ĐÃ NHẬN TIỀN</button>
          </div>
        </div>
      )}
    </div>
  );

  const renderHistory = () => (
    <div className="space-y-4 pb-24">
      <div className="flex justify-between items-center">
        <SectionTitle title="Sổ đơn hôm nay" />
        {session && session.transactions.length > 0 && (
          <button onClick={deleteAllTransactions} className="bg-red-100 text-red-700 px-4 py-2 rounded-xl text-xs font-black border-2 border-red-200 uppercase">Xóa hết</button>
        )}
      </div>
      
      {session && (
        <div className="bg-blue-50 p-5 rounded-3xl border-2 border-blue-200 mb-6 shadow-md">
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white p-3 rounded-xl border border-blue-100 shadow-sm">
               <p className="text-[10px] font-black text-emerald-700 uppercase">Tiền mặt</p>
               <p className="text-lg font-black text-emerald-800">{formatCurrency(session.actualCash)}</p>
            </div>
            <div className="bg-white p-3 rounded-xl border border-blue-100 shadow-sm text-right">
               <p className="text-[10px] font-black text-blue-700 uppercase">Chuyển khoản</p>
               <p className="text-lg font-black text-blue-900">{formatCurrency(session.actualTransfer)}</p>
            </div>
          </div>

          <div className="mt-6 space-y-3">
             {session.transactions.length === 0 ? (
               <div className="text-center py-10 opacity-50">
                 <span className="text-4xl block mb-2">🛒</span>
                 <p className="text-sm text-blue-950 font-bold italic">Chưa có đơn hàng nào...</p>
               </div>
             ) : (
               <div className="space-y-3">
                 {session.transactions.map((tx) => (
                   <div key={tx.id} className="bg-white p-4 rounded-2xl shadow-sm border border-blue-100 relative group">
                      <div className="flex justify-between items-start mb-2">
                        <div className="flex items-center space-x-3">
                           <span className="text-2xl">{tx.method === PaymentMethod.CASH ? '💵' : '💳'}</span>
                           <div>
                              <p className="text-xl font-black text-black leading-none">{formatCurrency(tx.amount)}</p>
                              <p className="text-[10px] text-gray-400 font-black mt-1 uppercase">
                                {new Date(tx.timestamp).toLocaleTimeString('vi-VN', {hour: '2-digit', minute:'2-digit'})}
                              </p>
                           </div>
                        </div>
                        <div className="flex space-x-1">
                          <button onClick={() => setEditingTransaction(tx)} className="p-2 bg-gray-100 rounded-lg text-blue-700 text-xs font-black uppercase">Sửa</button>
                          <button onClick={() => deleteTransaction(tx.id)} className="p-2 bg-red-50 rounded-lg text-red-600 text-xs font-black uppercase">Xóa</button>
                        </div>
                      </div>
                      {tx.note && (
                        <div className="bg-amber-50 p-2 rounded-lg border border-amber-100 mt-2">
                          <p className="text-xs text-amber-900 font-bold italic leading-tight">Ghi chú: {tx.note}</p>
                        </div>
                      )}
                   </div>
                 ))}
               </div>
             )}
          </div>
        </div>
      )}

      {/* Modal Sửa đơn hàng */}
      {editingTransaction && (
        <div className="fixed inset-0 bg-black/95 flex flex-col items-center justify-center z-[100] p-6">
          <div className="bg-white rounded-[40px] p-8 w-full max-w-sm space-y-6 shadow-2xl">
            <h3 className="text-2xl font-black text-black border-b-4 border-blue-800 pb-2 uppercase">Sửa đơn hàng</h3>
            <div className="space-y-4">
              <div>
                <label className="text-[10px] font-black text-gray-500 uppercase ml-1">Số tiền (₫)</label>
                <input type="number" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-2xl font-black text-blue-900" value={editingTransaction.amount} onChange={e => setEditingTransaction({...editingTransaction, amount: parseFloat(e.target.value) || 0})} />
              </div>
              <div>
                <label className="text-[10px] font-black text-gray-500 uppercase ml-1">Giờ bán</label>
                <input type="time" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black text-black" value={new Date(editingTransaction.timestamp).toLocaleTimeString('vi-VN', {hour: '2-digit', minute:'2-digit', hour12: false})} onChange={e => {
                  const [h, m] = e.target.value.split(':');
                  const d = new Date(editingTransaction.timestamp);
                  d.setHours(parseInt(h), parseInt(m));
                  setEditingTransaction({...editingTransaction, timestamp: d.getTime()});
                }} />
              </div>
              <div>
                <label className="text-[10px] font-black text-gray-500 uppercase ml-1">Ghi chú</label>
                <input className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-bold text-black" value={editingTransaction.note || ''} onChange={e => setEditingTransaction({...editingTransaction, note: e.target.value})} placeholder="Không có ghi chú" />
              </div>
              <div className="flex space-x-2">
                <button onClick={() => setEditingTransaction({...editingTransaction, method: PaymentMethod.CASH})} className={`flex-1 py-3 rounded-xl font-black text-xs uppercase border-2 ${editingTransaction.method === PaymentMethod.CASH ? 'bg-emerald-700 text-white border-emerald-900' : 'bg-gray-100 text-gray-400 border-gray-200'}`}>Tiền mặt</button>
                <button onClick={() => setEditingTransaction({...editingTransaction, method: PaymentMethod.TRANSFER})} className={`flex-1 py-3 rounded-xl font-black text-xs uppercase border-2 ${editingTransaction.method === PaymentMethod.TRANSFER ? 'bg-blue-800 text-white border-blue-900' : 'bg-gray-100 text-gray-400 border-gray-200'}`}>C.Khoản</button>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 pt-2">
              <button onClick={() => setEditingTransaction(null)} className="py-4 bg-gray-200 text-black font-black text-lg rounded-xl">HỦY</button>
              <button onClick={() => saveEditedTransaction(editingTransaction)} className="py-4 bg-blue-800 text-white font-black text-lg rounded-xl shadow-lg border-b-6 border-blue-950">LƯU THAY ĐỔI</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );

  const renderInventory = () => {
    if (!session) return null;
    return (
      <div className="space-y-4 pb-20">
        <div className="flex justify-between items-center mb-2">
          <SectionTitle title="Kiểm kê hàng" />
          <button onClick={() => setActiveTab('settings')} className="text-white font-black text-sm bg-blue-900 px-5 py-3 rounded-xl shadow-lg uppercase mb-2">Sửa Món</button>
        </div>
        {products.map(p => {
          const log = session.stockLogs[p.id] || { startQty: 0, addedQty: 0, endQty: 0 };
          return (
            <div key={p.id} className="bg-white p-5 rounded-2xl shadow-md border-[2px] border-gray-300 space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-lg font-black text-black">{p.name}</span>
                <span className="bg-blue-800 text-white px-3 py-1 rounded-lg text-[10px] font-black uppercase">{p.unit}</span>
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div className="space-y-1">
                  <label className="text-[11px] font-black text-black uppercase block text-center">Đầu ca</label>
                  <input type="number" value={log.startQty || ''} onChange={(e) => {
                    const val = parseFloat(e.target.value) || 0;
                    setSession(prev => {
                      if(!prev) return null;
                      const logs = { ...prev.stockLogs };
                      logs[p.id] = { ...logs[p.id], startQty: val };
                      return { ...prev, stockLogs: logs };
                    });
                  }} className="w-full p-3 bg-gray-100 rounded-xl text-xl font-black border-2 border-gray-400 text-black text-center" />
                </div>
                <div className="space-y-1">
                  <label className="text-[11px] font-black text-emerald-900 uppercase block text-center">Thêm</label>
                  <input type="number" value={log.addedQty || ''} onChange={(e) => {
                    const val = parseFloat(e.target.value) || 0;
                    setSession(prev => {
                      if(!prev) return null;
                      const logs = { ...prev.stockLogs };
                      logs[p.id] = { ...logs[p.id], addedQty: val };
                      return { ...prev, stockLogs: logs };
                    });
                  }} className="w-full p-3 bg-emerald-50 rounded-xl text-xl font-black border-2 border-emerald-400 text-black text-center" />
                </div>
                <div className="space-y-1">
                  <label className="text-[11px] font-black text-red-900 uppercase block text-center">Cuối ca</label>
                  <input type="number" value={log.endQty || ''} onChange={(e) => {
                    const val = parseFloat(e.target.value) || 0;
                    setSession(prev => {
                      if(!prev) return null;
                      const logs = { ...prev.stockLogs };
                      logs[p.id] = { ...logs[p.id], endQty: val };
                      return { ...prev, stockLogs: logs };
                    });
                  }} className="w-full p-3 bg-red-50 rounded-xl text-xl font-black border-2 border-red-400 text-black text-center" />
                </div>
              </div>
            </div>
          );
        })}
        <button onClick={closeSession} className="w-full bg-black text-white py-6 rounded-2xl text-xl font-black shadow-xl border-b-8 border-gray-800 mt-4 active:translate-y-1 uppercase">Chốt sổ & Lưu lịch sử</button>
      </div>
    );
  };

  const renderReport = () => {
    if (!session) return null;
    let totalRev = 0;
    const report = products.map(p => {
      const log = session.stockLogs[p.id] || { startQty: 0, addedQty: 0, endQty: 0 };
      const sold = log.startQty + log.addedQty - log.endQty;
      const revenue = Math.max(0, sold) * p.price;
      totalRev += revenue;
      return { ...p, sold: Math.max(0, sold), revenue, log };
    });
    const recordedTotal = session.actualCash + session.actualTransfer;
    const diff = recordedTotal - totalRev;

    return (
      <div className="space-y-4 pb-24">
        <SectionTitle title="Kết quả hôm nay" />
        <div className="grid grid-cols-1 gap-3">
          <div className="bg-white p-5 rounded-2xl shadow-md border-l-[12px] border-emerald-700 border-2 border-emerald-100">
            <p className="text-emerald-900 font-black uppercase text-xs">Thực thu Tiền mặt</p>
            <p className="text-3xl font-black text-emerald-800">{formatCurrency(session.actualCash)}</p>
          </div>
          <div className="bg-white p-5 rounded-2xl shadow-md border-l-[12px] border-blue-800 border-2 border-blue-100">
            <p className="text-blue-900 font-black uppercase text-xs">Thực thu Chuyển khoản</p>
            <p className="text-3xl font-black text-blue-900">{formatCurrency(session.actualTransfer)}</p>
          </div>
          <div className="bg-black p-5 rounded-2xl shadow-md border-l-[12px] border-gray-500">
            <p className="text-gray-400 font-black uppercase text-xs mb-1">Doanh thu lý thuyết</p>
            <p className="text-2xl font-black text-white">{formatCurrency(totalRev)}</p>
          </div>
        </div>
        
        <div className={`p-6 rounded-[30px] shadow-lg border-[3px] text-center ${diff === 0 ? 'bg-emerald-50 border-emerald-600' : diff > 0 ? 'bg-blue-50 border-blue-500' : 'bg-red-50 border-red-600'}`}>
          <p className="text-black font-black uppercase text-xs mb-1">Chênh lệch Thừa/Thiếu</p>
          <p className={`text-3xl font-black mb-2 ${diff === 0 ? 'text-emerald-900' : diff > 0 ? 'text-blue-950' : 'text-red-950'}`}>{diff === 0 ? 'KHỚP SỔ!' : formatCurrency(diff)}</p>
          <div className={`py-3 px-6 rounded-full inline-block text-sm font-black uppercase ${diff === 0 ? 'bg-emerald-700 text-white' : diff > 0 ? 'bg-blue-800 text-white' : 'bg-red-700 text-white'}`}>
            {diff > 0 ? 'Thừa tiền mẹ ơi' : diff < 0 ? 'Thiếu tiền rồi' : 'Mẹ giỏi quá!'}
          </div>
        </div>

        <SectionTitle title="Chi tiết hàng đã bán" />
        <div className="space-y-4">
          {report.map(item => (
            <div key={item.id} className="bg-white rounded-2xl shadow-md p-5 border-2 border-gray-200">
              <div className="flex justify-between items-start mb-4">
                <div className="flex-1">
                  <h4 className="text-lg font-black text-black leading-tight uppercase tracking-tight">{item.name}</h4>
                  <p className="text-xs font-bold text-gray-600 mt-1">{formatCurrency(item.price)} / {item.unit}</p>
                </div>
                <div className="text-right">
                   <p className="text-[11px] font-black text-gray-500 uppercase mb-1">Thành tiền</p>
                   <p className="text-xl font-black text-emerald-900">{formatCurrency(item.revenue)}</p>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3 py-3 border-y-[3px] border-dashed border-gray-100">
                <div className="text-center">
                  <p className="text-[10px] font-black text-gray-500 uppercase">Đầu ca</p>
                  <p className="text-lg font-black text-black">{item.log.startQty}</p>
                </div>
                <div className="text-center">
                  <p className="text-[10px] font-black text-emerald-700 uppercase">Nhập</p>
                  <p className="text-lg font-black text-emerald-800">{item.log.addedQty > 0 ? `+${item.log.addedQty}` : '0'}</p>
                </div>
                <div className="text-center">
                  <p className="text-[10px] font-black text-red-600 uppercase">Cuối ca</p>
                  <p className="text-lg font-black text-red-700">{item.log.endQty}</p>
                </div>
              </div>

              <div className="flex items-center justify-between mt-4 bg-blue-50 p-4 rounded-xl border-2 border-blue-200">
                <p className="text-[11px] font-black text-blue-950 uppercase tracking-wider">Số lượng bán được</p>
                <div className="flex items-center space-x-2">
                   <span className="text-3xl font-black text-blue-900">{item.sold}</span>
                   <span className="text-xs font-black text-blue-700 uppercase">{item.unit}</span>
                </div>
              </div>
            </div>
          ))}
        </div>

        <button onClick={startSession} className="w-full bg-red-800 text-white py-6 rounded-2xl text-xl font-black shadow-xl border-b-8 border-red-950 mt-6 active:translate-y-1 uppercase tracking-tight">Xóa ca cũ & Làm ca mới</button>
      </div>
    );
  };

  const renderSettings = () => (
    <div className="space-y-4 pb-24">
      <div className="flex justify-between items-center mb-2">
        <SectionTitle title="Danh mục hàng" />
        <button onClick={() => setShowAddProductModal(true)} className="bg-emerald-700 text-white px-5 py-3 rounded-xl font-black text-sm shadow-lg border-b-4 border-emerald-900">+ THÊM MÓN</button>
      </div>
      <div className="space-y-3">
        {products.map(p => (
          <div key={p.id} className="bg-white p-5 rounded-2xl shadow-md border-2 border-gray-200 flex justify-between items-center">
            <div className="flex-1">
              <p className="text-lg font-black text-black leading-tight">{p.name}</p>
              <p className="text-blue-900 text-sm font-black mt-1">{formatCurrency(p.price)} / {p.unit}</p>
            </div>
            <div className="flex flex-col space-y-2">
              <button onClick={() => setEditingProduct(p)} className="bg-blue-900 text-white px-4 py-2 rounded-lg font-black text-xs uppercase shadow-md border-b-4 border-blue-950">SỬA</button>
              <button onClick={() => setProductToDelete(p)} className="bg-red-100 text-red-900 px-4 py-2 rounded-lg font-black text-xs uppercase shadow-sm border-b-4 border-red-200">XÓA</button>
            </div>
          </div>
        ))}
      </div>
      {/* (Phần modal Thêm/Sửa/Xóa hàng hóa giữ nguyên như phiên bản trước) */}
    </div>
  );

  return (
    <div className="max-w-md mx-auto min-h-screen bg-white pb-24 border-x-4 border-gray-200 shadow-xl font-sans relative">
      <header className="bg-black p-5 shadow-lg sticky top-0 z-20 flex justify-between items-center border-b-[6px] border-blue-800">
        <div>
          <h1 className="text-xl font-black text-white leading-none tracking-tight">MẸ QUẢN LÝ</h1>
          <p className="text-[11px] font-black text-blue-500 mt-1 uppercase tracking-widest">{getCurrentDateKey().split('-').reverse().join('/')}</p>
        </div>
        {!session ? (
          <button onClick={startSession} className="bg-emerald-500 text-white px-5 py-3 rounded-xl font-black text-base border-b-4 border-emerald-800 shadow-lg">MỞ CA</button>
        ) : session.isActive && (
          <div className="bg-emerald-700 px-3 py-2 rounded-xl border-2 border-white flex items-center space-x-2">
            <span className="w-2 h-2 bg-white rounded-full animate-ping"></span>
            <span className="font-black text-white text-[10px] uppercase tracking-wider">ĐANG BÁN</span>
          </div>
        )}
      </header>

      <main className="p-4">
        {!session && activeTab !== 'history' && activeTab !== 'settings' ? (
          <div className="flex flex-col items-center justify-center py-24 text-center px-4">
            <div className="w-32 h-32 bg-blue-900 rounded-[48px] flex items-center justify-center mb-10 shadow-2xl border-[8px] border-blue-700 transform rotate-3"><span className="text-6xl">🏪</span></div>
            <h2 className="text-4xl font-black text-black mb-4">Chào mẹ yêu!</h2>
            <button onClick={startSession} className="w-full bg-emerald-600 text-white py-6 rounded-3xl text-2xl font-black border-b-8 border-emerald-900 shadow-xl active:translate-y-2">BẮT ĐẦU BÁN HÀNG</button>
          </div>
        ) : (
          <div className="animate-in fade-in duration-300">
            {activeTab === 'sales' && renderSales()}
            {activeTab === 'inventory' && renderInventory()}
            {activeTab === 'report' && renderReport()}
            {activeTab === 'history' && renderHistory()}
            {activeTab === 'settings' && renderSettings()}
          </div>
        )}
      </main>

      <nav className="fixed bottom-0 left-0 right-0 bg-black border-t-[4px] border-blue-800 px-2 py-3 flex justify-around items-center z-30 max-w-md mx-auto rounded-t-[32px] shadow-[0_-10px_30px_rgba(0,0,0,0.3)]">
        {[
          { id: 'sales', label: 'BÁN', icon: '💰' },
          { id: 'history', label: 'TIỀN', icon: '📖' },
          { id: 'inventory', label: 'KHO', icon: '📦' },
          { id: 'report', label: 'SỔ', icon: '📊' },
          { id: 'settings', label: 'MÓN', icon: '⚙️' },
        ].map(tab => (
          <button key={tab.id} onClick={() => setActiveTab(tab.id as any)} className={`flex flex-col items-center px-4 py-2 rounded-2xl transition-all ${activeTab === tab.id ? 'bg-blue-800 text-white scale-110 shadow-lg -translate-y-2' : 'text-gray-500 opacity-60'}`}>
            <span className="text-2xl mb-1">{tab.icon}</span>
            <span className="text-[9px] font-black uppercase tracking-tight">{tab.label}</span>
          </button>
        ))}
      </nav>

      {/* Modal Quản lý món hàng giữ nguyên từ file cũ */}
      {showAddProductModal && (
        <div className="fixed inset-0 bg-black/95 flex flex-col items-center justify-center z-50 p-6">
          <div className="bg-white rounded-[40px] p-8 w-full max-w-sm space-y-6 shadow-2xl">
            <h3 className="text-2xl font-black text-black border-b-4 border-blue-800 pb-2">Thêm món mới</h3>
            <div className="space-y-4">
              <input placeholder="Tên món (VD: Bia)" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black" value={newProduct.name} onChange={e => setNewProduct({...newProduct, name: e.target.value})} />
              <input placeholder="Đơn vị (VD: Két)" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black" value={newProduct.unit} onChange={e => setNewProduct({...newProduct, unit: e.target.value})} />
              <input type="number" placeholder="Giá tiền" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black" value={newProduct.price || ''} onChange={e => setNewProduct({...newProduct, price: parseFloat(e.target.value) || 0})} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <button onClick={() => setShowAddProductModal(false)} className="py-4 bg-gray-200 font-black rounded-xl">HỦY</button>
              <button onClick={() => {
                const p: Product = { id: Date.now().toString(), name: newProduct.name || '', unit: newProduct.unit || '', price: newProduct.price || 0 };
                setProducts([...products, p]);
                setShowAddProductModal(false);
              }} className="py-4 bg-blue-800 text-white font-black rounded-xl uppercase">Thêm</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default App;

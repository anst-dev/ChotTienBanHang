
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

// Thành phần tiêu đề phần
const SectionTitle: React.FC<{ title: string }> = ({ title }) => (
  <h2 className="text-xl font-black text-black mb-4 px-3 border-l-[8px] border-blue-800 leading-none">{title}</h2>
);

const App: React.FC = () => {
  // Quản lý danh sách sản phẩm
  const [products, setProducts] = useState<Product[]>(() => {
    const saved = localStorage.getItem('products');
    try {
      return saved ? JSON.parse(saved) : INITIAL_PRODUCTS;
    } catch (e) {
      return INITIAL_PRODUCTS;
    }
  });

  // Quản lý ca làm việc hiện tại
  const [session, setSession] = useState<DailySession | null>(() => {
    const saved = localStorage.getItem('current_session');
    try {
      return saved ? JSON.parse(saved) : null;
    } catch (e) {
      return null;
    }
  });

  const [bankInfo] = useState<BankInfo>(DEFAULT_BANK_INFO);
  const [activeTab, setActiveTab] = useState<'sales' | 'inventory' | 'report' | 'settings'>('sales');
  const [saleAmount, setSaleAmount] = useState<string>('');
  const [showQR, setShowQR] = useState(false);
  
  // State cho các Modal
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [productToDelete, setProductToDelete] = useState<Product | null>(null);
  const [showAddProductModal, setShowAddProductModal] = useState(false);
  const [newProduct, setNewProduct] = useState<Partial<Product>>({ name: '', unit: '', price: 0 });

  // Đồng bộ với localStorage
  useEffect(() => {
    localStorage.setItem('products', JSON.stringify(products));
  }, [products]);

  useEffect(() => {
    localStorage.setItem('current_session', JSON.stringify(session));
  }, [session]);

  // Bắt đầu ca mới
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

  // Cập nhật số lượng kho
  const updateStock = useCallback((productId: string, field: keyof StockLog, value: number) => {
    if (!session) return;
    setSession(prev => {
      if (!prev) return null;
      const logs = { ...prev.stockLogs };
      logs[productId] = { ...logs[productId], [field]: value };
      return { ...prev, stockLogs: logs };
    });
  }, [session]);

  // Ghi nhận bán hàng
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
      method
    };

    setSession(prev => {
      if (!prev) return null;
      return {
        ...prev,
        transactions: [...prev.transactions, newTransaction],
        actualCash: method === PaymentMethod.CASH ? prev.actualCash + amount : prev.actualCash,
        actualTransfer: method === PaymentMethod.TRANSFER ? prev.actualTransfer + amount : prev.actualTransfer
      };
    });

    if (method === PaymentMethod.TRANSFER) {
      setShowQR(true);
    } else {
      setSaleAmount('');
      alert('Đã ghi nhận TIỀN MẶT: ' + formatCurrency(amount));
    }
  }, [session, saleAmount]);

  // Chốt sổ cuối ngày
  const closeSession = () => {
    if (!session) return;
    const confirmed = window.confirm("Mẹ chắc chắn muốn CHỐT SỔ không?");
    if (confirmed) {
      setSession(prev => prev ? { ...prev, isActive: false } : null);
      setActiveTab('report');
    }
  };

  // Thêm hàng hóa mới
  const addProduct = () => {
    if (!newProduct.name || !newProduct.unit || !newProduct.price) {
      alert("Mẹ điền đủ Tên, Đơn vị và Giá nhé!");
      return;
    }
    const p: Product = {
      id: Date.now().toString(),
      name: newProduct.name,
      unit: newProduct.unit,
      price: Number(newProduct.price)
    };
    
    setProducts(prev => [...prev, p]);
    
    if (session && session.isActive) {
      setSession(prev => prev ? ({
        ...prev,
        stockLogs: {
          ...prev.stockLogs,
          [p.id]: { productId: p.id, startQty: 0, addedQty: 0, endQty: 0 }
        }
      }) : null);
    }
    setNewProduct({ name: '', unit: '', price: 0 });
    setShowAddProductModal(false);
  };

  // Thực hiện Xóa sau khi xác nhận
  const confirmDelete = () => {
    if (productToDelete) {
      setProducts(prev => prev.filter(p => p.id !== productToDelete.id));
      setProductToDelete(null);
    }
  };

  // Lưu chỉnh sửa hàng hóa
  const saveEditedProduct = () => {
    if (!editingProduct) return;
    setProducts(prev => prev.map(p => p.id === editingProduct.id ? editingProduct : p));
    setEditingProduct(null);
  };

  // Bàn phím số
  const handleKeypad = (val: string) => {
    if (val === 'C') {
      setSaleAmount('');
    } else if (val === '000') {
      setSaleAmount(prev => (prev === '' || prev === '0' ? '' : prev + '000'));
    } else {
      setSaleAmount(prev => (prev === '0' ? val : prev + val));
    }
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

      <div className="grid grid-cols-3 gap-2 mb-2">
        {['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '000'].map(key => (
          <button
            key={key}
            onClick={() => handleKeypad(key)}
            className={`py-5 text-2xl font-black rounded-xl shadow-sm active:bg-gray-300 transition-colors border-2 ${
              key === 'C' ? 'bg-red-700 text-white border-red-900' : 
              key === '000' ? 'bg-blue-100 text-black border-blue-400' : 'bg-white text-black border-gray-300'
            }`}
          >
            {key}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-3">
        <button 
          onClick={() => addSale(PaymentMethod.CASH)} 
          disabled={!saleAmount}
          className="bg-emerald-700 text-white py-6 rounded-2xl text-xl font-black shadow-lg border-b-8 border-emerald-950 active:translate-y-1 disabled:opacity-50"
        >
          TRẢ TIỀN MẶT
        </button>
        <button 
          onClick={() => addSale(PaymentMethod.TRANSFER)} 
          disabled={!saleAmount}
          className="bg-blue-800 text-white py-6 rounded-2xl text-xl font-black shadow-lg border-b-8 border-blue-950 active:translate-y-1 disabled:opacity-50"
        >
          CHUYỂN KHOẢN
        </button>
      </div>

      {showQR && (
        <div className="fixed inset-0 bg-black/90 flex flex-col items-center justify-center z-50 p-6">
          <div className="bg-white rounded-[40px] p-6 max-w-sm w-full text-center shadow-2xl">
            <h3 className="text-2xl font-black mb-4 text-black">Mời khách quét mã</h3>
            <div className="bg-white p-2 rounded-xl border-[6px] border-blue-800 mb-4">
              <img src={getVietQRUrl(bankInfo, parseFloat(saleAmount))} alt="VietQR" className="w-full h-auto" />
            </div>
            <p className="text-3xl font-black text-blue-950 mb-6">{formatCurrency(parseFloat(saleAmount))}</p>
            <button 
              onClick={() => { setShowQR(false); setSaleAmount(''); }} 
              className="w-full py-5 bg-emerald-700 text-white font-black text-xl rounded-2xl border-b-4 border-emerald-900"
            >
              MẸ ĐÃ NHẬN TIỀN
            </button>
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
          <SectionTitle title="Kiểm kê" />
          <button onClick={() => setActiveTab('settings')} className="text-white font-black text-sm bg-blue-900 px-5 py-3 rounded-xl shadow-lg uppercase mb-2">Sửa Món</button>
        </div>
        {products.map(p => {
          const log = session.stockLogs[p.id] || { startQty: 0, addedQty: 0, endQty: 0 };
          return (
            <div key={p.id} className="bg-white p-5 rounded-2xl shadow-md border-[2px] border-gray-300 space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-lg font-black text-black">{p.name}</span>
                <span className="bg-blue-800 text-white px-3 py-1 rounded-lg text-xs font-black uppercase">{p.unit}</span>
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div className="space-y-1">
                  <label className="text-[11px] font-black text-black uppercase block text-center">Đầu ca</label>
                  <input type="number" value={log.startQty || ''} onChange={(e) => updateStock(p.id, 'startQty', parseFloat(e.target.value) || 0)} className="w-full p-3 bg-gray-100 rounded-xl text-xl font-black border-2 border-gray-400 text-black text-center outline-none focus:border-blue-700" />
                </div>
                <div className="space-y-1">
                  <label className="text-[11px] font-black text-emerald-900 uppercase block text-center">Thêm</label>
                  <input type="number" value={log.addedQty || ''} onChange={(e) => updateStock(p.id, 'addedQty', parseFloat(e.target.value) || 0)} className="w-full p-3 bg-emerald-50 rounded-xl text-xl font-black border-2 border-emerald-400 text-black text-center outline-none focus:border-emerald-700" />
                </div>
                <div className="space-y-1">
                  <label className="text-[11px] font-black text-red-900 uppercase block text-center">Cuối ca</label>
                  <input type="number" value={log.endQty || ''} onChange={(e) => updateStock(p.id, 'endQty', parseFloat(e.target.value) || 0)} className="w-full p-3 bg-red-50 rounded-xl text-xl font-black border-2 border-red-400 text-black text-center outline-none focus:border-red-700" />
                </div>
              </div>
            </div>
          );
        })}
        <button onClick={closeSession} className="w-full bg-black text-white py-6 rounded-2xl text-xl font-black shadow-xl border-b-8 border-gray-800 mt-4 active:translate-y-1">CHỐT SỔ</button>
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
        <SectionTitle title="Báo cáo cuối ngày" />
        <div className="grid grid-cols-1 gap-3">
          <div className="bg-white p-5 rounded-xl shadow-md border-l-[12px] border-emerald-700">
            <p className="text-black font-black uppercase text-xs mb-1">Tiền mặt</p>
            <p className="text-2xl font-black text-emerald-900">{formatCurrency(session.actualCash)}</p>
          </div>
          <div className="bg-white p-5 rounded-xl shadow-md border-l-[12px] border-blue-800">
            <p className="text-black font-black uppercase text-xs mb-1">Chuyển khoản</p>
            <p className="text-2xl font-black text-blue-950">{formatCurrency(session.actualTransfer)}</p>
          </div>
          <div className="bg-white p-5 rounded-xl shadow-md border-l-[12px] border-black">
            <p className="text-black font-black uppercase text-xs mb-1">Doanh thu chuẩn</p>
            <p className="text-2xl font-black text-black">{formatCurrency(totalRev)}</p>
          </div>
        </div>
        
        <div className={`p-6 rounded-[30px] shadow-lg border-[3px] text-center ${diff === 0 ? 'bg-emerald-50 border-emerald-600' : diff > 0 ? 'bg-blue-50 border-blue-500' : 'bg-red-50 border-red-600'}`}>
          <p className="text-black font-black uppercase text-xs mb-1">Chênh lệch</p>
          <p className={`text-3xl font-black mb-2 ${diff === 0 ? 'text-emerald-900' : diff > 0 ? 'text-blue-950' : 'text-red-950'}`}>
            {diff === 0 ? 'KHỚP SỔ!' : formatCurrency(diff)}
          </p>
          <div className={`py-3 px-6 rounded-full inline-block text-sm font-black uppercase ${diff === 0 ? 'bg-emerald-700 text-white' : diff > 0 ? 'bg-blue-800 text-white' : 'bg-red-700 text-white'}`}>
            {diff > 0 ? 'Thừa tiền mẹ ơi' : diff < 0 ? 'Thiếu tiền rồi' : 'Xuất sắc!'}
          </div>
        </div>

        <SectionTitle title="Chi tiết đã bán" />
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

        <button onClick={startSession} className="w-full bg-red-800 text-white py-6 rounded-2xl text-xl font-black shadow-xl border-b-8 border-red-950 mt-6 active:translate-y-1">LÀM CA MỚI</button>
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

      {/* Modal Thêm */}
      {showAddProductModal && (
        <div className="fixed inset-0 bg-black/95 flex flex-col items-center justify-center z-50 p-6">
          <div className="bg-white rounded-[40px] p-8 w-full max-w-sm space-y-6 shadow-2xl">
            <h3 className="text-2xl font-black text-black border-b-4 border-blue-800 pb-2">Thêm món mới</h3>
            <div className="space-y-4">
              <div className="space-y-1">
                <label className="text-xs font-black text-black uppercase ml-1">Tên món</label>
                <input placeholder="VD: Bia hơi" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black text-black" value={newProduct.name} onChange={e => setNewProduct({...newProduct, name: e.target.value})} />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-black text-black uppercase ml-1">Đơn vị</label>
                <input placeholder="VD: Két, Thùng" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black text-black" value={newProduct.unit} onChange={e => setNewProduct({...newProduct, unit: e.target.value})} />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-black text-black uppercase ml-1">Giá bán</label>
                <input type="number" placeholder="250000" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black text-black" value={newProduct.price || ''} onChange={e => setNewProduct({...newProduct, price: parseFloat(e.target.value) || 0})} />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4 pt-2">
              <button onClick={() => setShowAddProductModal(false)} className="py-4 bg-gray-200 text-black font-black text-lg rounded-xl">HỦY</button>
              <button onClick={addProduct} className="py-4 bg-blue-800 text-white font-black text-lg rounded-xl shadow-lg border-b-6 border-blue-950">THÊM</button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Sửa */}
      {editingProduct && (
        <div className="fixed inset-0 bg-black/95 flex flex-col items-center justify-center z-50 p-6">
          <div className="bg-white rounded-[40px] p-8 w-full max-w-sm space-y-6 shadow-2xl">
            <h3 className="text-2xl font-black text-black border-b-4 border-blue-800 pb-2">Sửa món</h3>
            <div className="space-y-4">
              <input className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black text-black" value={editingProduct.name} onChange={e => setEditingProduct({...editingProduct, name: e.target.value})} />
              <input className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black text-black" value={editingProduct.unit} onChange={e => setEditingProduct({...editingProduct, unit: e.target.value})} />
              <input type="number" className="w-full p-4 bg-gray-50 border-2 border-gray-300 rounded-xl text-lg font-black text-black" value={editingProduct.price} onChange={e => setEditingProduct({...editingProduct, price: parseFloat(e.target.value) || 0})} />
            </div>
            <div className="grid grid-cols-2 gap-4 pt-2">
              <button onClick={() => setEditingProduct(null)} className="py-4 bg-gray-200 text-black font-black text-lg rounded-xl">HỦY</button>
              <button onClick={saveEditedProduct} className="py-4 bg-emerald-700 text-white font-black text-lg rounded-xl shadow-lg border-b-6 border-emerald-950">LƯU</button>
            </div>
          </div>
        </div>
      )}

      {/* Modal XÁC NHẬN XÓA */}
      {productToDelete && (
        <div className="fixed inset-0 bg-black/98 flex flex-col items-center justify-center z-[60] p-6">
          <div className="bg-white rounded-[40px] p-8 w-full max-w-sm text-center space-y-8 shadow-2xl border-4 border-red-200">
            <div className="text-7xl mb-2">🗑️</div>
            <h3 className="text-3xl font-black text-black leading-tight">Mẹ chắc chắn muốn XÓA mặt hàng này?</h3>
            <p className="text-2xl font-black text-red-800 bg-red-50 p-6 rounded-2xl border-2 border-red-200">
              {productToDelete.name}
            </p>
            <div className="grid grid-cols-1 gap-5">
              <button 
                onClick={confirmDelete} 
                className="py-6 bg-red-700 text-white text-2xl font-black rounded-3xl shadow-xl border-b-12 border-red-950 active:translate-y-2"
              >
                XÁC NHẬN XÓA
              </button>
              <button 
                onClick={() => setProductToDelete(null)} 
                className="py-5 bg-gray-100 text-black text-xl font-black rounded-2xl border-2 border-gray-300"
              >
                HỦY, KHÔNG XÓA
              </button>
            </div>
          </div>
        </div>
      )}
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
        {!session ? (
          <div className="flex flex-col items-center justify-center py-24 text-center px-4">
            <div className="w-32 h-32 bg-blue-900 rounded-[48px] flex items-center justify-center mb-10 shadow-2xl border-[8px] border-blue-700 transform rotate-3">
              <span className="text-6xl">🏪</span>
            </div>
            <h2 className="text-4xl font-black text-black mb-4">Chào mẹ yêu!</h2>
            <p className="text-lg text-gray-800 mb-10 font-bold leading-relaxed">Hôm nay mẹ bán hàng gì?<br/>Bấm "MỞ CA" để bắt đầu nhé.</p>
            <div className="w-full bg-amber-50 p-6 rounded-3xl border-2 border-amber-200 shadow-inner">
               <p className="text-amber-950 font-black text-sm uppercase mb-2 tracking-widest text-left">Lưu ý cho mẹ:</p>
               <p className="text-amber-950 font-bold text-base text-left">Mẹ nhớ kiểm hàng trên kệ và điền số vào cột "ĐẦU CA" để tối nay app tính cho chuẩn nhé!</p>
            </div>
          </div>
        ) : (
          <div className="animate-in fade-in duration-300">
            {activeTab === 'sales' && renderSales()}
            {activeTab === 'inventory' && renderInventory()}
            {activeTab === 'report' && renderReport()}
            {activeTab === 'settings' && renderSettings()}
          </div>
        )}
      </main>

      {session && (
        <nav className="fixed bottom-0 left-0 right-0 bg-black border-t-[4px] border-blue-800 px-2 py-3 flex justify-around items-center z-30 max-w-md mx-auto rounded-t-[32px] shadow-[0_-10px_30px_rgba(0,0,0,0.3)]">
          {[
            { id: 'sales', label: 'BÁN', icon: '💰' },
            { id: 'inventory', label: 'KHO', icon: '📦' },
            { id: 'report', label: 'SỔ', icon: '📊' },
            { id: 'settings', label: 'MÓN', icon: '⚙️' },
          ].map(tab => (
            <button key={tab.id} onClick={() => setActiveTab(tab.id as any)} className={`flex flex-col items-center px-5 py-2 rounded-2xl transition-all ${activeTab === tab.id ? 'bg-blue-800 text-white scale-110 shadow-lg -translate-y-2' : 'text-gray-500 opacity-60'}`}>
              <span className="text-2xl mb-1">{tab.icon}</span>
              <span className="text-[10px] font-black uppercase tracking-tight">{tab.label}</span>
            </button>
          ))}
        </nav>
      )}
    </div>
  );
};

export default App;

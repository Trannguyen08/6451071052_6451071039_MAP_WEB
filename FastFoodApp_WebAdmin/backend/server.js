const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const crypto = require('crypto');

const path = require('path');
const fs = require('fs');
const PayOS = require('@payos/node');
const admin = require('firebase-admin');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

dotenv.config({ path: path.join(__dirname, '../env') });

const app = express();
app.use(cors());
app.use(express.json());

let firestore = null;

const initFirebaseAdmin = () => {
  if (admin.apps.length) {
    firestore = getFirestore(admin.app(), 'fastfood');
    return;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const resolvedServiceAccountPath = serviceAccountPath
    ? (path.isAbsolute(serviceAccountPath)
      ? serviceAccountPath
      : path.join(__dirname, '..', serviceAccountPath))
    : '';

  try {
    if (serviceAccountJson) {
      admin.initializeApp({
        credential: admin.credential.cert(JSON.parse(serviceAccountJson)),
        projectId: process.env.FIREBASE_PROJECT_ID || 'project-5442431422660328081'
      });
    } else if (resolvedServiceAccountPath && fs.existsSync(resolvedServiceAccountPath)) {
      admin.initializeApp({
        credential: admin.credential.cert(require(resolvedServiceAccountPath)),
        projectId: process.env.FIREBASE_PROJECT_ID || 'project-5442431422660328081'
      });
    } else {
      firestore = null;
      console.warn(
        'Firebase Admin credentials not found. Set FIREBASE_SERVICE_ACCOUNT_PATH or GOOGLE_APPLICATION_CREDENTIALS.'
      );
      return;
    }

    firestore = getFirestore(admin.app(), 'fastfood');
    console.log('Firebase Admin connected to Firestore database: fastfood');
  } catch (error) {
    firestore = null;
    console.warn('Firebase Admin not configured. Admin Firestore APIs will return 503.', error.message);
  }
};

initFirebaseAdmin();

const requireFirestore = (res) => {
  if (firestore) return true;
  res.status(503).json({
    error: 'Firebase Admin is not configured. Set FIREBASE_SERVICE_ACCOUNT_PATH or GOOGLE_APPLICATION_CREDENTIALS.'
  });
  return false;
};

const toIsoString = (value) => {
  if (!value) return new Date().toISOString();
  if (typeof value === 'string') return value;
  if (value.toDate) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return new Date(value).toISOString();
};

const normalizeOrder = (doc) => {
  const data = doc.data();
  const totalAmount = Number(data.totalAmount ?? data.total ?? data.amount ?? 0);
  return {
    id: doc.id,
    orderCode: data.orderCode || data.code || `#FH-${doc.id.slice(0, 6).toUpperCase()}`,
    userId: data.userId || '',
    customerName: data.customerName || data.delivery?.name || data.customer?.name || '',
    customerPhone: data.customerPhone || data.delivery?.phone || data.customer?.phone || '',
    payment: data.payment || data.paymentMethod || '',
    items: Array.isArray(data.items) ? data.items : [],
    totalAmount,
    createdAt: toIsoString(data.createdAt),
    status: data.status || 'pending'
  };
};

const normalizeCategory = (doc) => {
  const data = doc.data();
  return {
    id: doc.id,
    name: data.name || '',
    icon: data.icon || '🍔'
  };
};

const normalizeProduct = (doc) => {
  const data = doc.data();
  return {
    id: doc.id,
    name: data.name || '',
    description: data.description || '',
    price: Number(data.price || 0),
    imageUrl: data.imageUrl || '',
    categoryId: data.categoryId || '',
    brand: data.brand || data.brandName || '',
    isAvailable: data.isAvailable !== false
  };
};

const normalizeUser = (doc, stats = {}) => {
  const data = doc.data();
  const email = data.email || '';
  return {
    id: doc.id,
    name: data.fullName || data.name || email || 'Unknown user',
    email,
    phone: data.phoneNumber || data.phone || '',
    avatar: data.avatar || data.photoUrl || '',
    ordersCount: Number(data.ordersCount ?? stats.ordersCount ?? 0),
    totalSpending: Number(data.totalSpending ?? stats.totalSpending ?? 0),
    status: data.status || (data.isBlocked ? 'blocked' : 'active')
  };
};

const normalizeNameKey = value =>
  String(value || '')
    .trim()
    .replace(/\s+/g, ' ')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLocaleLowerCase('vi-VN');

const getUserOrderStats = async () => {
  const stats = new Map();
  const snapshot = await firestore.collection('orders').get();

  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const userId = data.userId || '';
    if (!userId) return;

    const current = stats.get(userId) || { ordersCount: 0, totalSpending: 0 };
    current.ordersCount += 1;
    current.totalSpending += Number(data.totalAmount ?? data.total ?? data.amount ?? 0);
    stats.set(userId, current);
  });

  return stats;
};

// Default admin account:
// email: admin@fastfood.local
// password: Admin@123456
const adminAccounts = [
  {
    id: 'ADM-001',
    name: 'System Admin',
    email: 'admin@fastfood.local',
    password: 'Admin@123456'
  }
];

const adminSessions = new Map();

const requireAdmin = (req, res, next) => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
  const session = adminSessions.get(token);

  if (!session) {
    return res.status(401).json({ error: 'Admin authentication required' });
  }

  req.admin = session;
  next();
};

// PayOS Initialization
const payos = new PayOS(
  process.env.PAYOS_CLIENT_ID,
  process.env.PAYOS_API_KEY,
  process.env.PAYOS_CHECKSUM_KEY
);

// Mock Data for Cart
let cart = {
  items: [
    {
      id: '1',
      name: 'Bánh Burger Bò Phô Mai',
      options: 'Size L • Thêm thịt nướng',
      price: 85000,
      quantity: 1,
      image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500'
    },
    {
      id: '2',
      name: 'Pizza Hải Sản Pesto',
      options: 'Đế mỏng • Gấp đôi hải sản',
      price: 155000,
      quantity: 1,
      image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500'
    }
  ],
  deliveryInfo: {
    address: '123 Lê Lợi, Phường Bến Thành, Quận 1',
    name: '',
    phone: ''
  },
  paymentMethod: 'cash', // 'cash' or 'online'
  shippingFee: 15000,
  discount: 48000
};

// Helper function to calculate cart totals
const calculateCartTotals = (cart) => {
  const subtotal = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const total = subtotal + cart.shippingFee - cart.discount;
  return { ...cart, subtotal, total };
};

// Mock Data for Admin Users
let users = [
  {
    id: 'CUS-2041',
    name: 'Nguyễn An Nhiên',
    email: 'annhien@gmail.com',
    phone: '0901 234 567',
    avatar: 'https://i.pravatar.cc/150?img=1',
    ordersCount: 42,
    totalSpending: 12450000,
    status: 'active'
  },
  {
    id: 'CUS-2038',
    name: 'Trần Văn Tú',
    email: 'vantu.tran@outlook.com',
    phone: '0988 776 554',
    avatar: 'https://i.pravatar.cc/150?img=2',
    ordersCount: 8,
    totalSpending: 1200000,
    status: 'blocked'
  },
  {
    id: 'CUS-2015',
    name: 'Lê Thu Thảo',
    email: 'thao_le99@gmail.com',
    phone: '0345 678 901',
    avatar: 'https://i.pravatar.cc/150?img=3',
    ordersCount: 156,
    totalSpending: 54900000,
    status: 'active'
  },
  {
    id: 'CUS-1992',
    name: 'Hoàng Minh Anh',
    email: 'minhanh_h@yahoo.com',
    phone: '0912 334 455',
    avatar: 'https://i.pravatar.cc/150?img=4',
    ordersCount: 12,
    totalSpending: 3420000,
    status: 'active'
  }
];

// Admin Routes
app.post('/api/admin/login', (req, res) => {
  const { email, password } = req.body;
  const admin = adminAccounts.find(
    account => account.email === email && account.password === password
  );

  if (!admin) {
    return res.status(401).json({ error: 'Email hoặc mật khẩu admin không đúng' });
  }

  const token = crypto.randomBytes(32).toString('hex');
  adminSessions.set(token, {
    id: admin.id,
    name: admin.name,
    email: admin.email,
    createdAt: new Date().toISOString()
  });

  res.json({
    token,
    admin: {
      id: admin.id,
      name: admin.name,
      email: admin.email
    }
  });
});

app.post('/api/admin/logout', requireAdmin, (req, res) => {
  const token = req.headers.authorization.slice(7);
  adminSessions.delete(token);
  res.json({ success: true });
});

app.get('/api/admin/me', requireAdmin, (req, res) => {
  res.json({ admin: req.admin });
});

app.get('/api/admin/dashboard', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  try {
    const [usersSnapshot, ordersSnapshot, categoriesSnapshot, productsSnapshot] = await Promise.all([
      firestore.collection('users').get(),
      firestore.collection('orders').orderBy('createdAt', 'desc').limit(100).get(),
      firestore.collection('categories').get(),
      firestore.collection('products').get()
    ]);

    const users = usersSnapshot.docs.map(doc => normalizeUser(doc));
    const orders = ordersSnapshot.docs.map(normalizeOrder);

    res.json({
      totalUsers: users.length,
      activeUsers: users.filter(user => user.status === 'active').length,
      totalOrders: orders.length,
      pendingOrders: orders.filter(order => order.status === 'pending' || order.status === 'pending_payment').length,
      processingOrders: orders.filter(order => order.status === 'processing').length,
      completedOrders: orders.filter(order => order.status === 'delivered' || order.status === 'completed').length,
      cancelledOrders: orders.filter(order => order.status === 'cancelled').length,
      totalCategories: categoriesSnapshot.size,
      totalProducts: productsSnapshot.size,
      totalRevenue: orders.reduce((sum, order) => sum + order.totalAmount, 0),
      recentOrders: orders.slice(0, 5)
    });
  } catch (error) {
    console.error('Admin dashboard Firestore error:', error);
    res.status(500).json({ error: 'Khong the tai dashboard admin' });
  }
});

app.get('/api/admin/users', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { search } = req.query;

  try {
    const [usersSnapshot, orderStats] = await Promise.all([
      firestore.collection('users').get(),
      getUserOrderStats()
    ]);

    let firebaseUsers = usersSnapshot.docs.map(doc =>
      normalizeUser(doc, orderStats.get(doc.id))
    );
    firebaseUsers.sort((a, b) => a.name.localeCompare(b.name));

    if (search) {
      const keyword = search.toLowerCase();
      firebaseUsers = firebaseUsers.filter(user =>
        user.name.toLowerCase().includes(keyword) ||
        user.email.toLowerCase().includes(keyword) ||
        user.phone.toLowerCase().includes(keyword) ||
        user.id.toLowerCase().includes(keyword)
      );
    }

    const allUsers = usersSnapshot.docs.map(doc =>
      normalizeUser(doc, orderStats.get(doc.id))
    );

    res.json({
      total: allUsers.length,
      active: allUsers.filter(user => user.status === 'active').length,
      blocked: allUsers.filter(user => user.status === 'blocked').length,
      avgSpending: allUsers.length
        ? Math.round(allUsers.reduce((sum, user) => sum + user.totalSpending, 0) / allUsers.length)
        : 0,
      users: firebaseUsers
    });
  } catch (error) {
    console.error('Admin users Firestore error:', error);
    res.status(500).json({ error: 'Không thể tải khách hàng từ Firebase' });
  }
});

app.get('/api/admin/orders', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { search = '', status = 'all' } = req.query;

  try {
    const snapshot = await firestore
      .collection('orders')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    let adminOrders = snapshot.docs.map(normalizeOrder);

    if (status && status !== 'all') {
      adminOrders = adminOrders.filter(order => order.status === status);
    }

    if (search) {
      const keyword = search.toLowerCase();
      adminOrders = adminOrders.filter(order =>
        order.orderCode.toLowerCase().includes(keyword) ||
        order.userId.toLowerCase().includes(keyword) ||
        order.customerName.toLowerCase().includes(keyword) ||
        order.customerPhone.toLowerCase().includes(keyword)
      );
    }

    const allOrders = snapshot.docs.map(normalizeOrder);
    const totalRevenue = allOrders.reduce((sum, order) => sum + order.totalAmount, 0);

    res.json({
      total: allOrders.length,
      pending: allOrders.filter(order => order.status === 'pending' || order.status === 'pending_payment').length,
      processing: allOrders.filter(order => order.status === 'processing').length,
      completed: allOrders.filter(order => order.status === 'delivered' || order.status === 'completed').length,
      cancelled: allOrders.filter(order => order.status === 'cancelled').length,
      totalRevenue,
      orders: adminOrders
    });
  } catch (error) {
    console.error('Admin orders Firestore error:', error);
    res.status(500).json({ error: 'Không thể tải đơn hàng từ Firebase' });
  }
});

app.patch('/api/admin/orders/:id/status', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { id } = req.params;
  const statusAliases = {
    delivere: 'delivered',
    complete: 'completed',
  };
  const allowedStatuses = ['pending', 'pending_payment', 'processing', 'delivered', 'completed', 'cancelled'];
  const normalizeStatus = value => {
    const raw = String(value || '').trim().toLowerCase();
    if (statusAliases[raw]) return statusAliases[raw];
    if (raw.startsWith('deliver')) return 'delivered';
    if (raw.startsWith('complet')) return 'completed';
    if (raw.startsWith('process')) return 'processing';
    if (raw.startsWith('cancel')) return 'cancelled';
    if (raw === 'pendingpayment' || raw === 'pending-payment') return 'pending_payment';
    return raw;
  };
  const statusCandidates = [
    normalizeStatus(req.query.status),
    normalizeStatus(req.body?.status),
  ].filter(Boolean);
  const status =
    statusCandidates.find(candidate => allowedStatuses.includes(candidate)) ||
    statusCandidates[0] ||
    '';

  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({
      error: 'Tr?ng th?i ??n h?ng kh?ng h?p l?',
      receivedStatus: status ?? null
    });
  }

  try {
    const orderRef = firestore.collection('orders').doc(id);
    const doc = await orderRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Order not found' });
    }

    await orderRef.update({
      status,
      updatedAt: FieldValue.serverTimestamp()
    });

    const updatedDoc = await orderRef.get();
    res.json({ success: true, order: normalizeOrder(updatedDoc) });
  } catch (error) {
    console.error('Admin order status update error:', error);
    res.status(500).json({ error: 'Không thể cập nhật trạng thái đơn hàng' });
  }
});

app.get('/api/admin/categories', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { search = '' } = req.query;

  try {
    const snapshot = await firestore.collection('categories').orderBy('name').get();
    let categories = snapshot.docs.map(normalizeCategory);

    if (search) {
      const keyword = search.toLowerCase();
      categories = categories.filter(category =>
        category.name.toLowerCase().includes(keyword) ||
        category.id.toLowerCase().includes(keyword)
      );
    }

    res.json({ total: categories.length, categories });
  } catch (error) {
    console.error('Admin categories Firestore error:', error);
    res.status(500).json({ error: 'Không thể tải danh mục từ Firebase' });
  }
});

app.post('/api/admin/categories', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { name, icon } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'Tên danh mục là bắt buộc' });
  }

  try {
    const normalizedName = normalizeNameKey(name);
    const existingCategories = await firestore.collection('categories').get();
    const duplicated = existingCategories.docs.some(doc =>
      normalizeNameKey(doc.data().name) === normalizedName
    );
    if (duplicated) {
      return res.status(409).json({ error: 'Tên danh mục đã tồn tại' });
    }

    const docRef = await firestore.collection('categories').add({
      name,
      icon: icon || '🍔',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });
    const doc = await docRef.get();
    res.status(201).json({ success: true, category: normalizeCategory(doc) });
  } catch (error) {
    console.error('Admin category create error:', error);
    res.status(500).json({ error: 'Không thể tạo danh mục' });
  }
});

app.put('/api/admin/categories/:id', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { id } = req.params;
  const { name, icon } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'Tên danh mục là bắt buộc' });
  }

  try {
    const docRef = firestore.collection('categories').doc(id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Category not found' });
    }

    const normalizedName = normalizeNameKey(name);
    const existingCategories = await firestore.collection('categories').get();
    const duplicated = existingCategories.docs.some(categoryDoc =>
      categoryDoc.id !== id &&
      normalizeNameKey(categoryDoc.data().name) === normalizedName
    );
    if (duplicated) {
      return res.status(409).json({ error: 'Tên danh mục đã tồn tại' });
    }

    await docRef.update({
      name,
      icon: icon || '🍔',
      updatedAt: FieldValue.serverTimestamp()
    });
    const updatedDoc = await docRef.get();
    res.json({ success: true, category: normalizeCategory(updatedDoc) });
  } catch (error) {
    console.error('Admin category update error:', error);
    res.status(500).json({ error: 'Không thể cập nhật danh mục' });
  }
});

app.delete('/api/admin/categories/:id', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { id } = req.params;

  try {
    const productSnapshot = await firestore
      .collection('products')
      .where('categoryId', '==', id)
      .limit(1)
      .get();

    if (!productSnapshot.empty) {
      return res.status(409).json({ error: 'Không thể xóa danh mục đang có sản phẩm' });
    }

    await firestore.collection('categories').doc(id).delete();
    res.json({ success: true });
  } catch (error) {
    console.error('Admin category delete error:', error);
    res.status(500).json({ error: 'Không thể xóa danh mục' });
  }
});

app.get('/api/admin/products', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { search = '', categoryId = 'all' } = req.query;

  try {
    let query = firestore.collection('products');
    if (categoryId && categoryId !== 'all') {
      query = query.where('categoryId', '==', categoryId);
    }

    const snapshot = await query.get();
    let products = snapshot.docs.map(normalizeProduct);
    products.sort((a, b) => a.name.localeCompare(b.name));

    if (search) {
      const keyword = search.toLowerCase();
      products = products.filter(product =>
        product.name.toLowerCase().includes(keyword) ||
        product.description.toLowerCase().includes(keyword) ||
        product.brand.toLowerCase().includes(keyword) ||
        product.id.toLowerCase().includes(keyword)
      );
    }

    res.json({ total: products.length, products });
  } catch (error) {
    console.error('Admin products Firestore error:', error);
    res.status(500).json({ error: 'Không thể tải sản phẩm từ Firebase' });
  }
});

app.post('/api/admin/products', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { name, description, price, imageUrl, categoryId, brand, isAvailable } = req.body;
  if (!name || !categoryId) {
    return res.status(400).json({ error: 'Tên sản phẩm và danh mục là bắt buộc' });
  }

  try {
    const normalizedName = normalizeNameKey(name);
    const existingProducts = await firestore.collection('products').get();
    const duplicated = existingProducts.docs.some(doc =>
      normalizeNameKey(doc.data().name) === normalizedName
    );
    if (duplicated) {
      return res.status(409).json({ error: 'Tên sản phẩm đã tồn tại' });
    }

    const docRef = await firestore.collection('products').add({
      name,
      description: description || '',
      price: Number(price || 0),
      imageUrl: imageUrl || '',
      categoryId,
      brand: brand || '',
      isAvailable: isAvailable !== false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });
    const doc = await docRef.get();
    res.status(201).json({ success: true, product: normalizeProduct(doc) });
  } catch (error) {
    console.error('Admin product create error:', error);
    res.status(500).json({ error: 'Không thể tạo sản phẩm' });
  }
});

app.put('/api/admin/products/:id', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { id } = req.params;
  const { name, description, price, imageUrl, categoryId, brand, isAvailable } = req.body;
  if (!name || !categoryId) {
    return res.status(400).json({ error: 'Tên sản phẩm và danh mục là bắt buộc' });
  }

  try {
    const docRef = firestore.collection('products').doc(id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const normalizedName = normalizeNameKey(name);
    const existingProducts = await firestore.collection('products').get();
    const duplicated = existingProducts.docs.some(productDoc =>
      productDoc.id !== id &&
      normalizeNameKey(productDoc.data().name) === normalizedName
    );
    if (duplicated) {
      return res.status(409).json({ error: 'Tên sản phẩm đã tồn tại' });
    }

    await docRef.update({
      name,
      description: description || '',
      price: Number(price || 0),
      imageUrl: imageUrl || '',
      categoryId,
      brand: brand || '',
      isAvailable: isAvailable !== false,
      updatedAt: FieldValue.serverTimestamp()
    });
    const updatedDoc = await docRef.get();
    res.json({ success: true, product: normalizeProduct(updatedDoc) });
  } catch (error) {
    console.error('Admin product update error:', error);
    res.status(500).json({ error: 'Không thể cập nhật sản phẩm' });
  }
});

app.delete('/api/admin/products/:id', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  try {
    await firestore.collection('products').doc(req.params.id).delete();
    res.json({ success: true });
  } catch (error) {
    console.error('Admin product delete error:', error);
    res.status(500).json({ error: 'Không thể xóa sản phẩm' });
  }
});

app.post('/api/admin/users', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { name, email, phone, avatar, status } = req.body;
  if (!name || !email || !phone) {
    return res.status(400).json({ error: 'Ten, email va so dien thoai la bat buoc' });
  }

  try {
    const existed = await firestore.collection('users').where('email', '==', email).limit(1).get();
    if (!existed.empty) {
      return res.status(409).json({ error: 'Email khach hang da ton tai' });
    }

    const docRef = await firestore.collection('users').add({
      fullName: name,
      email,
      phoneNumber: phone,
      avatar: avatar || '',
      status: status === 'blocked' ? 'blocked' : 'active',
      isBlocked: status === 'blocked',
      isVerified: true,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    const doc = await docRef.get();
    res.status(201).json({ success: true, user: normalizeUser(doc) });
  } catch (error) {
    console.error('Admin user create error:', error);
    res.status(500).json({ error: 'Khong the tao khach hang' });
  }
});

app.put('/api/admin/users/:id', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { id } = req.params;
  const { name, email, phone, avatar, status } = req.body;

  try {
    const userRef = firestore.collection('users').doc(id);
    const doc = await userRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (email) {
      const existed = await firestore.collection('users').where('email', '==', email).limit(5).get();
      const duplicated = existed.docs.some(userDoc => userDoc.id !== id);
      if (duplicated) {
        return res.status(409).json({ error: 'Email khach hang da ton tai' });
      }
    }

    await userRef.update({
      fullName: name,
      email,
      phoneNumber: phone,
      avatar: avatar || '',
      status: status === 'blocked' ? 'blocked' : 'active',
      isBlocked: status === 'blocked',
      updatedAt: FieldValue.serverTimestamp()
    });

    const updatedDoc = await userRef.get();
    res.json({ success: true, user: normalizeUser(updatedDoc) });
  } catch (error) {
    console.error('Admin user update error:', error);
    res.status(500).json({ error: 'Khong the cap nhat khach hang' });
  }
});

app.delete('/api/admin/users/:id', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { id } = req.params;

  try {
    const userRef = firestore.collection('users').doc(id);
    const doc = await userRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    await userRef.delete();
    res.json({ success: true });
  } catch (error) {
    console.error('Admin user delete error:', error);
    res.status(500).json({ error: 'Khong the xoa khach hang' });
  }
});

app.post('/api/admin/users/:id/status', requireAdmin, async (req, res) => {
  if (!requireFirestore(res)) return;

  const { id } = req.params;
  const { status } = req.body;

  try {
    const userRef = firestore.collection('users').doc(id);
    const doc = await userRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    await userRef.update({
      status: status === 'blocked' ? 'blocked' : 'active',
      isBlocked: status === 'blocked',
      updatedAt: FieldValue.serverTimestamp()
    });

    const updatedDoc = await userRef.get();
    res.json({ success: true, user: normalizeUser(updatedDoc) });
  } catch (error) {
    console.error('Admin user status update error:', error);
    res.status(500).json({ error: 'Khong the cap nhat trang thai khach hang' });
  }
});

// Mock Data for Orders
let orders = [];

app.post('/api/admin/users', requireAdmin, (req, res) => {
  const { name, email, phone, avatar, ordersCount, totalSpending, status } = req.body;

  if (!name || !email || !phone) {
    return res.status(400).json({ error: 'Tên, email và số điện thoại là bắt buộc' });
  }

  const existed = users.some(user => user.email.toLowerCase() === email.toLowerCase());
  if (existed) {
    return res.status(409).json({ error: 'Email khách hàng đã tồn tại' });
  }

  const newUser = {
    id: `CUS-${Date.now().toString().slice(-6)}`,
    name,
    email,
    phone,
    avatar: avatar || `https://i.pravatar.cc/150?u=${encodeURIComponent(email)}`,
    ordersCount: Number(ordersCount || 0),
    totalSpending: Number(totalSpending || 0),
    status: status === 'blocked' ? 'blocked' : 'active'
  };

  users.unshift(newUser);
  res.status(201).json({ success: true, user: newUser });
});

app.put('/api/admin/users/:id', requireAdmin, (req, res) => {
  const { id } = req.params;
  const user = users.find(u => u.id === id);

  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  const { name, email, phone, avatar, ordersCount, totalSpending, status } = req.body;

  if (email) {
    const existed = users.some(u => u.id !== id && u.email.toLowerCase() === email.toLowerCase());
    if (existed) {
      return res.status(409).json({ error: 'Email khách hàng đã tồn tại' });
    }
  }

  user.name = name ?? user.name;
  user.email = email ?? user.email;
  user.phone = phone ?? user.phone;
  user.avatar = avatar ?? user.avatar;
  user.ordersCount = ordersCount == null ? user.ordersCount : Number(ordersCount);
  user.totalSpending = totalSpending == null ? user.totalSpending : Number(totalSpending);
  user.status = status === 'blocked' ? 'blocked' : 'active';

  res.json({ success: true, user });
});

app.delete('/api/admin/users/:id', requireAdmin, (req, res) => {
  const { id } = req.params;
  const beforeLength = users.length;
  users = users.filter(user => user.id !== id);

  if (users.length === beforeLength) {
    return res.status(404).json({ error: 'User not found' });
  }

  res.json({ success: true });
});

app.post('/api/admin/users/:id/status', requireAdmin, (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const user = users.find(u => u.id === id);
  if (user) {
    user.status = status;
    res.json({ success: true, user });
  } else {
    res.status(404).json({ error: 'User not found' });
  }
});

// Routes
app.get('/api/cart', (req, res) => {
  res.json(calculateCartTotals(cart));
});

app.post('/api/cart/items', (req, res) => {
  const { id, quantity } = req.body;
  const itemIndex = cart.items.findIndex(item => item.id === id);
  if (itemIndex > -1) {
    cart.items[itemIndex].quantity = quantity;
    if (cart.items[itemIndex].quantity <= 0) {
      cart.items.splice(itemIndex, 1);
    }
  }
  res.json(calculateCartTotals(cart));
});

app.post('/api/cart/items/add', (req, res) => {
  const { id, name, options, price, quantity, image, replace } = req.body;

  if (!id || !name || !price || !quantity) {
    return res.status(400).json({ error: 'Missing cart item data' });
  }

  if (replace === true) {
    cart.items = [];
  }

  const existingItem = cart.items.find(item => item.id === id);
  if (existingItem) {
    existingItem.quantity += Number(quantity);
  } else {
    cart.items.push({
      id,
      name,
      options: options || '',
      price: Number(price),
      quantity: Number(quantity),
      image: image || ''
    });
  }

  res.json(calculateCartTotals(cart));
});

app.post('/api/cart/delivery', (req, res) => {
  cart.deliveryInfo = { ...cart.deliveryInfo, ...req.body };
  res.json(calculateCartTotals(cart));
});

app.post('/api/cart/payment', (req, res) => {
  cart.paymentMethod = req.body.method;
  res.json(calculateCartTotals(cart));
});

app.post('/api/checkout', async (req, res) => {
  const orderId = Date.now();
  const isOnline = cart.paymentMethod === 'online';
  const calculatedCart = calculateCartTotals(cart);
  
  const newOrder = {
    id: orderId.toString(),
    userId: 'sample_user_id',
    orderCode: `#FH-${orderId.toString().slice(-6)}`,
    items: calculatedCart.items.map(item => ({
      productId: item.id,
      productName: item.name,
      imageUrl: item.image,
      details: item.options,
      quantity: item.quantity,
      price: item.price
    })),
    delivery: { ...calculatedCart.deliveryInfo },
    payment: cart.paymentMethod,
    total: calculatedCart.total,
    totalAmount: calculatedCart.total,
    status: isOnline ? 'pending_payment' : 'processing',
    createdAt: new Date().toISOString()
  };

  try {
    if (firestore) {
      await firestore.collection('orders').doc(newOrder.id).set({
        ...newOrder,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });
    } else {
      orders.push(newOrder);
    }
  } catch (error) {
    console.error('Save order error:', error);
    orders.push(newOrder);
  }

  if (isOnline) {
    try {
      const paymentData = {
        orderCode: orderId,
        amount: calculatedCart.total,
        description: `Thanh toan don hang ${orderId}`,
        items: cart.items.map(item => ({
          name: item.name,
          quantity: item.quantity,
          price: item.price
        })),
        returnUrl: 'fastfoodapp://payment-success',
        cancelUrl: 'fastfoodapp://payment-cancel',
      };

      const paymentLink = await payos.createPaymentLink(paymentData);
      
      // Clear cart even if online, but order is pending_payment
      cart.items = [];
      
      return res.json({ 
        success: true, 
        online: true,
        checkoutUrl: paymentLink.checkoutUrl,
        orderId: newOrder.id
      });
    } catch (error) {
      console.error('PayOS Error:', error);
      // Even if PayOS fails, the order is already in 'pending_payment' status
      cart.items = [];
      return res.json({ 
        success: true, 
        online: true, 
        error: 'PayOS link creation failed, please retry from order history',
        orderId: newOrder.id 
      });
    }
  }

  // Cash payment logic
  cart.items = [];
  res.json({ success: true, online: false, orderId: newOrder.id });
});

// Admin/User endpoint to get orders
app.get('/api/orders', async (req, res) => {
  if (!firestore) {
    return res.json(orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
  }

  try {
    const snapshot = await firestore
      .collection('orders')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();
    res.json(snapshot.docs.map(normalizeOrder));
  } catch (error) {
    console.error('Orders Firestore error:', error);
    res.json(orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
  }
});

// Retry Payment
app.post('/api/orders/:id/retry-payment', async (req, res) => {
  const { id } = req.params;
  const order = orders.find(o => o.id === id);

  if (!order) return res.status(404).json({ error: 'Order not found' });
  if (order.status !== 'pending_payment') return res.status(400).json({ error: 'Order is not in pending_payment status' });

  try {
    const paymentData = {
      orderCode: parseInt(order.id),
      amount: order.total,
      description: `Thanh toan lai don hang ${order.id}`,
      items: order.items.map(item => ({
        name: item.name,
        quantity: item.quantity,
        price: item.price
      })),
      returnUrl: 'fastfoodapp://payment-success',
      cancelUrl: 'fastfoodapp://payment-cancel',
    };

    const paymentLink = await payos.createPaymentLink(paymentData);
    res.json({ success: true, checkoutUrl: paymentLink.checkoutUrl });
  } catch (error) {
    res.status(500).json({ error: 'Không thể tạo lại link thanh toán' });
  }
});

// Cancel Order
app.post('/api/orders/:id/cancel', (req, res) => {
  const { id } = req.params;
  const order = orders.find(o => o.id === id);

  if (!order) return res.status(404).json({ error: 'Order not found' });
  order.status = 'cancelled';
  res.json({ success: true, order });
});

const webBuildPath = path.join(__dirname, '../build/web');
app.use(express.static(webBuildPath));

app.get('*', (req, res) => {
  if (req.path.startsWith('/api')) {
    return res.status(404).json({ error: 'API route not found' });
  }

  res.sendFile(path.join(webBuildPath, 'index.html'), error => {
    if (error) {
      res.status(404).send(
        'Flutter web build not found. Run: flutter build web --release'
      );
    }
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Admin web: http://localhost:${PORT}/#/admin/login`);
});

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');
const adminController = require('../controllers/adminController');

router.use(auth, requireAdmin);

router.get('/orders', adminController.listOrders);
router.patch('/orders/:id', adminController.patchOrderStatus);

router.post('/restaurants', adminController.createRestaurant);
router.put('/restaurants/:id', adminController.updateRestaurant);
router.delete('/restaurants/:id', adminController.deleteRestaurant);

router.post('/categories', adminController.createCategory);
router.put('/categories/:id', adminController.updateCategory);
router.delete('/categories/:id', adminController.deleteCategory);

router.post('/items', adminController.createMenuItem);
router.put('/items/:id', adminController.updateMenuItem);
router.delete('/items/:id', adminController.deleteMenuItem);

router.get('/vouchers', adminController.listVouchersAdmin);
router.post('/vouchers', adminController.createVoucher);
router.put('/vouchers/:code', adminController.updateVoucher);
router.delete('/vouchers/:code', adminController.deleteVoucher);

router.get('/users', adminController.listUsers);
router.patch('/users/:id', adminController.patchUser);

module.exports = router;

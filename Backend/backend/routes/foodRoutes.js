const express = require('express');
const router = express.Router();
const foodController = require('../controllers/foodController');
const optionalAuth = require('../middleware/optionalAuth');
const auth = require('../middleware/auth');

router.get('/restaurants', foodController.getRestaurants);
router.get('/vouchers', foodController.listVouchers);
router.get('/categories', foodController.getCategories);
router.get('/items', foodController.getMenuItems);
router.get('/search', foodController.searchFood);
router.post('/checkout', optionalAuth, foodController.checkout);
router.get('/my-orders', auth, foodController.getMyOrders);

module.exports = router;

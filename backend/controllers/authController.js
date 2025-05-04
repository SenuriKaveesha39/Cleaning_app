// backend/controllers/authController.js

// 1. Load environment variables
require('dotenv').config();

const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/user');

// 2. Conditional Stripe initialization
let stripe = null;
if (process.env.STRIPE_SECRET_KEY) {
  stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
} else {
  console.warn(
    '⚠️  STRIPE_SECRET_KEY not set in .env. Stripe features (customer creation) are disabled.'
  );
}

exports.register = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const tenantId = role === 'admin' ? email : req.body.tenantId;

    // 3. Stripe Customer (only if stripe is configured)
    let stripeCustomer = null;
    if (role === 'admin' && stripe) {
      stripeCustomer = await stripe.customers.create({ email });
    }

    // 4. Create and save user
    const user = new User({
      name,
      email,
      password: hashedPassword,
      role,
      tenantId,
      stripeCustomerId: stripeCustomer?.id || null
    });

    await user.save();

    // 5. Generate JWT
    const token = jwt.sign(
      { id: user._id, role: user.role, tenantId: user.tenantId },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({ token });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Server error during registration' });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Generate JWT
    const token = jwt.sign(
      { id: user._id, role: user.role, tenantId: user.tenantId },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ token });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error during login' });
  }
};

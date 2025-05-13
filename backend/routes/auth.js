const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/user'); // Assuming you have a User model
const jwt = require('jsonwebtoken');
const authMiddleware = require('../middleware/authMiddleware');
const router = express.Router();

// Register Admin Route
router.post('/register-admin', async (req, res) => {
  const { name, email, password } = req.body;
  const hashedPassword = await bcrypt.hash(password, 10);
  const user = new User({ name, email, password: hashedPassword, role: 'admin' });
  user.companyId = user._id; // Admin owns their company
  await user.save();
  res.status(201).json({ message: 'Admin registered' });
});

// Register Cleaner Route (requires admin role)
router.post('/register-cleaner', authMiddleware(['admin']), async (req, res) => {
    const { name, email, password } = req.body;
  
    // Check if the cleaner already exists
    const existingCleaner = await User.findOne({ email });
    if (existingCleaner) {
      return res.status(400).json({ message: 'Cleaner already exists' });
    }
  
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
  
    // Create a new cleaner
    const cleaner = new User({
      name,
      email,
      password: hashedPassword,
      role: 'cleaner',
      companyId: req.user.companyId // Set companyId based on admin who registered the cleaner
    });
  
    await cleaner.save();
  
    // Generate a token for the new cleaner
    const token = jwt.sign({ id: cleaner._id, role: cleaner.role }, process.env.JWT_SECRET, { expiresIn: '1h' });
  
    // Return the success message along with the cleaner's token
    res.status(201).json({
      message: 'Cleaner registered successfully by admin',
      token
    });
  });
  
// Login Route (Add this if needed)
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(400).json({ message: 'User not found' });

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });

  const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1h' });
  res.json({
    token,
    user: {
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      companyId: user.companyId
    }
  });
});

module.exports = router;

// routes/admin.js
const express = require('express');
const authMiddleware = require('../middleware/authMiddleware');
const User = require('../models/user'); // Assuming User is your model for users
const router = express.Router();

// GET /api/admin/cleaners
router.get('/cleaners', authMiddleware(['admin']), async (req, res) => {
  try {
    const admin = await User.findById(req.user.id);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }

    const cleaners = await User.find({ companyId: admin.companyId, role: 'cleaner' });
    res.json(cleaners);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;

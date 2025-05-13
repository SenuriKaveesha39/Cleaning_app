const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const Clock = require('../models/clock');

// GET clock status
router.get('/clock', auth(['cleaner']), async (req, res) => {
  const userId = req.user.id;
  const today = new Date().toISOString().split('T')[0];

  const record = await Clock.findOne({ userId, date: today });
  if (!record) return res.json({ clockIn: null, clockOut: null });

  res.json({ clockIn: record.clockIn, clockOut: record.clockOut });
});

// POST clock in/out
router.post('/clock', auth(['cleaner']), async (req, res) => {
  const { action } = req.body;
  const userId = req.user.id;
  const today = new Date().toISOString().split('T')[0];

  let record = await Clock.findOne({ userId, date: today });
  if (!record) record = new Clock({ userId, date: today });

  if (action === 'clock_in') {
    record.clockIn = new Date();
  } else if (action === 'clock_out') {
    record.clockOut = new Date();
  } else {
    return res.status(400).json({ message: 'Invalid action' });
  }

  await record.save();
  res.json({ message: 'Clock updated successfully' });
});

module.exports = router;

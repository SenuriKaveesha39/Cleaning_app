const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const Clock = require('../models/clock');

// ✅ GET today's clock status
router.get('/clock', auth(['cleaner']), async (req, res) => {
  try {
    const userId = req.user.id;
    const today = new Date().toISOString().split('T')[0];

    const record = await Clock.findOne({ userId, date: today });

    res.json({
      date: today,
      sessions: record?.sessions || []
    });
  } catch (err) {
    console.error('Error fetching clock status:', err);
    res.status(500).json({ message: 'Server error' });
  }
});


// ✅ POST clock in/out
router.post('/clock', auth(['cleaner']), async (req, res) => {
  try {
    const { action } = req.body;
    const userId = req.user.id;

    if (!['clock_in', 'clock_out'].includes(action)) {
      return res.status(400).json({ message: 'Invalid action' });
    }

    const today = new Date().toISOString().split('T')[0];
    let record = await Clock.findOne({ userId, date: today });

    if (!record) {
      record = new Clock({ userId, date: today, sessions: [] });
    }

    if (action === 'clock_in') {
      // Start a new session
      record.sessions.push({ clockIn: new Date(), clockOut: null });
    } else if (action === 'clock_out') {
      // Find the last session without a clockOut and set it
      const lastSession = record.sessions && record.sessions.length > 0
        ? record.sessions[record.sessions.length - 1]
        : null;
      if (lastSession && !lastSession.clockOut) {
        lastSession.clockOut = new Date();
      } else {
        return res.status(400).json({ message: 'No active clock-in session found' });
      }
    }

    await record.save();
    res.json({ message: 'Clock updated successfully' });
  } catch (err) {
    console.error('Clock update error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;

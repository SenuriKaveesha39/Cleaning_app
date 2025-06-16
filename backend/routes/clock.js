const express = require('express');
const Clock = require('../models/clock');
const router = express.Router();
const auth = require('../middleware/authMiddleware'); 

// GET today’s clock-in/out status
router.get('/clock-status/today', async (req, res) => {
  try {
    const userId = req.user.id;
    if (!userId) return res.status(400).json({ error: 'User ID missing' });

    const today = new Date().toISOString().split('T')[0]; // 'YYYY-MM-DD'

    const clock = await Clock.findOne({ userId: user_id, date: today });

    res.json({
      date: today,
      sessions: clock?.sessions || []
    });
  } catch (error) {
    console.error('Error in clock-status/today:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET last 7 days clock-in/out, authenticated route
  router.get('/clock-history', auth(['cleaner']), async (req, res) => {
    try {
      const userId = req.user.id;  // from auth middleware

      // Removed date filtering to get all records
      const history = await Clock.find({ userId: userId }).sort({ date: -1 });

      const formatted = history.map(entry => ({
        date: entry.date,
        sessions: entry.sessions || []
      }));

      res.json(formatted);
    } catch (error) {
      console.error('Error in clock-history:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });


module.exports = router;

const express = require("express");
const router = express.Router();
const auth = require("../middleware/authMiddleware");
const {
    getTodaysClockForCleaner,
    get7dayClockForCleaner,
} = require("../controllers/cleaner.controller");

// ✅ GET today's work assignments for the logged-in cleaner
router.get("/clocks", auth(["cleaner"]), getTodaysClockForCleaner);

// ✅ GET last 7 days clock-in/out history (cleaner only)
router.get("/clock-history", auth(["cleaner"]), get7dayClockForCleaner);

module.exports = router;

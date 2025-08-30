const express = require("express");
const router = express.Router();
const auth = require("../middleware/authMiddleware");
const { clockIn, clockOut } = require("../controllers/cleaner.controller");

// ✅ POST clock in
router.post("/clock/clock-in", auth(["cleaner"]), clockIn);

// ✅ POST clock out
router.post("/clock/clock-out", auth(["cleaner"]), clockOut);

module.exports = router;

// routes/admin.js
const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const User = require("../models/user");
const Clock = require("../models/clock");
const {
    assignWork,
    removeWork,
    updateWork,
} = require("../controllers/admin.controller");

// GET /api/admin/cleaners
// routes/admin.js
router.get("/cleaners", authMiddleware(["admin"]), async (req, res) => {
    try {
        const admin = await User.findById(req.user.id);

        if (!admin || admin.role !== "admin") {
            return res.status(403).json({ message: "Access denied" });
        }

        // Add debug logging
        console.log("Fetching cleaners for company:", admin.companyId);

        const cleaners = await User.find({
            companyId: admin.companyId,
            role: "cleaner",
        }).select("-password");

        console.log("Found cleaners:", cleaners.length);
        res.json(cleaners);
    } catch (error) {
        console.error("Error:", error);
        res.status(500).json({ message: "Server error" });
    }
});

// GET /api/admin/cleaner/:cleanerId/clock-history
router.get(
    "/cleaner/:cleanerId/clock-history",
    authMiddleware(["admin"]),
    async (req, res) => {
        try {
            const admin = await User.findById(req.user.id);
            if (!admin || admin.role !== "admin") {
                return res.status(403).json({ message: "Access denied" });
            }

            // Find the cleaner and verify they belong to this admin's company
            const cleaner = await User.findOne({
                _id: req.params.cleanerId,
                companyId: admin.companyId,
                role: "cleaner",
            });

            if (!cleaner) {
                return res.status(404).json({
                    message: "Cleaner not found or not in your company",
                });
            }

            // Fetch clock history for this cleaner
            const clockHistory = await Clock.find({ userId: cleaner._id }).sort(
                { date: -1 }
            );

            res.json(clockHistory);
        } catch (error) {
            console.error("Error fetching clock history for cleaner:", error);
            res.status(500).json({ message: "Server error" });
        }
    }
);

//Assign Work
router.post(
    "/cleaner/:cleanerId/assign",
    authMiddleware(["admin"]),
    assignWork
);

//Remove work. the clock should be in pending state
router.delete(
    "/cleaner/:cleanerId/remove-clock",
    authMiddleware(["admin"]),
    removeWork
);

//update work clock, the clock should be in pending state
router.delete(
    "/cleaner/:cleanerId/update-clock",
    authMiddleware(["admin"]),
    updateWork
);

module.exports = router;

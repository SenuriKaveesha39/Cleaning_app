const Clock = require("../models/clock");

const getTodaysClockForCleaner = async (req, res) => {
    try {
        const userId = req.user.id;

        // Get today's date (YYYY-MM-DD)
        const today = new Date().toISOString().split("T")[0];

        // Find all assignments for today (ignoring time part)
        const records = await Clock.find({
            userId,
            $expr: {
                $eq: [
                    { $dateToString: { format: "%Y-%m-%d", date: "$date" } },
                    today,
                ],
            },
        });

        res.json({
            success: true,
            date: today,
            totalAssignments: records.length,
            assignments: records.map((r) => ({
                id: r._id,
                status: r.status,
                clockIn: r.clockIn,
                clockOut: r.clockOut,
                assignedLocation: {
                    name: r.assignedLocation.name,
                    date: r.assignedLocation.date,
                    coordinates: r.assignedLocation.coordinates,
                },
            })),
        });
    } catch (err) {
        console.error("Error fetching clock status:", err);
        res.status(500).json({ success: false, message: "Server error" });
    }
};

const get7dayClockForCleaner = async (req, res) => {
    try {
        const userId = req.user.id;

        // Get today's date at 00:00
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Get the date 7 days ago
        const sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(today.getDate() - 6); // 6 + today = 7 days

        // Fetch all records in that date range
        const history = await Clock.find({
            userId,
            date: {
                $gte: sevenDaysAgo.toISOString().split("T")[0],
                $lte: today.toISOString().split("T")[0],
            },
        }).sort({ date: -1 });

        const formatted = history.map((entry) => ({
            id: entry._id,
            date: entry.date,
            status: entry.status,
            clockIn: entry.clockIn,
            clockOut: entry.clockOut,
            assignedLocation: {
                name: entry.assignedLocation.name,
                date: entry.assignedLocation.date,
                coordinates: entry.assignedLocation.coordinates,
            },
        }));

        res.json({
            success: true,
            from: sevenDaysAgo.toISOString().split("T")[0],
            to: today.toISOString().split("T")[0],
            totalRecords: formatted.length,
            history: formatted,
        });
    } catch (error) {
        console.error("Error in clock-history:", error);
        res.status(500).json({
            success: false,
            error: "Internal server error",
        });
    }
};

module.exports = { getTodaysClockForCleaner, get7dayClockForCleaner };

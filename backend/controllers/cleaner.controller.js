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

const clockIn = async (req, res) => {
    const { clockId, currentLat, currentLong } = req.body;
    const userId = req.user.id;

    try {
        // 1. Check if cleaner already has a clocked-in job
        const activeClock = await Clock.findOne({
            userId,
            status: "clockedIn",
        });
        if (activeClock) {
            return res.status(400).json({
                success: false,
                message:
                    "Please clock out from your current job before clocking in.",
            });
        }

        // 2. Find the job by ID and status
        const clock = await Clock.findOne({
            _id: clockId,
            userId,
            status: "pending",
        });
        if (!clock) {
            return res.status(404).json({
                success: false,
                message: "Job not found or already clocked in/completed.",
            });
        }

        // 3. Check proximity using $near
        const nearby = await Clock.findOne({
            _id: clockId,
            "assignedLocation.coordinates": {
                $near: {
                    $geometry: {
                        type: "Point",
                        coordinates: [currentLong, currentLat], // [lng, lat]
                    },
                    $maxDistance: 50, // 50 meters radius
                },
            },
        });

        if (!nearby) {
            return res.status(403).json({
                success: false,
                message:
                    "Cannot clock in: you are not within the range of assigned location.",
            });
        }

        // 4. Clock in
        clock.status = "clockedIn";
        clock.clockIn = new Date();
        await clock.save();

        res.json({
            success: true,
            message: "Clocked in successfully!",
            clock,
        });
    } catch (err) {
        console.error("ClockIn Error:", err);
        res.status(500).json({ success: false, message: "Server error" });
    }
};

const clockOut = async (req, res) => {
    const { clockId, currentLat, currentLong } = req.body;
    const userId = req.user.id;

    try {
        // 1. Find the job by ID, belonging to user, and currently clockedIn
        const clock = await Clock.findOne({
            _id: clockId,
            userId,
            status: "clockedIn",
        });
        if (!clock) {
            return res.status(400).json({
                success: false,
                message:
                    "Cannot clock out: job not found or not currently clocked in.",
            });
        }

        // 2. Optional: check proximity to assigned location for clock-out
        const nearby = await Clock.findOne({
            _id: clockId,
            "assignedLocation.coordinates": {
                $near: {
                    $geometry: {
                        type: "Point",
                        coordinates: [currentLong, currentLat], // [lng, lat]
                    },
                    $maxDistance: 50, // 50 meters radius
                },
            },
        });

        if (!nearby) {
            return res.status(403).json({
                success: false,
                message:
                    "Cannot clock out: you are not within the rangr of assigned location.",
            });
        }

        // 3. Clock out
        clock.status = "clockedOut";
        clock.clockOut = new Date();
        await clock.save();

        res.json({
            success: true,
            message: "Clocked out successfully!",
            clock,
        });
    } catch (err) {
        console.error("ClockOut Error:", err);
        res.status(500).json({ success: false, message: "Server error" });
    }
};

module.exports = {
    getTodaysClockForCleaner,
    get7dayClockForCleaner,
    clockIn,
    clockOut,
};

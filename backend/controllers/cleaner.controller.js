const { Clock } = require("../models/clock");
const User = require("../models/user");

const getTodaysClockForCleaner = async (req, res) => {
    try {
        const userId = req.user.id;

        // Get today's start and end (midnight → 23:59:59)
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);

        const endOfDay = new Date();
        endOfDay.setHours(23, 59, 59, 999);

        // Find today's clock records using createdAt
        const records = await Clock.find({
            userId,
            createdAt: { $gte: startOfDay, $lte: endOfDay },
        });

        res.json({
            success: true,
            totalAssignments: records.length,
            clocks: records.map((r) => ({
                id: r._id,
                status: r.status,
                clockIn: r.clockIn,
                clockOut: r.clockOut,
                assignedLocation: {
                    name: r.assignedLocation.name,
                    coordinates: r.assignedLocation.coordinates,
                },
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
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

        // Get the date 6 days before today (7-day range total)
        const sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(today.getDate() - 6);

        // Fetch all records in that date range
        const history = await Clock.find({
            userId,
            createdAt: { $gte: sevenDaysAgo, $lte: new Date() }, // include up to now
        }).sort({ createdAt: -1 });

        const formatted = history.map((entry) => ({
            id: entry._id,
            date: entry.createdAt.toISOString().split("T")[0], // format for output
            status: entry.status,
            clockIn: entry.clockIn,
            clockOut: entry.clockOut,
            assignedLocation: {
                name: entry.assignedLocation.name,
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
    const { locationId, currentLat, currentLong } = req.body;
    const userId = req.user.id;

    console.log(locationId);

    try {
        // 1. Check if cleaner already has an active clock
        const activeClock = await Clock.findOne({
            userId,
            status: "clockedIn",
        });
        if (activeClock) {
            return res.status(400).json({
                success: false,
                message: "Please clock out before clocking in again.",
            });
        }

        // 2. Load user & check assigned location
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found.",
            });
        }

        const assignedLocation = user.clockLocations.id(locationId);
        if (!assignedLocation) {
            return res.status(403).json({
                success: false,
                message: "You are not assigned to this location.",
            });
        }

        // 3. Verify cleaner is physically near the assigned location
        const nearby = await User.findOne({
            _id: userId,
            "clockLocations._id": locationId,
            "clockLocations.coordinates": {
                $near: {
                    $geometry: {
                        type: "Point",
                        coordinates: [currentLong, currentLat], // [lng, lat]
                    },
                    $maxDistance: 50, // within 50 meters
                },
            },
        });

        if (!nearby) {
            return res.status(403).json({
                success: false,
                message:
                    "Cannot clock in: you are not within range of the assigned location.",
            });
        }

        // 4. Create new Clock entry with assignedLocation snapshot
        const newClock = new Clock({
            userId,
            assignedLocation: assignedLocation.toObject(), // embed location snapshot
            status: "clockedIn",
            clockIn: new Date(),
        });

        await newClock.save();

        res.json({
            success: true,
            message: "Clocked in successfully!",
            clock: newClock,
        });
    } catch (err) {
        console.error("ClockIn Error:", err);
        res.status(500).json({ success: false, message: "Server error" });
    }
};

const clockOut = async (req, res) => {
    const { currentLat, currentLong } = req.body;
    const userId = req.user.id;

    try {
        // 1. Find the active clock for this user
        const clock = await Clock.findOne({
            userId,
            status: "clockedIn",
        }).sort({ clockIn: -1 }); // get most recent one if multiple

        if (!clock) {
            return res.status(400).json({
                success: false,
                message: "Cannot clock out: no active clock found.",
            });
        }

        // 2. Check proximity to the same assigned location
        const nearby = await Clock.findOne({
            _id: clock._id,
            "assignedLocation.coordinates": {
                $near: {
                    $geometry: {
                        type: "Point",
                        coordinates: [currentLong, currentLat], // [lng, lat]
                    },
                    $maxDistance: 50, // within 50 meters
                },
            },
        });

        if (!nearby) {
            return res.status(403).json({
                success: false,
                message:
                    "Cannot clock out: you are not within the range of the assigned location.",
            });
        }

        // 3. Update clock
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

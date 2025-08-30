const User = require("../models/user");
const Clock = require("../models/clock");

const assignWork = async (req, res) => {
    const { email, date, locationName, long, lat } = req.body;

    try {
        const cleaner = await User.findOne({ email });

        if (!cleaner || !cleaner.active || cleaner.role !== "cleaner") {
            return res.status(404).json({
                success: false,
                message: "User not found, inactive, or not a cleaner",
            });
        }

        const newLocation = {
            name: locationName,
            coordinates: {
                type: "Point",
                coordinates: [long, lat], // [longitude, latitude]
            },
        };

        const clock = new Clock({
            userId: cleaner._id,
            date: new Date(date),
            assignedLocation: newLocation,
        });

        await clock.save();

        return res.json({
            message: "Job assigned successfully",
            clock,
        });
    } catch (err) {
        console.error("AssignWork Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server error",
        });
    }
};

const removeWork = async (req, res) => {
    const { clockId } = req.body;

    try {
        // 1. Check if job exists
        const clock = await Clock.findById(clockId);

        if (!clock) {
            return res.status(404).json({
                success: false,
                message: "Job not found",
            });
        }

        // 2. Only allow removal if status is still pending
        if (clock.status !== "pending") {
            return res.status(400).json({
                success: false,
                message:
                    "Job cannot be removed. Already clocked in or completed.",
            });
        }

        // 3. Remove the job
        await Clock.findByIdAndDelete(clockId);

        return res.json({
            success: true,
            message: "Pending job removed successfully",
        });
    } catch (err) {
        console.error("RemoveWork Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server error",
        });
    }
};

const updateWork = async (req, res) => {
    const { clockId, date, locationName, long, lat } = req.body;

    try {
        const clock = await Clock.findById(clockId);

        if (!clock) {
            return res
                .status(404)
                .json({ success: false, message: "Job not found" });
        }

        if (clock.status !== "pending") {
            return res.status(400).json({
                success: false,
                message: "Cannot update job that is not pending",
            });
        }

        if (date) clock.date = new Date(date);
        if (locationName || long || lat) {
            clock.assignedLocation = {
                name: locationName || clock.assignedLocation.name,
                coordinates: {
                    type: "Point",
                    coordinates: [
                        long || clock.assignedLocation.coordinates[0],
                        lat || clock.assignedLocation.coordinates[1],
                    ],
                },
            };
        }

        await clock.save();

        return res.json({
            success: true,
            message: "Job updated successfully",
            clock,
        });
    } catch (err) {
        console.error("UpdateWork Error:", err);
        return res
            .status(500)
            .json({ success: false, message: "Server error" });
    }
};

module.exports = { assignWork, removeWork, updateWork };

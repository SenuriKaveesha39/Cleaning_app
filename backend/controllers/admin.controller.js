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

module.exports = assignWork;

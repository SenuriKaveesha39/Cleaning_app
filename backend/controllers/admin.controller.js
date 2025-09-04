const User = require("../models/user");

const assignWork = async (req, res) => {
    const { email, workArray } = req.body;

    try {
        const cleaner = await User.findOne({ email });

        if (!cleaner || !cleaner.active || cleaner.role !== "cleaner") {
            return res.status(404).json({
                success: false,
                message: "User not found, inactive, or not a cleaner",
            });
        }

        const formattedWorkArray = workArray.map((work) => ({
            name: work.locationName,
            coordinates: {
                type: "Point",
                coordinates: [work.long, work.lat], // [longitude, latitude]
            },
        }));

        const updated = await User.findByIdAndUpdate(
            cleaner._id,
            {
                clockLocations: formattedWorkArray,
            },
            { new: true, runValidators: true }
        ).select("-password -__v");

        return res.json({
            success: true,
            message: "Jobs updated successfully",
            updated,
        });
    } catch (err) {
        console.error("AssignWork Error:", err);

        return res.status(500).json({
            success: false,
            message: "Server error",
        });
    }
};

const setOperatingLocations = async (req, res) => {
    const userId = req.user.id;
    const { locations } = req.body; // expecting array of { locationName, lat, long }

    try {
        if (!Array.isArray(locations)) {
            return res.status(400).json({
                success: false,
                message: "Locations must be an array",
            });
        }

        // Format to match locationSchema
        const formattedLocations = locations.map((loc) => ({
            name: loc.locationName,
            coordinates: {
                type: "Point",
                coordinates: [loc.long, loc.lat], // [longitude, latitude]
            },
        }));

        const updatedUser = await User.findByIdAndUpdate(
            userId,
            { operatingLocations: formattedLocations }, // overwrite old array
            { new: true, runValidators: true }
        ).select("-password -__v");

        if (!updatedUser) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        return res.json({
            success: true,
            message: "Operating locations updated successfully",
            operatingLocations: updatedUser.operatingLocations,
        });
    } catch (err) {
        console.error("SetOperatingLocations Error:", err);
        return res.status(500).json({
            success: false,
            message: "Server error",
        });
    }
};

module.exports = { assignWork, setOperatingLocations };

const mongoose = require("mongoose");

const locationSchema = new mongoose.Schema({
    name: { type: String, required: true },
    date: { type: Date, required: true },
    coordinates: {
        type: {
            type: String,
            enum: ["Point"],
            required: true,
            default: "Point",
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            required: true,
        },
    },
});
locationSchema.index({ coordinates: "2dsphere" });

const clockSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
    },

    date: { type: Date, required: true },

    status: {
        type: String,
        enum: ["pending", "clockedIn", "clockedOut"],
        default: "pending",
    },

    clockIn: { type: Date },

    clockOut: { type: Date },

    assignedLocation: { type: locationSchema, required: true },
});

const Clock = mongoose.model("Clock", clockSchema);
module.exports = Clock;

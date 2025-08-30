const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
    name: { type: String, required: true },

    avatar: {
        type: String,
        trim: true,
        default: "https://icon-icons.com/icon/avatar-default-user/92824",
        required: true,
    },

    email: {
        type: String,
        required: [true, "Email is required"],
        trim: true,
        lowercase: true,
        match: [/^\S+@\S+\.\S+$/, "Please enter a valid email"],
        unique: true,
    },

    password: { type: String, required: true },

    role: { type: String, enum: ["admin", "cleaner"], required: true },

    companyId: { type: mongoose.Schema.Types.ObjectId, ref: "User" }, // Admin's ID or a Company model ID

    active: { type: Boolean, default: true },
});

const User = mongoose.model("User", userSchema);
module.exports = User;

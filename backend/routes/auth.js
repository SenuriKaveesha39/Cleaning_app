const express = require("express");
const bcrypt = require("bcryptjs");
const User = require("../models/user"); // Assuming you have a User model
const jwt = require("jsonwebtoken");
const authMiddleware = require("../middleware/authMiddleware");
const router = express.Router();

// Register Admin Route
router.post("/register-admin", async (req, res) => {
    const { name, email, password } = req.body;

    try {
        // 1. Check if user with this email already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: "Email is already registered.",
            });
        }

        // 2. Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // 3. Create new admin user
        const user = new User({
            name,
            email,
            password: hashedPassword,
            role: "admin",
        });

        // Admin owns their own company
        user.companyId = user._id;

        // 4. Save to database
        await user.save();

        res.status(201).json({
            success: true,
            message: "Admin registered successfully.",
            userId: user._id,
        });
    } catch (err) {
        console.error("Register Admin Error:", err);
        res.status(500).json({
            success: false,
            message: "Server error. Please try again later.",
        });
    }
});

// Register Cleaner Route (requires admin role)
router.post(
    "/register-cleaner",
    authMiddleware(["admin"]),
    async (req, res) => {
        const { name, email, password } = req.body;

        try {
            // 1. Find the admin to get the correct companyId
            const admin = await User.findById(req.user.id);
            if (!admin || admin.role !== "admin") {
                return res.status(403).json({
                    success: false,
                    message: "Access denied",
                });
            }

            // 2. Check if the cleaner already exists
            const existingCleaner = await User.findOne({ email });
            if (existingCleaner) {
                return res.status(400).json({
                    success: false,
                    message: "Cleaner with this email already exists",
                });
            }

            // 3. Hash password
            const hashedPassword = await bcrypt.hash(password, 10);

            // 4. Create a new cleaner
            const cleaner = new User({
                name,
                email,
                password: hashedPassword,
                role: "cleaner",
                companyId: admin.companyId, // assign companyId from admin
            });

            await cleaner.save();

            // 5. Generate JWT token for the new cleaner
            const token = jwt.sign(
                {
                    id: cleaner._id,
                    role: cleaner.role,
                    companyId: cleaner.companyId,
                },
                process.env.JWT_SECRET,
                { expiresIn: "1h" }
            );

            // 6. Send response
            res.status(201).json({
                success: true,
                message: "Cleaner registered successfully by admin",
                token,
            });
        } catch (err) {
            console.error("Register Cleaner Error:", err);
            res.status(500).json({
                success: false,
                message: "Server error. Please try again later.",
            });
        }
    }
);

// Login Route (Add this if needed)
router.post("/login", async (req, res) => {
    const { email, password } = req.body;

    try {
        // 1. Find user by email
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        // 2. Compare passwords
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({
                success: false,
                message: "Invalid credentials",
            });
        }

        // 3. Generate JWT token
        const token = jwt.sign(
            { id: user._id, role: user.role, companyId: user.companyId },
            process.env.JWT_SECRET,
            { expiresIn: "1h" }
        );

        // 4. Send response
        res.json({
            success: true,
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                companyId: user.companyId,
            },
        });
    } catch (err) {
        console.error("Login Error:", err);
        res.status(500).json({
            success: false,
            message: "Server error. Please try again later.",
        });
    }
});

module.exports = router;

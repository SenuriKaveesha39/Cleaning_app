const express = require("express");
const connectDB = require("./config/db");
const cors = require("cors");
require("dotenv").config();
const clockRoutes = require("./routes/clock");
const cleanerRoutes = require("./routes/cleaners");
var morgan = require("morgan");

const app = express();
connectDB();

app.use(cors());
app.use(morgan("tiny"));
app.use(express.json());

app.use("/api/auth", require("./routes/auth"));

// Importing the routes for admin actions (e.g., cleaners)
app.use("/api/admin", require("./routes/admin")); // Add this line

app.use("/api/cleaner", cleanerRoutes);

app.use("/api/cleaner", clockRoutes);

app.listen(process.env.PORT, () =>
    console.log(`Server running on port ${process.env.PORT}`)
);

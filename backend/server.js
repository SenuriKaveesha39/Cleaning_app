const express = require('express');
const connectDB = require('./config/db');
const cors = require('cors');
require('dotenv').config();

const app = express();
connectDB();

app.use(cors());
app.use(express.json());

app.use('/api/auth', require('./routes/auth'));

// Importing the routes for admin actions (e.g., cleaners)
app.use('/api/admin', require('./routes/admin'));  // Add this line
app.listen(process.env.PORT, () => console.log(`Server running on port ${process.env.PORT}`));

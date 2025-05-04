const express = require('express');
const connectDB = require('./config/db');
const cors = require('cors');
require('dotenv').config();

const app = express();
connectDB();

app.use(cors());
app.use(express.json());

app.use('/api/auth', require('./routes/auth'));
// More routes...

app.listen(process.env.PORT, () => console.log(`Server running on port ${process.env.PORT}`));

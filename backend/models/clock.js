const mongoose = require('mongoose');

const clockSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: String, required: true }, // Store as YYYY-MM-DD
  clockIn: { type: Date },
  clockOut: { type: Date }
});

const Clock = mongoose.model('Clock', clockSchema);
module.exports = Clock;

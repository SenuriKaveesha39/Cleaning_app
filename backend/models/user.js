const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: String,
  role: { type: String, enum: ['admin', 'cleaner'], default: 'cleaner' },
  tenantId: String,
  stripeCustomerId: String
});

module.exports = mongoose.model('User', userSchema);

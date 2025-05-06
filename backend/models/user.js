const mongoose = require('mongoose');


const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: String,
  role: { type: String, enum: ['admin', 'cleaner'], required: true },
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' } // Admin's ID or a Company model ID
});
module.exports = mongoose.model('User', userSchema);

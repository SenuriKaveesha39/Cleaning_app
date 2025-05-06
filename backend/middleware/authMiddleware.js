const jwt = require('jsonwebtoken');

const authMiddleware = (roles = []) => {
  return async (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1]; // Bearer token
    if (!token) {
      return res.status(401).json({ message: 'Access Denied: No token provided' });
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = decoded; // Attach user to request object
      // Check if user has required role
      if (roles.length && !roles.includes(req.user.role)) {
        return res.status(403).json({ message: 'Access Denied: Insufficient permissions' });
      }

      next(); // Proceed to the next middleware or route handler
    } catch (error) {
      return res.status(400).json({ message: 'Invalid token' });
    }
  };
};

module.exports = authMiddleware;

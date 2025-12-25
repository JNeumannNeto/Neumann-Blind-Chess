import jwt from 'jsonwebtoken';
import User from '../models/User.js';

export const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Pegar token do header
      token = req.headers.authorization.split(' ')[1];

      // Verificar token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Adicionar usuario ao request
      req.user = await User.findById(decoded.id).select('-password');

      next();
 } catch (error) {
      console.error(error);
      return res.status(401).json({ message: 'Nao autorizado, token invalido' });
    }
  }

  if (!token) {
    return res.status(401).json({ message: 'Nao autorizado, sem token' });
  }
};

// Gerar JWT
export const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: '7d'
  });
};

import express from 'express';
import { body } from 'express-validator';
import { register, login, getMe, searchUsers, getAllUsers } from '../controllers/authController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// @routePOST /api/auth/register
// @desc  Registrar novo usuario
// @access  Public
router.post('/register', [
  body('username').trim().isLength({ min: 3, max: 30 }).withMessage('Username deve ter entre 3 e 30 caracteres'),
  body('email').isEmail().withMessage('Email invalido'),
  body('password').isLength({ min: 6 }).withMessage('Senha deve ter pelo menos 6 caracteres')
], register);

// @route   POST /api/auth/login
// @desc    Login de usuario
// @access  Public
router.post('/login', [
  body('email').isEmail().withMessage('Email invalido'),
  body('password').notEmpty().withMessage('Senha obrigatoria')
], login);

// @route   GET /api/auth/me
// @desc    Obter usuario atual
// @access  Private
router.get('/me', protect, getMe);

// @route   GET /api/auth/search
// @desc    Buscar usuarios por nome
// @access  Private
router.get('/search', protect, searchUsers);

// @route   GET /api/auth/users
// @desc    Listar todos usuarios
// @access  Private
router.get('/users', protect, getAllUsers);

export default router;

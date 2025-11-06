import express from 'express';
import { 
  createGame,
  acceptGame,
  makeMove, 
  getGame, 
  getUserGames,
  getCurrentGame,
  getPendingGames,
  declineGame,
  endGame 
} from '../controllers/gameController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// Todas as rotas requerem autenticacao
router.use(protect);

// @route   POST /api/games
// @desc    Criar nova partida
// @access  Private
router.post('/', createGame);

// @route   GET /api/games/current
// @desc    Obter partida atual em andamento
// @access  Private
router.get('/current', getCurrentGame);

// @route   GET /api/games/pending
// @desc    Obter convites pendentes
// @access  Private
router.get('/pending', getPendingGames);

// @route   GET /api/games/user/:userId
// @desc    Obter todas as partidas de um usuario
// @access  Private
router.get('/user/:userId', getUserGames);

// @route   GET /api/games/:gameId
// @desc    Obter detalhes de uma partida
// @access  Private
router.get('/:gameId', getGame);

// @route   POST /api/games/:gameId/accept
// @desc    Aceitar desafio
// @access  Private
router.post('/:gameId/accept', acceptGame);

// @route   DELETE /api/games/:gameId
// @desc    Recusar/Cancelar partida
// @access  Private
router.delete('/:gameId', declineGame);

// @route   POST /api/games/:gameId/move
// @desc  Fazer um movimento
// @access  Private
router.post('/:gameId/move', makeMove);

// @route   PUT /api/games/:gameId/end
// @desc    Encerrar partida
// @access  Private
router.put('/:gameId/end', endGame);

export default router;

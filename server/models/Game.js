import mongoose from 'mongoose';

const moveSchema = new mongoose.Schema({
  from: { type: String, required: true },
  to: { type: String, required: true },
  piece: { type: String, required: true },
  captured: { type: String },
  promotion: { type: String },
  san: { type: String, required: true },
  timestamp: { type: Date, default: Date.now }
});

const gameSchema = new mongoose.Schema({
  whitePlayer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false  // Agora pode ser null para desafios livres
  },
  blackPlayer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false  // Agora pode ser null para desafios livres
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  isOpenChallenge: {
    type: Boolean,
    default: false  // True se for desafio livre (aberto para qualquer um)
  },
  accepted: {
    type: Boolean,
    default: false  // True quando o desafio for aceito
  },
  moves: [moveSchema],
  currentFen: {
    type: String,
    default: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
  },
  status: {
    type: String,
    enum: ['pendente', 'em_andamento', 'xeque_mate', 'empate', 'abandonada'],
    default: 'pendente'  // Começa como pendente até ser aceito
  },
  winner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  startedAt: {
    type: Date,
    default: Date.now
  },
  endedAt: {
    type: Date
  },
  result: {
    type: String,
    enum: ['1-0', '0-1', '1/2-1/2', null],
    default: null
  }
});

// Index para buscar jogos de um usuario
gameSchema.index({ whitePlayer: 1, blackPlayer: 1 });
gameSchema.index({ status: 1 });
gameSchema.index({ isOpenChallenge: 1, accepted: 1 });

export default mongoose.model('Game', gameSchema);

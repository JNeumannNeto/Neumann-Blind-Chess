import Game from '../models/Game.js';
import User from '../models/User.js';

// @desc    Criar nova partida
// @route   POST /api/games
// @access  Private
export const createGame = async (req, res) => {
  try {
    const { opponentId, myColor } = req.body;
    const creatorId = req.user._id;

    // Validar cor escolhida
    if (!myColor || (myColor !== 'white' && myColor !== 'black')) {
    return res.status(400).json({ message: 'Cor invalida. Escolha white ou black' });
    }

    // Verificar se o jogador ja tem jogo em andamento ou pendente
    // Incluir verificação por createdBy para pegar desafios livres
    const existingGame = await Game.findOne({
      $or: [
        { whitePlayer: creatorId, status: { $in: ['pendente', 'em_andamento'] } },
        { blackPlayer: creatorId, status: { $in: ['pendente', 'em_andamento'] } },
    { createdBy: creatorId, status: { $in: ['pendente', 'em_andamento'] } }
      ]
    });

    if (existingGame) {
      return res.status(400).json({ 
     message: 'Voce ja tem uma partida pendente ou em andamento',
        gameId: existingGame._id
  });
    }

    let gameData;
    
    // Se não tem oponente, criar desafio livre
    if (!opponentId) {
   gameData = {
        whitePlayer: myColor === 'white' ? creatorId : null,
        blackPlayer: myColor === 'black' ? creatorId : null,
        createdBy: creatorId,
  isOpenChallenge: true,
        status: 'pendente',
        accepted: false
      };
    } else {
    // Desafio direto a um oponente específico
      const opponent = await User.findById(opponentId);
      if (!opponent) {
     return res.status(404).json({ message: 'Oponente nao encontrado' });
      }

      // Verificar se nao esta desafiando a si mesmo
      if (creatorId.toString() === opponentId.toString()) {
        return res.status(400).json({ message: 'Voce nao pode desafiar a si mesmo' });
  }

      // Verificar se oponente ja tem jogo pendente ou em andamento
      const opponentGame = await Game.findOne({
        $or: [
  { whitePlayer: opponentId, status: { $in: ['pendente', 'em_andamento'] } },
          { blackPlayer: opponentId, status: { $in: ['pendente', 'em_andamento'] } },
          { createdBy: opponentId, status: { $in: ['pendente', 'em_andamento'] } }
      ]
      });

      if (opponentGame) {
        return res.status(400).json({ 
       message: 'O oponente ja tem uma partida pendente ou em andamento'
        });
      }

      gameData = {
   whitePlayer: myColor === 'white' ? creatorId : opponentId,
        blackPlayer: myColor === 'white' ? opponentId : creatorId,
        createdBy: creatorId,
        isOpenChallenge: false,
  status: 'pendente',
        accepted: false
      };
    }

    const game = await Game.create(gameData);
    
    // Popular apenas os campos que não são null
    const populateFields = [];
    if (game.whitePlayer) populateFields.push({ path: 'whitePlayer', select: 'username email' });
    if (game.blackPlayer) populateFields.push({ path: 'blackPlayer', select: 'username email' });
    populateFields.push({ path: 'createdBy', select: 'username email' });
    
    await game.populate(populateFields);

    res.status(201).json(game);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao criar partida' });
  }
};

// @desc    Aceitar desafio
// @route   POST /api/games/:gameId/accept
// @access  Private
export const acceptGame = async (req, res) => {
  try {
    const { gameId } = req.params;
    const userId = req.user._id;

    const game = await Game.findById(gameId);

    if (!game) {
      return res.status(404).json({ message: 'Partida nao encontrada' });
    }

    if (game.accepted) {
    return res.status(400).json({ message: 'Partida ja foi aceita' });
    }

    if (game.status !== 'pendente') {
return res.status(400).json({ message: 'Esta partida nao esta mais disponivel' });
    }

    // Verificar se o usuário já tem jogo em andamento
    const existingGame = await Game.findOne({
      $or: [
   { whitePlayer: userId, status: { $in: ['pendente', 'em_andamento'] } },
        { blackPlayer: userId, status: { $in: ['pendente', 'em_andamento'] } }
      ],
      _id: { $ne: gameId }
    });

    if (existingGame) {
      return res.status(400).json({ 
        message: 'Voce ja tem uma partida pendente ou em andamento'
      });
    }

    // Não pode aceitar próprio desafio
    if (game.createdBy.toString() === userId.toString()) {
      return res.status(400).json({ message: 'Voce nao pode aceitar seu proprio desafio' });
  }

    // Se for desafio genérico, preencher o oponente
    if (game.isOpenChallenge) {
    if (!game.whitePlayer) {
        game.whitePlayer = userId;
      } else if (!game.blackPlayer) {
        game.blackPlayer = userId;
      }
    } else {
      // Verificar se é o oponente designado
      const isDesignatedOpponent = 
        game.whitePlayer.toString() === userId.toString() || 
        game.blackPlayer.toString() === userId.toString();

      if (!isDesignatedOpponent) {
        return res.status(403).json({ message: 'Este desafio nao e para voce' });
      }
    }

  game.accepted = true;
    game.status = 'em_andamento';
    await game.save();
    await game.populate('whitePlayer blackPlayer createdBy', 'username email');

    res.json(game);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao aceitar partida' });
  }
};

// @desc    Obter convites pendentes (desafios diretos + desafios genéricos)
// @route   GET /api/games/pending
// @access  Private
export const getPendingGames = async (req, res) => {
  try {
 const userId = req.user._id;

 // Desafios diretos para mim (não aceitos ainda)
    const directChallenges = await Game.find({
      $or: [
        { whitePlayer: userId },
        { blackPlayer: userId }
   ],
      status: 'pendente',
      accepted: false,
  createdBy: { $ne: userId }
 })
    .populate([
      { path: 'whitePlayer', select: 'username email' },
      { path: 'blackPlayer', select: 'username email' },
      { path: 'createdBy', select: 'username email' }
    ])
    .sort({ startedAt: -1 });

    // Desafios genéricos (abertos para qualquer um)
    const openChallenges = await Game.find({
      isOpenChallenge: true,
      status: 'pendente',
      accepted: false,
      createdBy: { $ne: userId }
    })
  .populate([
      { path: 'whitePlayer', select: 'username email' },
    { path: 'blackPlayer', select: 'username email' },
      { path: 'createdBy', select: 'username email' }
    ])
    .sort({ startedAt: -1 });

    // Meus desafios pendentes (que eu criei)
    const myChallenges = await Game.find({
   createdBy: userId,
   status: 'pendente',
   accepted: false
    })
    .populate([
      { path: 'whitePlayer', select: 'username email' },
   { path: 'blackPlayer', select: 'username email' },
    { path: 'createdBy', select: 'username email' }
    ])
  .sort({ startedAt: -1 });

    // Jogos aceitos e em andamento
  const activeGames = await Game.find({
      $or: [
   { whitePlayer: userId },
  { blackPlayer: userId }
      ],
      status: 'em_andamento',
      accepted: true
    })
    .populate([
      { path: 'whitePlayer', select: 'username email' },
    { path: 'blackPlayer', select: 'username email' },
    { path: 'createdBy', select: 'username email' }
    ])
  .sort({ startedAt: -1 });

    res.json({
directChallenges,
      openChallenges,
    myChallenges,
      activeGames
  });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao obter convites pendentes' });
  }
};

// @desc    Obter todas partidas de um usuario
// @route   GET /api/games/user/:userId
// @access  Private
export const getUserGames = async (req, res) => {
  try {
    const { userId } = req.params;
    const { status, limit = 20, page = 1 } = req.query;

    const query = {
      $or: [
        { whitePlayer: userId },
        { blackPlayer: userId }
      ],
      $and: [
        {
          $or: [
            { accepted: true },  // Jogos aceitos
            { status: { $ne: 'pendente' } }  // Ou jogos finalizados
          ]
        }
      ]
    };

    if (status) {
      query.status = status;
    }

    const games = await Game.find(query)
      .populate('whitePlayer blackPlayer winner createdBy', 'username email')
      .sort({ startedAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Game.countDocuments(query);

    res.json({
      games,
      currentPage: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit)),
      totalGames: total
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao obter partidas' });
  }
};

// @desc Obter partida atual em andamento
// @route   GET /api/games/current
// @access  Private
export const getCurrentGame = async (req, res) => {
  try {
    const userId = req.user._id;

    const game = await Game.findOne({
  $or: [
        { whitePlayer: userId },
     { blackPlayer: userId }
      ],
      status: 'em_andamento',
      accepted: true
    }).populate('whitePlayer blackPlayer createdBy', 'username email');

    if (!game) {
      return res.status(404).json({ message: 'Nenhuma partida em andamento' });
    }

    res.json(game);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao obter partida atual' });
  }
};

// @desc    Obter detalhes da partida
// @route   GET /api/games/:gameId
// @access  Private
export const getGame = async (req, res) => {
  try {
    const { gameId } = req.params;

    const game = await Game.findById(gameId)
      .populate('whitePlayer blackPlayer winner createdBy', 'username email stats');

    if (!game) {
      return res.status(404).json({ message: 'Partida nao encontrada' });
    }

    // Verificar se usuario e um dos jogadores
    const userId = req.user._id.toString();
    const isPlayer = 
      game.whitePlayer._id.toString() === userId || 
      game.blackPlayer._id.toString() === userId;

    if (!isPlayer) {
      return res.status(403).json({ message: 'Voce nao tem acesso a esta partida' });
    }

    res.json(game);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao obter partida' });
  }
};

// @desc    Recusar/Cancelar partida (apenas se nao tiver movimentos)
// @route   DELETE /api/games/:gameId
// @access  Private
export const declineGame = async (req, res) => {
  try {
    const { gameId } = req.params;
    const userId = req.user._id;

    const game = await Game.findById(gameId);

    if (!game) {
      return res.status(404).json({ message: 'Partida nao encontrada' });
    }

    // Verificar se e um dos jogadores ou o criador
    const isWhite = game.whitePlayer && game.whitePlayer.toString() === userId.toString();
    const isBlack = game.blackPlayer && game.blackPlayer.toString() === userId.toString();
    const isCreator = game.createdBy.toString() === userId.toString();

    if (!isWhite && !isBlack && !isCreator) {
      return res.status(403).json({ message: 'Voce nao e um jogador desta partida' });
    }

    // So pode recusar se nao houver movimentos
 if (game.moves.length > 0) {
      return res.status(400).json({ message: 'Nao e possivel recusar uma partida que ja comecou' });
    }

 // Deletar a partida
    await Game.findByIdAndDelete(gameId);

    res.json({ message: 'Partida recusada com sucesso' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao recusar partida' });
  }
};

// @desc    Fazer movimento
// @route   POST /api/games/:gameId/move
// @access  Private
export const makeMove = async (req, res) => {
  try {
    const { gameId } = req.params;
    const { from, to, piece, captured, promotion, san, fen } = req.body;
    const userId = req.user._id;

    const game = await Game.findById(gameId);

    if (!game) {
      return res.status(404).json({ message: 'Partida nao encontrada' });
    }

    if (game.status !== 'em_andamento') {
    return res.status(400).json({ message: 'Partida ja finalizada' });
    }

    // Verificar se e um dos jogadores
    const isWhite = game.whitePlayer.toString() === userId.toString();
    const isBlack = game.blackPlayer.toString() === userId.toString();

    if (!isWhite && !isBlack) {
   return res.status(403).json({ message: 'Voce nao e um jogador desta partida' });
    }

    // Adicionar movimento
    game.moves.push({
      from,
      to,
      piece,
      captured,
      promotion,
      san
 });

    // Atualizar FEN
    if (fen) {
      game.currentFen = fen;
    }

    await game.save();

    res.json(game);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao fazer movimento' });
  }
};

// @desc    Encerrar partida
// @route   PUT /api/games/:gameId/end
// @access  Private
export const endGame = async (req, res) => {
  try {
    const { gameId } = req.params;
 const { status, result, winnerId } = req.body;
    const userId = req.user._id;

    console.log('═══════════════════════════════════════════');
    console.log('📥 endGame chamado:');
    console.log('   gameId:', gameId);
 console.log('   status:', status);
    console.log('   result:', result);
 console.log('   winnerId:', winnerId);
    console.log('   userId (quem chamou):', userId);
    console.log('═══════════════════════════════════════════');

    const game = await Game.findById(gameId);

    if (!game) {
      console.log('❌ Jogo não encontrado:', gameId);
   return res.status(404).json({ message: 'Partida nao encontrada' });
    }

  // Verificar se e um dos jogadores
    const isWhite = game.whitePlayer.toString() === userId.toString();
    const isBlack = game.blackPlayer.toString() === userId.toString();

    if (!isWhite && !isBlack) {
      console.log('❌ Usuário não é jogador. whitePlayer:', game.whitePlayer, 'blackPlayer:', game.blackPlayer);
      return res.status(403).json({ message: 'Voce nao e um jogador desta partida' });
    }

    console.log('✅ Usuário autorizado. Atualizando jogo...');
    console.log('   Status anterior:', game.status);
    console.log('   Novo status:', status);
    console.log('   Result:', result);

    game.status = status;
    game.result = result;
    game.endedAt = new Date();

    if (winnerId) {
      game.winner = winnerId;
      console.log('   Winner ID:', winnerId);
    }

    await game.save();
    console.log('✅ Jogo salvo com sucesso!');
    console.log('   game.status:', game.status);
    console.log('   game.result:', game.result);
    console.log('   game.winner:', game.winner);

    // Atualizar estatisticas dos jogadores
    if (status === 'xeque_mate' || status === 'checkmate' && winnerId) {
      console.log('📊 Atualizando estatísticas - Xeque-mate');
      await User.findByIdAndUpdate(winnerId, {
    $inc: { 'stats.gamesPlayed': 1, 'stats.gamesWon': 1 }
      });

      const loserId = game.whitePlayer.toString() === winnerId.toString() 
        ? game.blackPlayer 
        : game.whitePlayer;

      await User.findByIdAndUpdate(loserId, {
        $inc: { 'stats.gamesPlayed': 1, 'stats.gamesLost': 1 }
      });
      console.log('✅ Estatísticas de xeque-mate atualizadas');
    } else if (status === 'empate' || status === 'stalemate' || status === 'draw') {
      console.log('📊 Atualizando estatísticas - Empate');
   await User.findByIdAndUpdate(game.whitePlayer, {
        $inc: { 'stats.gamesPlayed': 1, 'stats.gamesDraw': 1 }
  });
      await User.findByIdAndUpdate(game.blackPlayer, {
        $inc: { 'stats.gamesPlayed': 1, 'stats.gamesDraw': 1 }
      });
  console.log('✅ Estatísticas de empate atualizadas');
    }

    console.log('═══════════════════════════════════════════');
    res.json(game);
  } catch (error) {
    console.error('❌ ERRO em endGame:', error);
    res.status(500).json({ message: 'Erro ao encerrar partida' });
  }
};

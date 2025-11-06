import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { getCurrentGame, getUserGames, createGame, getPendingGames, searchUsers, declineGame, acceptGame } from '../services/api';

export default function Lobby() {
  const { user, logout, refreshUser } = useAuth();
  const navigate = useNavigate();
  const [currentGame, setCurrentGame] = useState(null);
  const [directChallenges, setDirectChallenges] = useState([]);
  const [openChallenges, setOpenChallenges] = useState([]);
  const [myChallenges, setMyChallenges] = useState([]);
  const [recentGames, setRecentGames] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Challenge form state
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [selectedOpponent, setSelectedOpponent] = useState(null);
  const [selectedColor, setSelectedColor] = useState('white');
  const [showDropdown, setShowDropdown] = useState(false);
  const [isFreeChallenge, setIsFreeChallenge] = useState(false);
  
  const pollingInterval = useRef(null);
  const searchTimeout = useRef(null);
  const dropdownRef = useRef(null);

  useEffect(() => {
    loadData();
    
    pollingInterval.current = setInterval(() => {
      checkForNewInvites();
 if (refreshUser) {
        refreshUser();
 }
    }, 3000);

const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
     setShowDropdown(false);
}
    };
    document.addEventListener('mousedown', handleClickOutside);

    return () => {
      if (pollingInterval.current) {
   clearInterval(pollingInterval.current);
      }
      if (searchTimeout.current) {
        clearTimeout(searchTimeout.current);
      }
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  const checkForNewInvites = async () => {
 try {
 const response = await getPendingGames();
      const data = response.data;
      
    setDirectChallenges(data.directChallenges || []);
      setOpenChallenges(data.openChallenges || []);
      setMyChallenges(data.myChallenges || []);
      
      // Atualizar currentGame se houver jogo ativo
      if (data.activeGames && data.activeGames.length > 0) {
        setCurrentGame(data.activeGames[0]);
      } else {
    setCurrentGame(null);
      }
    } catch (err) {
 // Silencioso
    }
  };

  const loadData = async () => {
    try {
      setLoading(true);
 
try {
        const gameResponse = await getCurrentGame();
      if (gameResponse.data) {
        setCurrentGame(gameResponse.data);
      }
      } catch (err) {
    // Nenhum jogo em andamento
 }

      if (user) {
 const gamesResponse = await getUserGames(user._id, { limit: 5 });
        setRecentGames(gamesResponse.data.games || []);
}
      
  await checkForNewInvites();
    } catch (err) {
    setError('Erro ao carregar dados');
    } finally {
      setLoading(false);
    }
  };

  const handleSearchChange = (e) => {
    const query = e.target.value;
    setSearchQuery(query);
    setShowDropdown(true);

    if (searchTimeout.current) {
      clearTimeout(searchTimeout.current);
    }

    if (query.trim().length < 2) {
      setSearchResults([]);
      return;
    }

    searchTimeout.current = setTimeout(async () => {
 try {
     const response = await searchUsers(query);
      setSearchResults(response.data);
      } catch (err) {
        console.error('Erro ao buscar usuarios:', err);
 }
  }, 300);
  };

  const handleSelectOpponent = (opponent) => {
    setSelectedOpponent(opponent);
    setSearchQuery(opponent.username);
    setShowDropdown(false);
    setSearchResults([]);
    setIsFreeChallenge(false);
  };

  const handleContinueGame = (gameId) => {
    navigate(`/game/${gameId || currentGame._id}`);
  };

  const handleAcceptChallenge = async (gameId) => {
    try {
      setError('');
      setLoading(true);
    
   const response = await acceptGame(gameId);
      
      navigate(`/game/${response.data._id}`);
    } catch (err) {
      setError(err.response?.data?.message || 'Erro ao aceitar desafio');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateGame = async () => {
    if (!isFreeChallenge && !selectedOpponent) {
      setError('Selecione um oponente ou marque "Desafio Livre"');
      return;
    }

  try {
      setError('');
      setLoading(true);
      
      const response = await createGame(
        isFreeChallenge ? null : selectedOpponent._id, 
        selectedColor
      );
      
      // Se for desafio livre ou direto, voltar para o lobby e aguardar
      await loadData();
      setSelectedOpponent(null);
    setSearchQuery('');
      setIsFreeChallenge(false);
      setError('Desafio criado! Aguardando aceitacao...');
    } catch (err) {
      setError(err.response?.data?.message || 'Erro ao criar partida');
    } finally {
      setLoading(false);
    }
  };

  const handleDeclineGame = async (gameId) => {
try {
      await declineGame(gameId);
      setError('');
      await checkForNewInvites();
      setCurrentGame(null);
    } catch (err) {
 setError(err.response?.data?.message || 'Erro ao recusar partida');
 }
  };

  const handleLogout = () => {
    if (pollingInterval.current) {
  clearInterval(pollingInterval.current);
    }
    logout();
    navigate('/');
  };

  const getGameStatus = (game) => {
    if (game.status === 'em_andamento') {
      return 'Em andamento';
    }
    
    if (game.result) {
      return `Resultado: ${game.result}`;
    }
    
    const statusMap = {
 'xeque_mate': 'Xeque-mate',
      'empate': 'Empate',
      'abandonada': 'Abandonada'
  };
    
    return statusMap[game.status] || game.status;
  };

  if (loading && !currentGame && directChallenges.length === 0 && openChallenges.length === 0) {
    return React.createElement('div', { 
 style: { 
        minHeight: '100vh', 
      display: 'flex', 
        alignItems: 'center', 
      justifyContent: 'center' 
      } 
    }, 'Carregando...');
  }

  const totalPendingChallenges = directChallenges.length + openChallenges.length;

  return React.createElement('div', { 
    style: { 
   minHeight: '100vh', 
      background: '#f5f7fa', 
    padding: '20px' 
    } 
  },
 React.createElement('div', { 
    style: { 
     maxWidth: '1200px', 
margin: '0 auto' 
 } 
    },
      // Header
  React.createElement('div', { 
        style: { 
    background: 'white', 
   padding: '20px', 
  borderRadius: '10px', 
    marginBottom: '20px',
        display: 'flex',
        justifyContent: 'space-between',
   alignItems: 'center'
        } 
    },
    React.createElement('div', null,
  React.createElement('h1', { style: { margin: 0, color: '#667eea' } }, 'Neumann Chess'),
     React.createElement('p', { style: { margin: '5px 0 0 0', color: '#666' } }, 
  'Bem-vindo, ', user?.username || 'Jogador'
          )
      ),
React.createElement('button', { 
    onClick: handleLogout,
          style: {
   padding: '10px 20px',
   background: '#f44336',
    color: 'white',
          border: 'none',
            borderRadius: '6px',
         cursor: 'pointer',
       fontWeight: 'bold'
          }
        }, 'Sair')
      ),

      error && React.createElement('div', { 
  style: { 
      padding: '15px', 
     background: error.includes('criado') ? '#e8f5e9' : '#ffebee', 
   color: error.includes('criado') ? '#2e7d32' : '#c62828',
          borderRadius: '8px',
          marginBottom: '20px'
    } 
      }, error),

      // Direct Challenges - Desafios diretos para mim
      directChallenges.length > 0 && React.createElement('div', { 
    style: { 
   background: '#fff3e0', 
      padding: '20px', 
   borderRadius: '10px', 
 marginBottom: '20px',
  border: '2px solid #ff9800'
 } 
   },
        React.createElement('h2', { style: { marginTop: 0, color: '#ff9800' } }, 
    'Desafios Diretos (', directChallenges.length, ')'
 ),
  React.createElement('div', { style: { display: 'flex', flexDirection: 'column', gap: '10px' } },
  directChallenges.map((game) => {
      const amIWhite = game.whitePlayer && game.whitePlayer._id === user._id;
   const myColor = amIWhite ? 'Brancas' : 'Pretas';
     const challenger = game.createdBy;
      
  return React.createElement('div', {
          key: game._id,
 style: {
   padding: '15px',
  background: 'white',
      borderRadius: '6px',
   display: 'flex',
     justifyContent: 'space-between',
     alignItems: 'center',
    border: '1px solid #e0e0e0'
   }
       },
   React.createElement('div', null,
      React.createElement('strong', null, challenger.username),
    React.createElement('div', { style: { fontSize: '12px', color: '#666', marginTop: '5px' } },
       'Voce joga com: ', myColor
    )
       ),
  React.createElement('div', { style: { display: 'flex', gap: '8px' } },
 React.createElement('button', {
      onClick: () => handleDeclineGame(game._id),
    style: {
  padding: '10px 16px',
    background: '#f44336',
      color: 'white',
   border: 'none',
      borderRadius: '6px',
    cursor: 'pointer',
     fontWeight: 'bold'
        }
           }, 'Recusar'),
     React.createElement('button', {
  onClick: () => handleAcceptChallenge(game._id),
   style: {
    padding: '10px 20px',
      background: '#4caf50',
   color: 'white',
        border: 'none',
 borderRadius: '6px',
     cursor: 'pointer',
      fontWeight: 'bold'
  }
       }, 'Aceitar')
 )
     );
   })
        )
      ),

      // Free Challenges - Desafios livres
      openChallenges.length > 0 && React.createElement('div', { 
        style: { 
     background: '#e3f2fd', 
          padding: '20px', 
          borderRadius: '10px', 
          marginBottom: '20px',
   border: '2px solid #2196f3'
        } 
      },
    React.createElement('h2', { style: { marginTop: 0, color: '#2196f3' } }, 
'Desafios Livres (', openChallenges.length, ')'
        ),
        React.createElement('div', { style: { display: 'flex', flexDirection: 'column', gap: '10px' } },
      openChallenges.map((game) => {
    // Para desafio livre, um dos jogadores é null
      const challengerColor = game.whitePlayer ? 'Brancas' : 'Pretas';
            const myColor = game.whitePlayer ? 'Pretas' : 'Brancas';
            const challenger = game.createdBy;
            
            return React.createElement('div', {
       key: game._id,
         style: {
      padding: '15px',
     background: 'white',
 borderRadius: '6px',
 display: 'flex',
       justifyContent: 'space-between',
     alignItems: 'center',
    border: '1px solid #e0e0e0'
       }
      },
         React.createElement('div', null,
       React.createElement('strong', null, challenger ? challenger.username : 'Desconhecido', ' (', challengerColor, ')'),
                React.createElement('div', { style: { fontSize: '12px', color: '#666', marginTop: '5px' } },
       'Voce jogara com: ', myColor
     )
          ),
   React.createElement('div', { style: { display: 'flex', gap: '8px' } },
                React.createElement('button', {
   onClick: () => handleAcceptChallenge(game._id),
     style: {
 padding: '10px 20px',
     background: '#2196f3',
 color: 'white',
  border: 'none',
         borderRadius: '6px',
      cursor: 'pointer',
    fontWeight: 'bold'
           }
        }, 'Aceitar Desafio')
              )
);
     })
  )
      ),

    // My Challenges - Meus desafios pendentes
    myChallenges.length > 0 && React.createElement('div', { 
     style: { 
  background: '#f3e5f5', 
      padding: '20px', 
 borderRadius: '10px', 
 marginBottom: '20px',
border: '2px solid #9c27b0'
 } 
      },
   React.createElement('h2', { style: { marginTop: 0, color: '#9c27b0' } }, 
    'Meus Desafios Pendentes (', myChallenges.length, ')'
        ),
  React.createElement('div', { style: { display: 'flex', flexDirection: 'column', gap: '10px' } },
  myChallenges.map((game) => {
      const amIWhite = game.whitePlayer && game.whitePlayer._id === user._id;
         const myColor = amIWhite ? 'Brancas' : 'Pretas';
      const isFree = game.isOpenChallenge;
    
  return React.createElement('div', {
     key: game._id,
 style: {
   padding: '15px',
       background: 'white',
  borderRadius: '6px',
        display: 'flex',
   justifyContent: 'space-between',
       alignItems: 'center',
    border: '1px solid #e0e0e0'
   }
       },
   React.createElement('div', null,
      React.createElement('strong', null, isFree ? 'Desafio Livre' : 'Desafio Direto'),
  React.createElement('div', { style: { fontSize: '12px', color: '#666', marginTop: '5px' } },
       'Voce joga com: ', myColor, ' - Aguardando aceitacao'
    )
       ),
  React.createElement('div', { style: { display: 'flex', gap: '8px' } },
 React.createElement('button', {
      onClick: () => handleDeclineGame(game._id),
  style: {
  padding: '10px 16px',
  background: '#f44336',
      color: 'white',
      border: 'none',
      borderRadius: '6px',
    cursor: 'pointer',
     fontWeight: 'bold'
  }
           }, 'Cancelar')
 )
   );
   })
        )
      ),

      // Create New Game
   React.createElement('div', { 
        style: { 
          background: 'white', 
          padding: '25px', 
       borderRadius: '10px', 
      marginBottom: '20px' 
     } 
   },
   React.createElement('h2', { style: { marginTop: 0, color: '#667eea' } }, 'Nova Partida'),
 React.createElement('p', { style: { color: '#666', marginBottom: '15px' } }, 
   'Escolha um oponente especifico ou crie um desafio livre'
        ),

        // Checkbox para desafio livre
   React.createElement('div', { style: { marginBottom: '15px' } },
          React.createElement('label', { 
         style: { 
     display: 'flex', 
      alignItems: 'center',
  gap: '8px',
       cursor: 'pointer'
    }
          },
            React.createElement('input', {
      type: 'checkbox',
checked: isFreeChallenge,
      onChange: (e) => {
   setIsFreeChallenge(e.target.checked);
     if (e.target.checked) {
    setSelectedOpponent(null);
  setSearchQuery('');
    }
            },
       style: { cursor: 'pointer' }
    }),
        React.createElement('span', null, 'Desafio Livre (qualquer um pode aceitar)')
          )
   ),
     
      // User Search - desabilitado se for desafio livre
        !isFreeChallenge && React.createElement('div', { 
   style: { position: 'relative', marginBottom: '15px' },
          ref: dropdownRef
        },
 React.createElement('input', {
   type: 'text',
    value: searchQuery,
    onChange: handleSearchChange,
       onFocus: () => searchResults.length > 0 && setShowDropdown(true),
        placeholder: 'Digite o nome do jogador...',
       style: {
      width: '100%',
       padding: '12px',
         border: '2px solid #e0e0e0',
       borderRadius: '6px',
      fontSize: '14px'
    }
   }),
       
    showDropdown && searchResults.length > 0 && React.createElement('div', {
        style: {
     position: 'absolute',
     top: '100%',
    left: 0,
right: 0,
    background: 'white',
        border: '2px solid #e0e0e0',
   borderTop: 'none',
              borderRadius: '0 0 6px 6px',
      maxHeight: '200px',
  overflowY: 'auto',
     zIndex: 10,
  boxShadow: '0 4px 8px rgba(0,0,0,0.1)'
            }
        },
         searchResults.map((user) =>
 React.createElement('div', {
     key: user._id,
   onClick: () => handleSelectOpponent(user),
         style: {
   padding: '12px',
  cursor: 'pointer',
  borderBottom: '1px solid #f0f0f0',
  transition: 'background 0.2s'
    },
   onMouseEnter: (e) => e.target.style.background = '#f5f5f5',
          onMouseLeave: (e) => e.target.style.background = 'white'
 },
     React.createElement('div', { style: { fontWeight: 'bold' } }, user.username),
                React.createElement('div', { style: { fontSize: '12px', color: '#666' } }, 
         user.stats.gamesPlayed, ' jogos - ',
user.stats.gamesWon, ' vitorias'
    )
     )
   )
    )
     ),

  // Selected opponent display
   !isFreeChallenge && selectedOpponent && React.createElement('div', {
          style: {
padding: '10px',
   background: '#e3f2fd',
       borderRadius: '6px',
marginBottom: '15px',
      display: 'flex',
   justifyContent: 'space-between',
alignItems: 'center'
    }
   },
   React.createElement('span', null, 'Oponente: ', React.createElement('strong', null, selectedOpponent.username)),
          React.createElement('button', {
     onClick: () => {
     setSelectedOpponent(null);
      setSearchQuery('');
    },
    style: {
     background: 'transparent',
      border: 'none',
   color: '#f44336',
  cursor: 'pointer',
   fontSize: '20px',
              fontWeight: 'bold'
 }
          }, '\u00D7')
        ),

    // Color selection
   React.createElement('div', { style: { marginBottom: '15px' } },
          React.createElement('label', { style: { display: 'block', marginBottom: '8px', fontWeight: 'bold' } }, 
            'Escolha sua cor:'
   ),
          React.createElement('div', { style: { display: 'flex', gap: '10px' } },
            React.createElement('button', {
      onClick: () => setSelectedColor('white'),
       style: {
   flex: 1,
  padding: '15px',
   border: selectedColor === 'white' ? '3px solid #667eea' : '2px solid #e0e0e0',
       borderRadius: '8px',
       background: selectedColor === 'white' ? '#e3f2fd' : 'white',
          cursor: 'pointer',
      fontWeight: 'bold',
   fontSize: '16px',
   transition: 'all 0.2s',
  display: 'flex',
  alignItems: 'center',
   justifyContent: 'center',
   gap: '8px'
            }
            }, 
        React.createElement('img', {
  src: 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/wk.png',
       alt: 'Rei Branco',
           style: { width: '32px', height: '32px', objectFit: 'contain' }
           }),
  'Brancas'
     ),
            React.createElement('button', {
     onClick: () => setSelectedColor('black'),
       style: {
           flex: 1,
  padding: '15px',
        border: selectedColor === 'black' ? '3px solid #667eea' : '2px solid #e0e0e0',
 borderRadius: '8px',
 background: selectedColor === 'black' ? '#e3f2fd' : 'white',
          cursor: 'pointer',
         fontWeight: 'bold',
       fontSize: '16px',
   transition: 'all 0.2s',
       display: 'flex',
         alignItems: 'center',
     justifyContent: 'center',
 gap: '8px'
         }
}, 
    React.createElement('img', {
   src: 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/bk.png',
                alt: 'Rei Preto',
 style: { width: '32px', height: '32px', objectFit: 'contain' }
     }),
   'Pretas'
     )
     )
     ),

   React.createElement('button', {
            onClick: handleCreateGame,
       disabled: (!isFreeChallenge && !selectedOpponent) || loading,
          style: {
       width: '100%',
 padding: '14px',
            background: ((!isFreeChallenge && !selectedOpponent) || loading) ? '#ccc' : '#667eea',
    color: 'white',
        border: 'none',
            borderRadius: '6px',
          cursor: ((!isFreeChallenge && !selectedOpponent) || loading) ? 'not-allowed' : 'pointer',
       fontWeight: 'bold',
fontSize: '16px'
    }
        }, loading ? 'Criando...' : (isFreeChallenge ? 'Criar Desafio Livre' : 'Desafiar'))
      ),

      // Stats
      React.createElement('div', { 
        style: { 
          background: 'white', 
 padding: '25px', 
          borderRadius: '10px',
          marginBottom: '20px'
        } 
      },
        React.createElement('h2', { style: { marginTop: 0, color: '#667eea' } }, 'Estatisticas'),
    React.createElement('div', { 
       style: { 
            display: 'grid', 
   gridTemplateColumns: 'repeat(4, 1fr)', 
         gap: '15px',
    marginTop: '15px'
  } 
        },
          React.createElement('div', { style: { textAlign: 'center' } },
            React.createElement('div', { style: { fontSize: '32px', fontWeight: 'bold', color: '#667eea' } }, 
     user?.stats?.gamesPlayed || 0
   ),
   React.createElement('div', { style: { fontSize: '14px', color: '#666' } }, 'Jogadas')
          ),
          React.createElement('div', { style: { textAlign: 'center' } },
       React.createElement('div', { style: { fontSize: '32px', fontWeight: 'bold', color: '#4caf50' } }, 
           user?.stats?.gamesWon || 0
            ),
  React.createElement('div', { style: { fontSize: '14px', color: '#666' } }, 'Vitorias')
          ),
          React.createElement('div', { style: { textAlign: 'center' } },
            React.createElement('div', { style: { fontSize: '32px', fontWeight: 'bold', color: '#f44336' } }, 
   user?.stats?.gamesLost || 0
  ),
  React.createElement('div', { style: { fontSize: '14px', color: '#666' } }, 'Derrotas')
          ),
          React.createElement('div', { style: { textAlign: 'center' } },
            React.createElement('div', { style: { fontSize: '32px', fontWeight: 'bold', color: '#ff9800' } }, 
     user?.stats?.gamesDraw || 0
 ),
 React.createElement('div', { style: { fontSize: '14px', color: '#666' } }, 'Empates')
   )
   )
      ),

      // Recent Games
      recentGames.length > 0 && React.createElement('div', { 
        style: { 
   background: 'white', 
      padding: '25px', 
   borderRadius: '10px' 
    } 
  },
   React.createElement('h2', { style: { marginTop: 0, color: '#667eea' } }, 'Partidas Recentes'),
 React.createElement('div', { style: { display: 'flex', flexDirection: 'column', gap: '10px' } },
      recentGames.map((game) => {
  const isFinished = game.status !== 'em_andamento';
        
    return React.createElement('div', {
key: game._id,
 style: {
      padding: '15px',
     border: '1px solid #e0e0e0',
     borderRadius: '6px',
    display: 'flex',
           justifyContent: 'space-between',
alignItems: 'center',
    cursor: isFinished ? 'pointer' : 'default',
    transition: 'all 0.2s',
   background: 'white'
   },
      onClick: isFinished ? () => navigate(`/game/${game._id}`) : undefined,
        onMouseEnter: (e) => {
       if (isFinished) {
      e.currentTarget.style.background = '#f5f7fa';
     e.currentTarget.style.borderColor = '#667eea';
     }
     },
      onMouseLeave: (e) => {
  if (isFinished) {
 e.currentTarget.style.background = 'white';
  e.currentTarget.style.borderColor = '#e0e0e0';
           }
 }
 },
     React.createElement('div', null,
    React.createElement('strong', null, 
     game.whitePlayer.username, ' vs ', game.blackPlayer.username
     ),
 React.createElement('div', { style: { fontSize: '12px', color: '#666', marginTop: '5px' } },
     getGameStatus(game)
     )
      ),
  game.status === 'em_andamento' ? React.createElement('button', {
   onClick: () => navigate(`/game/${game._id}`),
  style: {
   padding: '8px 16px',
  background: '#667eea',
   color: 'white',
 border: 'none',
   borderRadius: '6px',
     cursor: 'pointer',
      fontWeight: 'bold'
            }
       }, 'Continuar') : React.createElement('button', {
 onClick: (e) => {
 e.stopPropagation();
         navigate(`/viewer/${game._id}`);
   },
  style: {
    padding: '8px 16px',
background: '#4caf50',
  color: 'white',
  border: 'none',
borderRadius: '6px',
     cursor: 'pointer',
         fontWeight: 'bold'
     }
       }, '\uD83D\uDC41 Visualizar')
      );
     })
    )
      )
    )
  );
}

import React, { useState, useEffect, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Chessboard } from "react-chessboard";
import { Chess } from "chess.js";
import { getGame } from "../services/api";

export default function GameViewer() {
	const { gameId } = useParams();
	const navigate = useNavigate();
	
	const [gameData, setGameData] = useState(null);
	const [loading, setLoading] = useState(true);
	const [currentMoveIndex, setCurrentMoveIndex] = useState(-1); // -1 = posição inicial
	const [currentPosition, setCurrentPosition] = useState('start');
	
	useEffect(() => {
		loadGame();
	}, [gameId]);

	const loadGame = async () => {
		try {
			const response = await getGame(gameId);
			const game = response.data;
			
			// Verificar se o jogo está encerrado
			if (game.status === 'em_andamento') {
				// Se está em andamento, redirecionar para a página normal do jogo
				navigate(`/game/${gameId}`);
				return;
			}
			
			setGameData(game);
			setCurrentPosition('start');
			setCurrentMoveIndex(-1);
			setLoading(false);
		} catch (err) {
			console.error('Erro ao carregar partida:', err);
			navigate('/lobby');
		}
	};

	const applyMovesToPosition = (moveIndex) => {
		const chess = new Chess();
		
		if (moveIndex === -1) {
			// Posição inicial
			return chess.fen();
		}
		
		// Aplicar movimentos até o índice especificado
		for (let i = 0; i <= moveIndex && i < gameData.moves.length; i++) {
			const move = gameData.moves[i];
			try {
				chess.move({
					from: move.from,
					to: move.to,
					promotion: move.promotion || 'q'
				});
			} catch (e) {
				console.error('Erro ao aplicar movimento:', e);
			}
		}
		
		return chess.fen();
	};

	const handleFirst = () => {
		setCurrentMoveIndex(-1);
		setCurrentPosition('start');
	};

	const handlePrevious = () => {
		if (currentMoveIndex >= 0) {
			const newIndex = currentMoveIndex - 1;
			setCurrentMoveIndex(newIndex);
			setCurrentPosition(applyMovesToPosition(newIndex));
		}
	};

	const handleNext = () => {
		if (currentMoveIndex < gameData.moves.length - 1) {
			const newIndex = currentMoveIndex + 1;
			setCurrentMoveIndex(newIndex);
			setCurrentPosition(applyMovesToPosition(newIndex));
		}
	};

	const handleLast = () => {
		const lastIndex = gameData.moves.length - 1;
		setCurrentMoveIndex(lastIndex);
		setCurrentPosition(applyMovesToPosition(lastIndex));
	};

	const handleGoToMove = (index) => {
		setCurrentMoveIndex(index);
		setCurrentPosition(applyMovesToPosition(index));
	};

	const getPieceName = (piece, color) => {
		const names = {
			'p': color === 'w' ? 'Peão' : 'Peão',
			'n': color === 'w' ? 'Cavalo' : 'Cavalo',
			'b': color === 'w' ? 'Bispo' : 'Bispo',
			'r': color === 'w' ? 'Torre' : 'Torre',
			'q': color === 'w' ? 'Dama' : 'Dama',
			'k': color === 'w' ? 'Rei' : 'Rei'
		};
		return names[piece] || '';
	};

	const getGameResult = () => {
		if (!gameData) return '';
		
		const statusMap = {
			'xeque_mate': 'Xeque-mate',
			'empate': 'Empate',
			'abandonada': 'Abandonada'
		};
		
		const status = statusMap[gameData.status] || gameData.status;
		const result = gameData.result ? ` (${gameData.result})` : '';
		
		return `${status}${result}`;
	};

	if (loading) {
		return React.createElement('div', {
			style: {
				minHeight: '100vh',
				display: 'flex',
				alignItems: 'center',
				justifyContent: 'center',
				fontSize: '20px'
			}
		}, 'Carregando partida...');
	}

	if (!gameData) {
		return React.createElement('div', {
			style: {
				minHeight: '100vh',
				display: 'flex',
				alignItems: 'center',
				justifyContent: 'center',
				fontSize: '20px'
			}
		}, 'Partida não encontrada');
	}

	return React.createElement('div', { 
		style: { 
			padding: '20px', 
			background: '#f5f7fa', 
			minHeight: '100vh' 
		} 
	},
		React.createElement('div', { 
			style: { 
				maxWidth: '600px', 
				margin: '0 auto' 
			} 
		},
			// Header
			React.createElement('div', {
				style: {
					background: 'white',
					padding: '15px 20px',
					borderRadius: '10px',
					marginBottom: '15px',
					display: 'flex',
					justifyContent: 'space-between',
					alignItems: 'center'
				}
			},
				React.createElement('div', null,
					React.createElement('h1', { 
						style: { 
							margin: 0, 
							color: '#667eea', 
							fontSize: '20px' 
						} 
					},
						'\uD83D\uDC41 Visualizador de Partida'
					),
					React.createElement('p', { 
						style: { 
							margin: '5px 0 0 0', 
							fontSize: '13px', 
							color: '#666' 
						} 
					},
						gameData.whitePlayer.username, ' vs ', gameData.blackPlayer.username
					)
				),
				React.createElement('button', {
					onClick: () => navigate('/lobby'),
					style: {
						padding: '8px 16px',
						background: '#667eea',
						color: 'white',
						border: 'none',
						borderRadius: '6px',
						cursor: 'pointer',
						fontWeight: 'bold',
						fontSize: '13px'
					}
				}, 'Voltar')
			),

			// Game Result - Compacto
			React.createElement('div', {
				style: {
					background: 'white',
					padding: '12px 15px',
					borderRadius: '8px',
					marginBottom: '15px',
					textAlign: 'center',
					border: '2px solid #667eea'
				}
			},
				React.createElement('div', { 
					style: { 
						color: '#667eea', 
						fontSize: '16px',
						fontWeight: 'bold'
					} 
				},
					'\uD83C\uDFC6 ', getGameResult(),
					gameData.winner && React.createElement('span', {
						style: {
							marginLeft: '8px',
							fontSize: '14px',
							fontWeight: 'normal',
							color: '#666'
						}
					},
						' - Vencedor: ', 
						gameData.winner._id === gameData.whitePlayer._id 
							? gameData.whitePlayer.username 
							: gameData.blackPlayer.username
					)
				)
			),

			// Chessboard
			React.createElement('div', {
				style: {
					background: 'white',
					padding: '15px',
					borderRadius: '10px',
					marginBottom: '15px'
				}
			},
				React.createElement(Chessboard, {
					position: currentPosition,
					boardWidth: 560,
					areArrowsAllowed: false,
					isDraggablePiece: () => false
				}),
				
				// Navigation Controls - Apenas símbolos
				React.createElement('div', {
					style: {
						marginTop: '15px',
						display: 'flex',
						gap: '8px',
						justifyContent: 'center',
						alignItems: 'center'
					}
				},
					React.createElement('button', {
						onClick: handleFirst,
						disabled: currentMoveIndex === -1,
						style: {
							padding: '10px 16px',
							background: currentMoveIndex === -1 ? '#ccc' : '#667eea',
							color: 'white',
							border: 'none',
							borderRadius: '6px',
							cursor: currentMoveIndex === -1 ? 'not-allowed' : 'pointer',
							fontWeight: 'bold',
							fontSize: '16px',
							minWidth: '50px'
						}
					}, '<<'),
					
					React.createElement('button', {
						onClick: handlePrevious,
						disabled: currentMoveIndex === -1,
						style: {
							padding: '10px 16px',
							background: currentMoveIndex === -1 ? '#ccc' : '#667eea',
							color: 'white',
							border: 'none',
							borderRadius: '6px',
							cursor: currentMoveIndex === -1 ? 'not-allowed' : 'pointer',
							fontWeight: 'bold',
							fontSize: '16px',
							minWidth: '50px'
						}
					}, '<'),
					
					React.createElement('div', {
						style: {
							padding: '6px 12px',
							background: '#e3f2fd',
							borderRadius: '6px',
							fontWeight: 'bold',
							fontSize: '13px',
							minWidth: '120px',
							textAlign: 'center'
						}
					},
						currentMoveIndex === -1 
							? '0 de ' + gameData.moves.length 
							: (currentMoveIndex + 1) + ' de ' + gameData.moves.length
					),
					
					React.createElement('button', {
						onClick: handleNext,
						disabled: currentMoveIndex >= gameData.moves.length - 1,
						style: {
							padding: '10px 16px',
							background: currentMoveIndex >= gameData.moves.length - 1 ? '#ccc' : '#667eea',
							color: 'white',
							border: 'none',
							borderRadius: '6px',
							cursor: currentMoveIndex >= gameData.moves.length - 1 ? 'not-allowed' : 'pointer',
							fontWeight: 'bold',
							fontSize: '16px',
							minWidth: '50px'
						}
					}, '>'),
					
					React.createElement('button', {
						onClick: handleLast,
						disabled: currentMoveIndex >= gameData.moves.length - 1,
						style: {
							padding: '10px 16px',
							background: currentMoveIndex >= gameData.moves.length - 1 ? '#ccc' : '#667eea',
							color: 'white',
							border: 'none',
							borderRadius: '6px',
							cursor: currentMoveIndex >= gameData.moves.length - 1 ? 'not-allowed' : 'pointer',
							fontWeight: 'bold',
							fontSize: '16px',
							minWidth: '50px'
						}
					}, '>>')
				)
			),
			
			// Move list - Compacta, largura do tabuleiro
			React.createElement('div', {
				style: {
					background: 'white',
					padding: '15px',
					borderRadius: '10px',
					marginBottom: '15px'
				}
			},
				React.createElement('h3', {
					style: {
						margin: '0 0 12px 0',
						color: '#667eea',
						fontSize: '16px'
					}
				}, 'Lista de Lances'),
				
				React.createElement('div', {
					style: {
						maxHeight: '300px',
						overflowY: 'auto',
						border: '1px solid #e0e0e0',
						borderRadius: '6px',
						padding: '10px'
					}
				},
					gameData.moves.length === 0 
						? React.createElement('p', {
							style: {
								textAlign: 'center',
								color: '#999',
								padding: '20px',
								margin: 0,
								fontSize: '13px'
							}
						}, 'Nenhum movimento registrado')
						: React.createElement('div', {
							style: {
								display: 'grid',
								gridTemplateColumns: '50px 1fr 1fr',
								gap: '6px',
								fontSize: '13px'
							}
						},
							// Header
							React.createElement('div', {
								style: {
									fontWeight: 'bold',
									padding: '6px',
									background: '#f5f5f5',
									borderRadius: '4px',
									textAlign: 'center'
								}
							}, '#'),
							React.createElement('div', {
								style: {
									fontWeight: 'bold',
									padding: '6px',
									background: '#f5f5f5',
									borderRadius: '4px'
								}
							}, 'Brancas'),
							React.createElement('div', {
								style: {
									fontWeight: 'bold',
									padding: '6px',
									background: '#f5f5f5',
									borderRadius: '4px'
								}
							}, 'Pretas'),
							
							// Moves
							...gameData.moves.reduce((acc, move, index) => {
								const moveNumber = Math.floor(index / 2) + 1;
								const isWhite = index % 2 === 0;
								
								if (isWhite) {
									// Adicionar número do lance
									acc.push(
										React.createElement('div', {
											key: `num-${index}`,
											style: {
												padding: '6px',
												textAlign: 'center',
												fontWeight: 'bold',
												color: '#666'
											}
										}, moveNumber + '.')
									);
									
									// Lance das brancas
									acc.push(
										React.createElement('div', {
											key: `white-${index}`,
											onClick: () => handleGoToMove(index),
											style: {
												padding: '6px',
												cursor: 'pointer',
												background: currentMoveIndex === index ? '#e3f2fd' : 'transparent',
												borderRadius: '4px',
												border: currentMoveIndex === index ? '2px solid #667eea' : '1px solid #e0e0e0',
												transition: 'all 0.2s',
												fontWeight: currentMoveIndex === index ? 'bold' : 'normal'
											},
											onMouseEnter: (e) => {
												if (currentMoveIndex !== index) {
													e.target.style.background = '#f5f5f5';
												}
											},
											onMouseLeave: (e) => {
												if (currentMoveIndex !== index) {
													e.target.style.background = 'transparent';
												}
											}
										}, move.san || `${move.from}-${move.to}`)
									);
									
									// Placeholder para pretas
									acc.push(
										React.createElement('div', {
											key: `black-placeholder-${index}`,
											style: { padding: '6px' }
										}, '')
									);
								} else {
									// Remover placeholder e adicionar lance das pretas
									acc.pop();
									acc.push(
										React.createElement('div', {
											key: `black-${index}`,
											onClick: () => handleGoToMove(index),
											style: {
												padding: '6px',
												cursor: 'pointer',
												background: currentMoveIndex === index ? '#e3f2fd' : 'transparent',
												borderRadius: '4px',
												border: currentMoveIndex === index ? '2px solid #667eea' : '1px solid #e0e0e0',
												transition: 'all 0.2s',
												fontWeight: currentMoveIndex === index ? 'bold' : 'normal'
											},
											onMouseEnter: (e) => {
												if (currentMoveIndex !== index) {
													e.target.style.background = '#f5f5f5';
												}
											},
											onMouseLeave: (e) => {
												if (currentMoveIndex !== index) {
													e.target.style.background = 'transparent';
												}
											}
										}, move.san || `${move.from}-${move.to}`)
									);
								}
								
								return acc;
							}, [])
						)
				),
				
				// Game info compacta
				React.createElement('div', {
					style: {
						marginTop: '12px',
						padding: '10px',
						background: '#f5f5f5',
						borderRadius: '6px',
						fontSize: '12px'
					}
				},
					React.createElement('div', {
						style: { marginBottom: '5px' }
					},
						React.createElement('strong', null, 'Total: '),
						gameData.moves.length, ' lances'
					),
					React.createElement('div', {
						style: { marginBottom: '5px' }
					},
						React.createElement('strong', null, 'Inicio: '),
						new Date(gameData.startedAt).toLocaleString('pt-BR', { 
							day: '2-digit', 
							month: '2-digit', 
							year: 'numeric',
							hour: '2-digit',
							minute: '2-digit'
						})
					),
					gameData.endedAt && React.createElement('div', null,
						React.createElement('strong', null, 'Termino: '),
						new Date(gameData.endedAt).toLocaleString('pt-BR', {
							day: '2-digit',
							month: '2-digit',
							year: 'numeric',
							hour: '2-digit',
							minute: '2-digit'
						})
					)
				)
			)
		)
	);
}

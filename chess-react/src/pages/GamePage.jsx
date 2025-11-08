import React, { useRef, useState, useEffect, useMemo } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Chessboard } from "react-chessboard";
import { Chess } from "chess.js";
import { useAuth } from "../context/AuthContext";
import { getGame, makeMove, endGame } from "../services/api";

export default function GamePage() {
	const { gameId } = useParams();
	const navigate = useNavigate();
	const { user, refreshUser } = useAuth();
	
	const chessRef = useRef(new Chess());
	const [gameState, setGameState] = useState({
		fen: chessRef.current.fen(),
		status: "Brancas jogam",
	});
	const [notifications, setNotifications] = useState([]);
	const [isGameOver, setIsGameOver] = useState(false);
	const [gameData, setGameData] = useState(null);
	const [loading, setLoading] = useState(true);
	const [myColor, setMyColor] = useState(null);
	const [showOpponentPieces, setShowOpponentPieces] = useState(false);
	const [isMobile, setIsMobile] = useState(window.innerWidth <= 768);
	const pollingInterval = useRef(null);
	// Controle de ID para notificações
	const notificationIdCounter = useRef(0);

	useEffect(() => {
		// Detectar mudanças de tamanho da tela
		const handleResize = () => {
			setIsMobile(window.innerWidth <= 768);
		};

		window.addEventListener('resize', handleResize);
		
		return () => {
			window.removeEventListener('resize', handleResize);
		};
	}, []);

	useEffect(() => {
		loadGame();
		
		// Polling para atualizar o estado do jogo a cada 2 segundos
		pollingInterval.current = setInterval(() => {
			if (!isGameOver) {
				refreshGame();
			}
		}, 2000);

		return () => {
			if (pollingInterval.current) {
				clearInterval(pollingInterval.current);
			}
		};
	}, [gameId, isGameOver]);

	const refreshGame = async () => {
		try {
			const response = await getGame(gameId);
			const game = response.data;
			
			// Atualizar gameData
			setGameData(game);
			
			// Atualizar tabuleiro se o FEN mudou
			if (game.currentFen && game.currentFen !== chessRef.current.fen()) {
				chessRef.current.load(game.currentFen);
				setGameState({
					fen: game.currentFen,
					status: updateStatus()
				});
			}
			
			// Verificar se jogo terminou
			if (game.status !== 'em_andamento' && !isGameOver) {
				setIsGameOver(true);
				if (pollingInterval.current) {
					clearInterval(pollingInterval.current);
				}
				// Atualizar estatísticas do usuário
				if (refreshUser) {
					await refreshUser();
				}
			}
		} catch (err) {
			console.error('Erro ao atualizar jogo:', err);
		}
	};

	const loadGame = async () => {
		try {
			const response = await getGame(gameId);
			const game = response.data;
			setGameData(game);
			
			// Determinar cor do jogador atual
			const playerColor = game.whitePlayer._id === user._id ? 'white' : 'black';
			setMyColor(playerColor);
			
			// Carregar estado do jogo
			if (game.currentFen) {
				chessRef.current.load(game.currentFen);
				setGameState({
					fen: game.currentFen,
					status: updateStatus()
				});
			}
			
			if (game.status !== 'em_andamento') {
				setIsGameOver(true);
			}
			
			setLoading(false);
		} catch (err) {
			console.error('Erro ao carregar jogo:', err);
			navigate('/lobby');
		}
	};

	const playAlertSound = () => {
		const audioContext = new (window.AudioContext || window.webkitAudioContext)();
		const oscillator = audioContext.createOscillator();
		const gainNode = audioContext.createGain();
		
		oscillator.connect(gainNode);
		gainNode.connect(audioContext.destination);
		
		oscillator.frequency.value = 800;
		oscillator.type = 'sine';
		
		gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
		gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
		
		oscillator.start(audioContext.currentTime);
		oscillator.stop(audioContext.currentTime + 0.5);
	};

	const getPieceName = (pieceType, color) => {
		const names = {
			'p': color === 'w' ? 'Peao branco' : 'Peao preto',
			'n': color === 'w' ? 'Cavalo branco' : 'Cavalo preto',
			'b': color === 'w' ? 'Bispo branco' : 'Bispo preto',
			'r': color === 'w' ? 'Torre branca' : 'Torre preta',
			'q': color === 'w' ? 'Dama branca' : 'Dama preta',
			'k': color === 'w' ? 'Rei branco' : 'Rei preto'
		};
		return names[pieceType] || 'Peca';
	};

	const addNotification = (message, type = 'capture') => {
		const id = ++notificationIdCounter.current;
		const newNotification = { id, message, type };
		
		setNotifications(prev => [...prev, newNotification]);
		playAlertSound();
		
		const duration = type === 'checkmate' ? 5000 : 3000;
		setTimeout(() => {
			setNotifications(prev => prev.filter(n => n.id !== id));
		}, duration);
	};

	const updateStatus = () => {
		const game = chessRef.current;
		let newStatus;
		if (game.isCheckmate()) {
			newStatus = "Xeque-mate! " + (game.turn() === "w" ? "Pretas" : "Brancas") + " venceram!";
		} else if (game.isDraw()) {
			newStatus = "Empate!";
		} else if (game.isCheck()) {
			newStatus = (game.turn() === "w" ? "Brancas" : "Pretas") + " jogam - Xeque!";
		} else {
			newStatus = (game.turn() === "w" ? "Brancas" : "Pretas") + " jogam";
		}
		return newStatus;
	};

	const handleDrop = async (sourceSquare, targetSquare) => {
		const game = chessRef.current;
		
		if (isGameOver) {
			return false;
		}
		
		// Verificar se e a vez do jogador
		const isWhite = gameData.whitePlayer._id === user._id;
		const isBlack = gameData.blackPlayer._id === user._id;
		const currentTurn = game.turn();
		
		if ((currentTurn === 'w' && !isWhite) || (currentTurn === 'b' && !isBlack)) {
			addNotification('Nao e sua vez!', 'check');
			return false;
		}
		
		try {
			const move = game.move({
				from: sourceSquare,
				to: targetSquare,
				promotion: "q",
			});

			if (move === null) {
				return false;
			}

			// Salvar movimento no backend
			try {
				await makeMove(gameId, {
					from: move.from,
					to: move.to,
					piece: move.piece,
					captured: move.captured,
					promotion: move.promotion,
					san: move.san,
					fen: game.fen()
				});
				
				// Recarregar dados do jogo imediatamente apos movimento bem-sucedido
				await refreshGame();
			} catch (err) {
				console.error('Erro ao salvar movimento:', err);
				// Reverter movimento se falhar
				game.undo();
				return false;
			}

			// Notificar promocao PRIMEIRO (se houver)
			if (move.promotion) {
				const promotionNames = {
					'q': 'Dama',
					'r': 'Torre',
					'b': 'Bispo',
					'n': 'Cavalo'
				};
				const promotedTo = promotionNames[move.promotion] || 'Dama';
				addNotification('Peao promovido a ' + promotedTo + '!', 'promotion');
			}

			// Verificar captura
			if (move.captured) {
				const capturedPieceName = getPieceName(move.captured, move.color === 'w' ? 'b' : 'w');
				addNotification(capturedPieceName + " desaparece!", 'capture');
			}

			// Depois verificar xeque-mate ou xeque
			if (game.isCheckmate()) {
				const winner = game.turn() === 'w' ? 'Pretas' : 'Brancas';
				const winnerId = game.turn() === 'w' ? gameData.blackPlayer._id : gameData.whitePlayer._id;
				addNotification("XEQUE-MATE! " + winner + " venceram!", 'checkmate');
				setIsGameOver(true);
				
				// Parar polling
				if (pollingInterval.current) {
					clearInterval(pollingInterval.current);
				}
				
				// Finalizar jogo no backend
				try {
					await endGame(gameId, {
						status: 'xeque_mate',
						result: game.turn() === 'w' ? '0-1' : '1-0',
						winnerId: winnerId
					});
					
					// Atualizar estatisticas do usuario
					if (refreshUser) {
						await refreshUser();
					}
				} catch (err) {
					console.error('Erro ao finalizar jogo:', err);
				}
			} else if (game.isDraw()) {
				// Detectar empate automaticamente
				addNotification("EMPATE! O jogo terminou empatado.", 'draw');
				setIsGameOver(true);
				
				// Parar polling
				if (pollingInterval.current) {
					clearInterval(pollingInterval.current);
				}
				
				// Finalizar jogo no backend
				try {
					await endGame(gameId, {
						status: 'empate',
						result: '1/2-1/2'
					});
					
					// Atualizar estatisticas do usuario
					if (refreshUser) {
						await refreshUser();
					}
				} catch (err) {
					console.error('Erro ao finalizar jogo:', err);
				}
			} else if (game.isStalemate()) {
				// Afogamento (stalemate) tambem e empate
				addNotification("EMPATE POR AFOGAMENTO!", 'draw');
				setIsGameOver(true);
				
				// Parar polling
				if (pollingInterval.current) {
					clearInterval(pollingInterval.current);
				}
				
				// Finalizar jogo no backend
				try {
					await endGame(gameId, {
						status: 'empate',
						result: '1/2-1/2'
					});
					
					// Atualizar estatisticas do usuario
					if (refreshUser) {
						await refreshUser();
					}
				} catch (err) {
					console.error('Erro ao finalizar jogo:', err);
				}
			} else if (game.isInsufficientMaterial()) {
				// Material insuficiente para dar xeque-mate
				addNotification("EMPATE POR MATERIAL INSUFICIENTE!", 'draw');
				setIsGameOver(true);
				
				// Parar polling
				if (pollingInterval.current) {
					clearInterval(pollingInterval.current);
				}
				
				// Finalizar jogo no backend
				try {
					await endGame(gameId, {
						status: 'empate',
						result: '1/2-1/2'
					});
					
					// Atualizar estatisticas do usuario
					if (refreshUser) {
						await refreshUser();
					}
				} catch (err) {
					console.error('Erro ao finalizar jogo:', err);
				}
			} else if (game.isThreefoldRepetition()) {
				// Tripla repeticao
				addNotification("EMPATE POR TRIPLA REPETICAO!", 'draw');
				setIsGameOver(true);
				
				// Parar polling
				if (pollingInterval.current) {
					clearInterval(pollingInterval.current);
				}
				
				// Finalizar jogo no backend
				try {
					await endGame(gameId, {
						status: 'empate',
						result: '1/2-1/2'
					});
					
					// Atualizar estatisticas do usuario
					if (refreshUser) {
						await refreshUser();
					}
				} catch (err) {
					console.error('Erro ao finalizar jogo:', err);
				}
			} else if (game.isCheck()) {
				const kingInCheck = game.turn() === 'w' ? 'Rei branco' : 'Rei preto';
				addNotification(kingInCheck + " em xeque!", 'check');
			}
			
			setGameState({
				fen: game.fen(),
				status: updateStatus(),
			});

			return true;
		} catch (error) {
			return false;
		}
	};

	const handleBackToLobby = () => {
		if (pollingInterval.current) {
			clearInterval(pollingInterval.current);
		}
		navigate('/lobby');
	};

	const getAllPieces = () => {
		const game = chessRef.current;
		const board = game.board();
		const whitePieces = [];
		const blackPieces = [];

		for (let row = 0; row < 8; row++) {
			for (let col = 0; col < 8; col++) {
				const piece = board[row][col];
				if (piece) {
					if (piece.color === 'w') {
						whitePieces.push({ type: piece.type, color: piece.color });
					} else {
						blackPieces.push({ type: piece.type, color: piece.color });
					}
				}
			}
		}

		const order = { k: 0, q: 1, r: 2, b: 3, n: 4, p: 5 };
		whitePieces.sort((a, b) => order[a.type] - order[b.type]);
		blackPieces.sort((a, b) => order[a.type] - order[b.type]);

		return { whitePieces, blackPieces };
	};

	// Memoizar peças do oponente - dados
	const opponentPiecesData = useMemo(() => {
		if (isGameOver || !myColor) return [];
		
		const game = chessRef.current;
		const board = game.board();
		const opponentColor = myColor === 'white' ? 'b' : 'w';
		const pieces = [];

		for (let row = 0; row < 8; row++) {
			for (let col = 0; col < 8; col++) {
				const piece = board[row][col];
				if (piece && piece.color === opponentColor) {
					pieces.push({
						type: piece.type,
						color: piece.color
					});
				}
			}
		}

		const order = { k: 0, q: 1, r: 2, b: 3, n: 4, p: 5 };
		pieces.sort((a, b) => order[a.type] - order[b.type]);

		return pieces;
	}, [gameState.fen, myColor, isGameOver]);

	// Calcular se é minha vez baseado no estado atual do tabuleiro e gameData
	const isMyTurn = useMemo(() => {
		if (!gameData || !myColor) return false;
		
		const currentTurn = chessRef.current.turn();
		const amIWhite = myColor === 'white';
		
		return (currentTurn === 'w' && amIWhite) || (currentTurn === 'b' && !amIWhite);
	}, [gameState.fen, myColor, gameData]);

	const customPieces = () => {
		const pieces = {};
		const pieceTypes = ['wP', 'wN', 'wB', 'wR', 'wQ', 'wK', 'bP', 'bN', 'bB', 'bR', 'bQ', 'bK'];
		
		// Ocultar pecas do oponente baseado na cor do jogador
		const myColorLetter = myColor === 'white' ? 'w' : 'b';
		
		pieceTypes.forEach(pieceType => {
			const pieceColor = pieceType[0]; // 'w' ou 'b'
			
			// Ocultar se nao for minha cor e o jogo nao acabou
			const shouldHide = !isGameOver && pieceColor !== myColorLetter;
			
			if (shouldHide) {
				pieces[pieceType] = () => React.createElement('div', { style: { width: '100%', height: '100%' } });
			}
		});
		
		return pieces;
	};

	// Orientacao do tabuleiro baseada na cor do jogador, nao no turno
	const boardOrientation = myColor || 'white';

	const PieceIcon = React.memo(({ type, color }) => {
		const pieceKey = (color === 'w' ? 'w' : 'b') + type.toUpperCase();
		const pieceImages = {
			'wK': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/wk.png',
			'wQ': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/wq.png',
			'wR': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/wr.png',
			'wB': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/wb.png',
			'wN': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/wn.png',
			'wP': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/wp.png',
			'bK': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/bk.png',
			'bQ': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/bq.png',
			'bR': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/br.png',
			'bB': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/bb.png',
			'bN': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/bn.png',
			'bP': 'https://images.chesscomfiles.com/chess-themes/pieces/neo/150/bp.png',
		};

		return React.createElement('img', {
			src: pieceImages[pieceKey],
			alt: pieceKey,
			style: { width: '100%', height: '100%', objectFit: 'contain' }
		});
	});

	const allPieces = isGameOver ? getAllPieces() : null;

	// Memoizar a RENDERIZAÇÃO completa das peças do oponente
	const opponentPiecesDisplay = useMemo(() => {
		if (opponentPiecesData.length === 0) {
			return React.createElement('div', { 
				style: { 
					fontSize: "12px", 
					color: "#999", 
					width: "100%", 
					textAlign: "center", 
					padding: "20px 0" 
				}
			}, "Nenhuma peca do adversario no tabuleiro");
		}

		// Criar chave única baseada nos tipos de peças
		const piecesKey = opponentPiecesData.map(p => `${p.type}${p.color}`).join('-');
		
		return opponentPiecesData.map((piece, index) =>
			React.createElement('div', {
				key: `${piecesKey}-${index}`, // Key estável baseada no conteúdo
				style: {
					width: "45px",
					height: "45px",
					display: "flex",
					alignItems: "center",
					justifyContent: "center",
					backgroundColor: "white",
					borderRadius: "4px",
					border: "1px solid #ddd",
					boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
					padding: "4px"
				}
			},
				React.createElement(PieceIcon, { type: piece.type, color: piece.color })
			)
		);
	}, [opponentPiecesData]); // Só recalcula quando dados mudam

	const getNotificationStyle = (type) => {
		const baseStyle = {
			marginBottom: 8,
			padding: 10,
			borderRadius: 6,
			fontSize: 13,
			fontWeight: "bold",
			textAlign: "center",
			animation: "slideIn 0.3s ease-out",
			boxShadow: "0 4px 8px rgba(0,0,0,0.2)"
		};

		if (type === 'checkmate') {
			return {
				...baseStyle,
				backgroundColor: "#d32f2f",
				color: "white",
				border: "3px solid #b71c1c",
				fontSize: 14
			};
		} else if (type === 'draw') {
			return {
				...baseStyle,
				backgroundColor: "#ff9800",
				color: "white",
				border: "3px solid #f57c00",
				fontSize: 14
			};
		} else if (type === 'promotion') {
			return {
				...baseStyle,
				backgroundColor: "#e8f5e9",
				color: "#2e7d32",
				border: "2px solid #4caf50"
			};
		} else if (type === 'check') {
			return {
				...baseStyle,
				backgroundColor: "#fff3e0",
				border: "2px solid #ff9800"
			};
		} else {
			return {
				...baseStyle,
				backgroundColor: "#ffebee",
				border: "2px solid #f44336"
			};
		}
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
		}, 'Partida nao encontrada');
	}

	const myColorName = myColor === 'white' ? 'Brancas' : 'Pretas';
	const opponent = gameData.whitePlayer._id === user._id ? gameData.blackPlayer : gameData.whitePlayer;

	// Calcular largura do tabuleiro baseado no dispositivo
	const boardWidth = isMobile ? Math.min(window.innerWidth - 40, 400) : 560;

	return React.createElement('div', { 
		style: { 
			padding: isMobile ? '10px' : '20px', 
			background: '#f5f7fa', 
			minHeight: '100vh' 
		} 
	},
		React.createElement('div', { 
			style: { 
				maxWidth: isMobile ? '100%' : '1000px', 
				margin: '0 auto' 
			} 
		},
			// Header
			React.createElement('div', {
				style: {
					background: 'white',
					padding: isMobile ? '10px 15px' : '15px 20px',
					borderRadius: '10px',
					marginBottom: '15px',
					display: 'flex',
					flexDirection: isMobile ? 'column' : 'row',
					justifyContent: 'space-between',
					alignItems: isMobile ? 'stretch' : 'center',
					gap: isMobile ? '10px' : '0'
				}
			},
				React.createElement('div', null,
					React.createElement('h1', { 
						style: { 
							margin: 0, 
							color: '#667eea', 
							fontSize: isMobile ? '18px' : '24px' 
						} 
					},
						gameData.whitePlayer.username, ' vs ', gameData.blackPlayer.username
					),
					React.createElement('p', { 
						style: { 
							margin: '5px 0 0 0', 
							fontSize: isMobile ? '12px' : '14px', 
							color: '#666' 
						} 
					},
						'Voce joga com: ', React.createElement('strong', null, myColorName)
					)
				),
				React.createElement('button', {
					onClick: handleBackToLobby,
					style: {
						padding: isMobile ? '8px 16px' : '10px 20px',
						background: '#667eea',
						color: 'white',
						border: 'none',
						borderRadius: '6px',
						cursor: 'pointer',
						fontWeight: 'bold',
						fontSize: isMobile ? '14px' : '16px'
					}
				}, 'Voltar ao Lobby')
			),

			// Indicador compacto de turno
			!isGameOver && React.createElement('div', {
				style: {
					background: isMyTurn ? 'linear-gradient(135deg, #4caf50 0%, #45a049 100%)' : 'linear-gradient(135deg, #ff9800 0%, #f57c00 100%)',
					padding: isMobile ? '10px 15px' : '12px 20px',
					borderRadius: '8px',
					marginBottom: '15px',
					textAlign: 'center',
					boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
					border: isMyTurn ? '2px solid #4caf50' : '2px solid #ff9800',
					animation: isMyTurn ? 'pulse 2s infinite' : 'none',
					display: 'flex',
					flexDirection: isMobile ? 'column' : 'row',
					alignItems: 'center',
					justifyContent: 'center',
					gap: isMobile ? '5px' : '12px'
				}
			},
				React.createElement('h2', { 
					style: { 
						margin: 0, 
						color: 'white', 
						fontSize: isMobile ? '16px' : '20px',
						fontWeight: 'bold',
						textShadow: '1px 1px 2px rgba(0,0,0,0.2)'
					} 
				},
					isMyTurn ? '>> SUA VEZ!' : 'VEZ DO OPONENTE'
				),
				React.createElement('span', { 
					style: { 
						color: 'white', 
						fontSize: isMobile ? '12px' : '14px',
						opacity: 0.9
					} 
				},
					isMyTurn ? 'Faca seu movimento' : `Aguardando ${opponent.username}...`
				)
			),

			// Layout responsivo: coluna em mobile, linha em desktop
			React.createElement('div', { 
				style: { 
					display: "flex", 
					flexDirection: isMobile ? 'column' : 'row',
					gap: isMobile ? 15 : 24,
					alignItems: isMobile ? 'center' : 'flex-start'
				} 
			},
				// Tabuleiro
				React.createElement('div', { 
					style: { 
						width: isMobile ? '100%' : 'auto',
						display: 'flex',
						justifyContent: 'center'
					}
				},
					React.createElement(Chessboard, {
						position: gameState.fen,
						onPieceDrop: handleDrop,
						boardOrientation: boardOrientation,
						customPieces: customPieces(),
						areArrowsAllowed: true,
						boardWidth: boardWidth,
						isDraggablePiece: () => !isGameOver
					})
				),

				// Painel lateral (desktop) ou abaixo (mobile)
				React.createElement('div', { 
					style: { 
						minWidth: isMobile ? '100%' : 280,
						width: isMobile ? '100%' : 'auto',
						background: 'white', 
						padding: isMobile ? '15px' : '20px', 
						borderRadius: '10px' 
					} 
				},
					React.createElement('div', { style: { marginBottom: 16 } },
						React.createElement('strong', null, "Status: "),
						gameState.status
					),

					!isGameOver && React.createElement('div', { style: { marginBottom: 16 } },
						React.createElement('strong', null, "Turno: "),
						chessRef.current.turn() === 'w' ? 'Brancas' : 'Pretas'
					),

					!isGameOver && React.createElement('div', {
						style: { 
							marginBottom: 16, 
							padding: 8, 
							backgroundColor: "#e3f2fd", 
							border: "1px solid #2196f3",
							borderRadius: 4,
							fontSize: "12px"
						}
					},
						React.createElement('strong', null, "Xadrez as Cegas: "),
						"Voce so pode ver suas proprias pecas. As pecas do adversario estao ocultas mas ainda no tabuleiro!"
					),

					// Renderizar multiplas notificacoes
					notifications.length > 0 && React.createElement('div', {
						style: { marginBottom: 16 }
					},
						notifications.map((notification) =>
							React.createElement('div', {
								key: notification.id,
								style: getNotificationStyle(notification.type)
							},
								React.createElement('div', { style: { fontSize: "20px", marginBottom: 4 } },
									notification.type === 'checkmate' ? '\u2620' : 
									notification.type === 'draw' ? '\u267B' :
									notification.type === 'promotion' ? '\u2B06' :
									notification.type === 'capture' ? '\u2620' : '\u26A0'
								),
								notification.message
							)
						)
					),

					// Seção de peças do adversário
					React.createElement('div', { style: { marginTop: 16 } },
						isGameOver 
							? React.createElement('div', null,
								React.createElement('strong', { style: { fontSize: "14px", marginBottom: 8, display: "block" } },
									"Pecas Finais no Tabuleiro:"
								),
								React.createElement('div', { style: { marginBottom: 12 } },
									React.createElement('div', { style: { fontSize: "12px", fontWeight: "bold", marginBottom: 4 } }, "Brancas:"),
									React.createElement('div', {
										style: { 
											padding: 8, 
											backgroundColor: "#f5f5f5", 
											borderRadius: 4,
											display: "flex",
											flexWrap: "wrap",
											gap: 6,
											minHeight: 50
										}
									},
										allPieces.whitePieces.map((piece, index) =>
											React.createElement('div', {
												key: 'w' + index,
												style: {
													width: "40px",
													height: "40px",
													display: "flex",
													alignItems: "center",
													justifyContent: "center",
													backgroundColor: "white",
													borderRadius: "4px",
													border: "1px solid #ddd",
													boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
													padding: "3px"
												}
											},
												React.createElement(PieceIcon, { type: piece.type, color: piece.color })
											)
										)
									)
								),
								React.createElement('div', null,
									React.createElement('div', { style: { fontSize: "12px", fontWeight: "bold", marginBottom: 4 } }, "Pretas:"),
									React.createElement('div', {
										style: { 
											padding: 8, 
											backgroundColor: "#f5f5f5", 
											borderRadius: 4,
											display: "flex",
											flexWrap: "wrap",
											gap: 6,
											minHeight: 50
										}
									},
										allPieces.blackPieces.map((piece, index) =>
											React.createElement('div', {
												key: 'b' + index,
												style: {
													width: "40px",
													height: "40px",
													display: "flex",
													alignItems: "center",
													justifyContent: "center",
													backgroundColor: "white",
													borderRadius: "4px",
													border: "1px solid #ddd",
													boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
													padding: "3px"
												}
											},
												React.createElement(PieceIcon, { type: piece.type, color: piece.color })
											)
										)
									)
								)
							)
							: React.createElement('div', null,
								// Cabeçalho com botão de toggle (apenas mobile)
								React.createElement('div', {
									style: {
										display: 'flex',
										justifyContent: 'space-between',
										alignItems: 'center',
										marginBottom: 8
									}
								},
									React.createElement('strong', { style: { fontSize: "14px" } },
										"Pecas de ", opponent.username, ":"
									),
									isMobile && React.createElement('button', {
										onClick: () => setShowOpponentPieces(!showOpponentPieces),
										style: {
											padding: '5px 10px',
											background: showOpponentPieces ? '#f44336' : '#4caf50',
											color: 'white',
											border: 'none',
											borderRadius: '4px',
											cursor: 'pointer',
											fontSize: '12px',
											fontWeight: 'bold'
										}
									}, showOpponentPieces ? 'Ocultar' : 'Mostrar')
								),
								
								// Lista de peças (sempre visível em desktop, toggle em mobile)
								(!isMobile || showOpponentPieces) && React.createElement('div', {
									style: { 
										padding: 12, 
										backgroundColor: "#f5f5f5", 
										borderRadius: 4,
										minHeight: 80,
										display: "flex",
										flexWrap: "wrap",
										gap: 8,
										alignItems: "flex-start",
										alignContent: "flex-start"
									}
								},
									opponentPiecesDisplay
								)
							)
					)
				)
			)
		)
	);
}

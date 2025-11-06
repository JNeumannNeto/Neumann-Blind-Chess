import React, { useRef, useState, useEffect } from "react";
import { Chessboard } from "react-chessboard";
import { Chess } from "chess.js";

export default function ChessApp() {
	const chessRef = useRef(new Chess());
	const [gameState, setGameState] = useState({
		fen: chessRef.current.fen(),
		status: "Brancas jogam",
	});
	const [notification, setNotification] = useState(null);
	const [isGameOver, setIsGameOver] = useState(false);

	const playAlertSound = () => {
		// Create a simple beep sound using Web Audio API
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

	const showNotification = (message, type = 'capture') => {
		setNotification({ message, type });
		playAlertSound();
		
		// Hide notification after 3 seconds (or 5 seconds for checkmate)
		const duration = type === 'checkmate' ? 5000 : 3000;
		setTimeout(() => {
			setNotification(null);
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

	const handleDrop = (sourceSquare, targetSquare) => {
		const game = chessRef.current;
		
		// Don't allow moves after game is over
		if (isGameOver) {
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

			// Check for capture first
			if (move.captured) {
				const capturedPieceName = getPieceName(move.captured, move.color === 'w' ? 'b' : 'w');
				showNotification(capturedPieceName + " desaparece!", 'capture');
			}

			// Check game state AFTER move - priority: checkmate > check
			if (game.isCheckmate()) {
				const winner = game.turn() === 'w' ? 'Pretas' : 'Brancas';
				showNotification("XEQUE-MATE! " + winner + " venceram!", 'checkmate');
				setIsGameOver(true); // Game is over, reveal all pieces
			} else if (game.isCheck()) {
				const kingInCheck = game.turn() === 'w' ? 'Rei branco' : 'Rei preto';
				showNotification(kingInCheck + " em xeque!", 'check');
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

	const resetGame = () => {
		chessRef.current = new Chess();
		setGameState({
			fen: chessRef.current.fen(),
			status: "Brancas jogam",
		});
		setNotification(null);
		setIsGameOver(false); // Reset game over state
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

	const getOpponentPieces = () => {
		const game = chessRef.current;
		const board = game.board();
		const currentTurn = game.turn();
		const opponentColor = currentTurn === 'w' ? 'b' : 'w';
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
	};

	const customPieces = () => {
		const pieces = {};
		const pieceTypes = ['wP', 'wN', 'wB', 'wR', 'wQ', 'wK', 'bP', 'bN', 'bB', 'bR', 'bQ', 'bK'];
		const currentTurn = chessRef.current.turn();
		
		pieceTypes.forEach(pieceType => {
			const isWhitePiece = pieceType.startsWith('w');
			const isBlackPiece = pieceType.startsWith('b');
			
			// If game is over, show all pieces. Otherwise hide opponent pieces
			const shouldHide = !isGameOver && (
				(currentTurn === 'w' && isBlackPiece) || 
				(currentTurn === 'b' && isWhitePiece)
			);
			
			if (shouldHide) {
				pieces[pieceType] = () => React.createElement('div', { style: { width: '100%', height: '100%' } });
			}
		});
		
		return pieces;
	};

	const boardOrientation = chessRef.current.turn() === 'w' ? 'white' : 'black';

	const PieceIcon = ({ type, color }) => {
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
	};

	const allPieces = isGameOver ? getAllPieces() : null;
	const opponentPieces = !isGameOver ? getOpponentPieces() : null;

	// Get notification background color based on type
	const getNotificationStyle = (type) => {
		const baseStyle = {
			marginBottom: 16,
			padding: 12,
			borderRadius: 6,
			fontSize: 14,
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
				fontSize: 16
			};
		} else if (type === 'check') {
			return {
				...baseStyle,
				backgroundColor: "#fff3e0",
				border: "2px solid #ff9800"
			};
		} else { // capture
			return {
				...baseStyle,
				backgroundColor: "#ffebee",
				border: "2px solid #f44336"
			};
		}
	};

	return React.createElement('div', null,
		React.createElement('div', { style: { display: "flex", gap: 24 } },
			React.createElement('div', null,
				React.createElement(Chessboard, {
					position: gameState.fen,
					onPieceDrop: handleDrop,
					boardOrientation: boardOrientation,
					customPieces: customPieces(),
					areArrowsAllowed: true,
					boardWidth: 560,
					isDraggablePiece: () => !isGameOver // Disable dragging if game is over
				})
			),
			React.createElement('div', { style: { minWidth: 280 } },
				React.createElement('div', { style: { marginBottom: 16 } },
					React.createElement('strong', null, "Status: "),
					gameState.status
				),
				
				React.createElement('div', { className: "controls", style: { marginBottom: 16 } },
					React.createElement('button', { onClick: resetGame }, "Reiniciar Jogo")
				),

				!isGameOver && React.createElement('div', { style: { marginBottom: 16 } },
					React.createElement('strong', null, "Jogador Atual: "),
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

				// Notification banner
				notification && React.createElement('div', {
					style: getNotificationStyle(notification.type)
				},
					React.createElement('div', { style: { fontSize: "24px", marginBottom: 4 } },
						notification.type === 'checkmate' ? "????" : 
						notification.type === 'capture' ? "??" : "??"
					),
					notification.message
				),

				// Show opponent pieces during game, or all pieces after checkmate
				React.createElement('div', { style: { marginTop: 16 } },
					isGameOver 
						? React.createElement('div', null,
							React.createElement('strong', { style: { fontSize: "14px", marginBottom: 8, display: "block" } },
								"Pecas Finais no Tabuleiro:"
							),
							// White pieces
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
							// Black pieces
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
							React.createElement('strong', { style: { fontSize: "14px", marginBottom: 8, display: "block" } },
								"Pecas do Adversario no Tabuleiro:"
							),
							React.createElement('div', {
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
								opponentPieces.length > 0 
									? opponentPieces.map((piece, index) =>
										React.createElement('div', {
											key: index,
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
									)
									: React.createElement('div', { 
										style: { 
											fontSize: "12px", 
											color: "#999", 
											width: "100%", 
											textAlign: "center", 
											padding: "20px 0" 
										}
									}, "Nenhuma peca do adversario no tabuleiro")
							)
						)
				)
			)
		)
	);
}
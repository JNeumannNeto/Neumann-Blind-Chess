import axios from 'axios';

const API_URL = 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Adicionar token a cada requisicao
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
   config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Auth
export const register = (userData) => api.post('/auth/register', userData);
export const login = (credentials) => api.post('/auth/login', credentials);
export const getMe = () => api.get('/auth/me');
export const searchUsers = (query) => api.get('/auth/search', { params: { query } });
export const getAllUsers = (limit) => api.get('/auth/users', { params: { limit } });

// Games
export const createGame = (opponentId, myColor) => api.post('/games', { opponentId, myColor });
export const acceptGame = (gameId) => api.post(`/games/${gameId}/accept`);
export const getCurrentGame = () => api.get('/games/current');
export const getPendingGames = () => api.get('/games/pending');
export const getGame = (gameId) => api.get(`/games/${gameId}`);
export const getUserGames = (userId, params) => api.get(`/games/user/${userId}`, { params });
export const makeMove = (gameId, moveData) => api.post(`/games/${gameId}/move`, moveData);
export const endGame = (gameId, endData) => api.put(`/games/${gameId}/end`, endData);
export const declineGame = (gameId) => api.delete(`/games/${gameId}`);

export default api;

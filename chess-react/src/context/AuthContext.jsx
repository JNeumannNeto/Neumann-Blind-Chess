import React, { createContext, useState, useContext, useEffect } from 'react';
import { login as apiLogin, register as apiRegister, getMe } from '../services/api';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth deve ser usado dentro de AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    const token = localStorage.getItem('token');
    if (token) {
      try {
        const response = await getMe();
        setUser(response.data);
      } catch (err) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
      }
    }
    setLoading(false);
  };

  const refreshUser = async () => {
    const token = localStorage.getItem('token');
    if (token) {
      try {
        const response = await getMe();
        setUser(response.data);
      } catch (error) {
        console.error('Erro ao atualizar usuario:', error);
      }
    }
  };

  const login = async (email, password) => {
    try {
      setError(null);
      const response = await apiLogin({ email, password });
      const { token, ...userData } = response.data;
      
      localStorage.setItem('token', token);
  localStorage.setItem('user', JSON.stringify(userData));
      setUser(userData);
      
      return { success: true };
} catch (err) {
      const message = err.response?.data?.message || 'Erro ao fazer login';
      setError(message);
      return { success: false, error: message };
    }
  };

  const register = async (username, email, password) => {
    try {
      setError(null);
    const response = await apiRegister({ username, email, password });
      const { token, ...userData } = response.data;
      
      localStorage.setItem('token', token);
  localStorage.setItem('user', JSON.stringify(userData));
      setUser(userData);
      
    return { success: true };
    } catch (err) {
      const message = err.response?.data?.message || 'Erro ao registrar';
      setError(message);
      return { success: false, error: message };
    }
  };

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
  };

  const value = {
    user,
    loading,
    error,
    login,
    register,
    logout,
    refreshUser,
    isAuthenticated: !!user,
  };

  return React.createElement(AuthContext.Provider, { value }, children);
};

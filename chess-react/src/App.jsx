import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext";
import Login from "./pages/Login";
import Lobby from "./pages/Lobby";
import GamePage from "./pages/GamePage";
import GameViewer from "./pages/GameViewer";
import ChessApp from "./components/ChessApp";

// Componente para proteger rotas
const PrivateRoute = ({ children }) => {
    const { isAuthenticated, loading } = useAuth();
    
    if (loading) {
    return React.createElement('div', {
    style: {
         minHeight: '100vh',
    display: 'flex',
       alignItems: 'center',
                justifyContent: 'center',
      fontSize: '20px'
 }
      }, 'Carregando...');
    }
 
    return isAuthenticated ? children : React.createElement(Navigate, { to: '/' });
};

function AppRoutes() {
    return React.createElement(BrowserRouter, null,
     React.createElement(AuthProvider, null,
       React.createElement(Routes, null,
         React.createElement(Route, { 
      path: "/", 
  element: React.createElement(Login) 
     }),
    React.createElement(Route, { 
    path: "/lobby", 
            element: React.createElement(PrivateRoute, null,
     React.createElement(Lobby)
      )
        }),
     React.createElement(Route, { 
    path: "/game/:gameId", 
          element: React.createElement(PrivateRoute, null,
      React.createElement(GamePage)
)
     }),
React.createElement(Route, { 
    path: "/viewer/:gameId", 
  element: React.createElement(PrivateRoute, null,
        React.createElement(GameViewer)
        )
    }),
      React.createElement(Route, { 
               path: "/chess", 
    element: React.createElement(ChessApp) 
       })
       )
        )
    );
}

export default AppRoutes;
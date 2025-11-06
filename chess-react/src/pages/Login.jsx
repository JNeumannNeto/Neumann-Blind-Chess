import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const { login, register } = useAuth();
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({
      ...formData,
   [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

 try {
 let result;
      if (isLogin) {
        result = await login(formData.email, formData.password);
      } else {
        result = await register(formData.username, formData.email, formData.password);
      }

      if (result.success) {
        navigate('/lobby');
      } else {
     setError(result.error);
      }
    } catch (err) {
      setError('Erro ao processar requisicao');
  } finally {
      setLoading(false);
  }
  };

  return React.createElement('div', { 
    style: { 
      minHeight: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
    } 
  },
    React.createElement('div', { 
      style: { 
        background: 'white', 
        padding: '40px', 
        borderRadius: '12px', 
        boxShadow: '0 10px 40px rgba(0,0,0,0.2)',
   width: '100%',
     maxWidth: '400px'
    } 
    },
      React.createElement('h1', { 
        style: { 
          textAlign: 'center', 
      marginBottom: '30px',
   color: '#667eea',
          fontSize: '28px'
        } 
      }, isLogin ? 'Login' : 'Registrar'),

      error && React.createElement('div', { 
      style: { 
          padding: '12px', 
          marginBottom: '20px', 
     background: '#ffebee', 
  color: '#c62828',
          borderRadius: '6px',
          fontSize: '14px',
          textAlign: 'center'
    } 
      }, error),

      React.createElement('form', { onSubmit: handleSubmit },
  !isLogin && React.createElement('div', { style: { marginBottom: '20px' } },
          React.createElement('label', { 
            style: { 
       display: 'block', 
              marginBottom: '8px',
          fontWeight: '600',
  color: '#333'
            } 
     }, 'Usuario'),
  React.createElement('input', {
            type: 'text',
      name: 'username',
   value: formData.username,
  onChange: handleChange,
            required: !isLogin,
     style: {
        width: '100%',
   padding: '12px',
          border: '2px solid #e0e0e0',
     borderRadius: '6px',
        fontSize: '16px',
              outline: 'none',
       transition: 'border 0.3s'
  },
            onFocus: (e) => e.target.style.borderColor = '#667eea',
       onBlur: (e) => e.target.style.borderColor = '#e0e0e0'
      })
    ),

    React.createElement('div', { style: { marginBottom: '20px' } },
          React.createElement('label', { 
       style: { 
              display: 'block', 
       marginBottom: '8px',
   fontWeight: '600',
        color: '#333'
            } 
          }, 'Email'),
          React.createElement('input', {
       type: 'email',
            name: 'email',
 value: formData.email,
   onChange: handleChange,
            required: true,
         style: {
       width: '100%',
              padding: '12px',
   border: '2px solid #e0e0e0',
 borderRadius: '6px',
   fontSize: '16px',
       outline: 'none'
          },
            onFocus: (e) => e.target.style.borderColor = '#667eea',
            onBlur: (e) => e.target.style.borderColor = '#e0e0e0'
    })
 ),

 React.createElement('div', { style: { marginBottom: '25px' } },
  React.createElement('label', { 
            style: { 
              display: 'block', 
         marginBottom: '8px',
              fontWeight: '600',
    color: '#333'
} 
     }, 'Senha'),
      React.createElement('input', {
    type: 'password',
      name: 'password',
            value: formData.password,
onChange: handleChange,
            required: true,
       minLength: isLogin ? undefined : 6,
  style: {
    width: '100%',
        padding: '12px',
              border: '2px solid #e0e0e0',
    borderRadius: '6px',
              fontSize: '16px',
              outline: 'none'
       },
            onFocus: (e) => e.target.style.borderColor = '#667eea',
      onBlur: (e) => e.target.style.borderColor = '#e0e0e0'
     })
        ),

        React.createElement('button', {
          type: 'submit',
          disabled: loading,
          style: {
   width: '100%',
            padding: '14px',
            background: loading ? '#ccc' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
color: 'white',
      border: 'none',
 borderRadius: '6px',
          fontSize: '16px',
            fontWeight: 'bold',
       cursor: loading ? 'not-allowed' : 'pointer',
            transition: 'transform 0.2s',
       marginBottom: '15px'
   },
   onMouseEnter: (e) => !loading && (e.target.style.transform = 'translateY(-2px)'),
          onMouseLeave: (e) => e.target.style.transform = 'translateY(0)'
 }, loading ? 'Processando...' : (isLogin ? 'Entrar' : 'Registrar')),

     React.createElement('div', { style: { textAlign: 'center' } },
          React.createElement('button', {
         type: 'button',
         onClick: () => {
         setIsLogin(!isLogin);
         setError('');
       setFormData({ username: '', email: '', password: '' });
  },
            style: {
       background: 'none',
   border: 'none',
      color: '#667eea',
        cursor: 'pointer',
          fontSize: '14px',
   textDecoration: 'underline'
            }
       }, isLogin ? 'Nao tem conta? Registre-se' : 'Ja tem conta? Faca login')
        )
      )
    )
  );
}

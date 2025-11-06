# Neumann React Chess - Guia de Instalacao Completo

## Pre-requisitos

- Node.js (v18 ou superior)
- MongoDB instalado e rodando localmente OU conta no MongoDB Atlas
- npm ou yarn

## Instalacao

### 1. Backend (Servidor)

```bash
# Entre na pasta do servidor
cd server

# Instale as dependencias
npm install

# Configure as variaveis de ambiente
cp .env.example .env

# Edite o arquivo .env com suas configuracoes
# PORT=5000
# MONGODB_URI=mongodb://localhost:27017/neumann-chess
# JWT_SECRET=seu_secret_super_seguro_mude_isso
# JWT_EXPIRE=7d

# Inicie o servidor
npm run dev
```

O servidor estara rodando em `http://localhost:5000`

### 2. Frontend (React)

```bash
# Em outro terminal, entre na pasta chess-react
cd chess-react

# Instale as dependencias
npm install

# Inicie o aplicativo
npm run dev
```

O frontend estara rodando em `http://localhost:5173`

## Usando o Aplicativo

### 1. Registro/Login
- Acesse `http://localhost:5173`
- Crie uma conta nova ou faca login
- Voce sera redirecionado para o Lobby

### 2. Iniciar Partida
- No Lobby, digite o **ID do usuario** do seu oponente
- Clique em "Desafiar"
- A partida sera criada e o tabuleiro aparecera

### 3. Jogar
- **Xadrez as Cegas**: Voce so ve suas proprias pecas
- Arraste e solte para fazer movimentos
- O tabuleiro inverte automaticamente a cada turno
- Notificacoes aparecem para capturas e xeques

### 4. Encontrar ID do Oponente

Para testar localmente, voce pode:

**Opcao 1: Criar dois usuarios no navegador**
1. Abra uma aba normal e registre Usuario 1
2. Abra uma aba anonima e registre Usuario 2
3. Use o console do navegador para pegar o ID:
   ```javascript
   JSON.parse(localStorage.getItem('user'))._id
   ```

**Opcao 2: Usar ferramentas de API**
Use Postman ou Insomnia para:
1. Registrar dois usuarios via `POST http://localhost:5000/api/auth/register`
2. Pegar os `_id` retornados

## Estrutura das Pastas

```
Neumann-React-Chess/
??? server/   # Backend Node.js
?   ??? config/       # Configuracao MongoDB
?   ??? controllers/       # Logica de negocios
?   ??? middleware/     # Autenticacao JWT
?   ??? models/         # Schemas MongoDB
?   ??? routes/    # Rotas da API
?   ??? server.js          # Arquivo principal
?
??? chess-react/        # Frontend React
    ??? src/
    ?   ??? components/    # Componentes reutilizaveis
    ?   ??? context/       # Context API (Auth)
  ?   ??? pages/  # Paginas (Login, Lobby, Game)
    ?   ??? services/      # Servicos de API
    ??? package.json
```

## Endpoints da API

### Autenticacao
- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/login` - Login
- `GET /api/auth/me` - Dados do usuario (requer token)

### Partidas
- `POST /api/games` - Criar partida
- `GET /api/games/current` - Partida em andamento
- `GET /api/games/:gameId` - Detalhes da partida
- `POST /api/games/:gameId/move` - Fazer movimento
- `PUT /api/games/:gameId/end` - Encerrar partida

## Troubleshooting

### Erro de conexao MongoDB
```
Erro: MongoNetworkError
```
**Solucao**: Certifique-se de que o MongoDB esta rodando:
```bash
# Windows
net start MongoDB

# Linux/Mac
sudo systemctl start mongod
```

### Erro CORS
```
Access to XMLHttpRequest blocked by CORS policy
```
**Solucao**: Verifique se o backend esta rodando na porta 5000

### Token invalido
```
401 Unauthorized
```
**Solucao**: Faca logout e login novamente

## Proximos Passos

- [ ] Implementar sistema de convites por email
- [ ] Adicionar chat durante a partida
- [ ] Sistema de ranking e ELO
- [ ] Replay de partidas
- [ ] Timers de xadrez
- [ ] Modo espectador

## Tecnologias Utilizadas

### Backend
- Node.js + Express
- MongoDB + Mongoose
- JWT para autenticacao
- bcryptjs para hash de senhas

### Frontend
- React 18
- React Router v6
- Axios
- chess.js
- react-chessboard

## Suporte

Para problemas ou duvidas, abra uma issue no repositorio.

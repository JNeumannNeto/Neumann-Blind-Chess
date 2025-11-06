# Neumann Chess Server

Backend para o aplicativo Neumann Blind Chess.

## Tecnologias

- Node.js
- Express.js
- MongoDB + Mongoose
- JWT para autenticacao
- bcryptjs para hash de senhas

## Instalacao

1. Entre na pasta do servidor:
```bash
cd server
```

2. Instale as dependencias:
```bash
npm install
```

3. Configure as variaveis de ambiente:
```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas configuracoes:
```
PORT=5000
MONGODB_URI=mongodb://localhost:27017/neumann-chess
JWT_SECRET=seu_secret_super_seguro
JWT_EXPIRE=7d
NODE_ENV=development
```

4. Certifique-se de que o MongoDB esta rodando localmente ou use MongoDB Atlas.

5. Inicie o servidor:
```bash
# Desenvolvimento (com nodemon)
npm run dev

# Producao
npm start
```

## Endpoints da API

### Autenticacao (`/api/auth`)

#### POST `/api/auth/register`
Registrar novo usuario
```json
{
  "username": "jogador1",
  "email": "jogador1@email.com",
  "password": "senha123"
}
```

#### POST `/api/auth/login`
Login de usuario
```json
{
  "email": "jogador1@email.com",
  "password": "senha123"
}
```

#### GET `/api/auth/me`
Obter dados do usuario autenticado (requer token)

### Partidas (`/api/games`)

**Todas as rotas requerem autenticacao (Bearer Token)**

#### POST `/api/games`
Criar nova partida
```json
{
  "blackPlayerId": "65abc123..."
}
```

#### GET `/api/games/current`
Obter partida atual em andamento do usuario

#### GET `/api/games/user/:userId`
Obter todas as partidas de um usuario
Query params: `?status=em_andamento&limit=20&page=1`

#### GET `/api/games/:gameId`
Obter detalhes de uma partida especifica

#### POST `/api/games/:gameId/move`
Registrar um movimento
```json
{
  "from": "e2",
  "to": "e4",
  "piece": "p",
  "san": "e4",
  "fen": "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1"
}
```

#### PUT `/api/games/:gameId/end`
Encerrar partida
```json
{
  "status": "xeque_mate",
  "result": "1-0",
  "winnerId": "65abc123..."
}
```

## Modelos de Dados

### User
- username (string, unico)
- email (string, unico)
- password (string, hash)
- stats (objeto com estatisticas)
- createdAt (data)

### Game
- whitePlayer (ref User)
- blackPlayer (ref User)
- moves (array de movimentos)
- currentFen (string)
- status (em_andamento, xeque_mate, empate, abandonada)
- winner (ref User)
- startedAt (data)
- endedAt (data)
- result (1-0, 0-1, 1/2-1/2)

## Autenticacao

Use o token JWT retornado no login/registro em todas as requisicoes protegidas:

```
Authorization: Bearer <seu_token_aqui>
```

## Status HTTP

- 200: Sucesso
- 201: Criado com sucesso
- 400: Requisicao invalida
- 401: Nao autorizado
- 403: Proibido
- 404: Nao encontrado
- 500: Erro interno do servidor

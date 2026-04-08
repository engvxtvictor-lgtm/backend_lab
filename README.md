# Paulo Lab - Docker & Postgres Migration

Este projeto foi totalmente refatorado para utilizar uma arquitetura microserviços baseada em Docker, mantendo o frontend e opções de persistência segmentadas, não mais dependentes de recursos proprietários do Supabase (como Auth e RLS).

## Diagrama da Arquitetura

- **/frontend**: Aplicação React com Vite e Shadcn.
- **/backend**: API REST Node.js e Express, orquestrando JWT e Bcrypt.
- **PostgreSQL**: Imagem oficial `latest` do Postgres hospedando esquemas relacionais, gatilhos e armazenamento isolado (sem Supabase).
- **pgAdmin**: Portal local e independente de interface web para visualizar o banco de dados.

## Instruções de Inicialização

Siga este passo a passo para executar a aplicação via Docker:

### 1. Preparação (Variáveis de Ambiente)
Copie o arquivo de variáveis de ambiente base:
```bash
cp .env.example .env
```
Nele você poderá modificar credenciais de banco e a secret key do JWT caso for rodar em produção.

### 2. Rodar o Ambiente com Docker Compose
O comando de inicialização a seguir irá baixar todas as imagens e rodar os 4 containers do sistema:
```bash
docker-compose up --build -d
```
Assim que for concluído:

- Toda a estrutura do banco e o usuário `admin` padrão serão populados pelo script `init.sql` atrelado ao container.
- **Frontend** disponível em: [http://localhost:5173](http://localhost:5173) *(Ou a qual porta você definir no `.env`)*
- **Backend (API)** disponível em: [http://localhost:3001/api](http://localhost:3001/api)
- **Painel de Controle pgAdmin**: [http://localhost:5050](http://localhost:5050)

### 3. Entrando no Sistema

A nossa injeção de tabela (`database/init.sql`) já criou para você um Admin com as seguintes credenciais de teste para efetuar login na plataforma:

**Admin Default do Sistema:**
- **Email:** `admin@paulo-lab.com`
- **Senha:** `admin123`

### 4. Acessando o pgAdmin

Para visualizar seu postgres através da interface web administrativa recém-erguida:

1. Acesse [http://localhost:5050](http://localhost:5050) na sua máquina host (ou servidor IP VPS).
2. Entre com o Email e Senha definidos nas chaves `PGADMIN_DEFAULT_EMAIL` e `PGADMIN_DEFAULT_PASSWORD` (Por padrão, `admin@paulo-lab.com` / `admin`).
3. Adicione um novo servidor:
   - **Name:** Paulo Lab DB
   - Aba **Connection**:
     - **Hostname / address:** `db` (O nome do host container no Docker Compose)
     - **Port:** `5432`
     - **Database / Username / Password:** Mesmos do `.env` (`paulo_lab_db`, `postgres`, `secret_postgres_pass`).  

## Desenvolvimento Local (Sem Docker)

Se preferir rodar apenas o servidor com o NodeJS na sua máquina e conectar no banco via Docker:

**No Terminal 1 (Backend):**
```bash
cd backend
npm install
npm run dev
```

**No Terminal 2 (Frontend):**
```bash
cd frontend
npm install
npm run dev
```
*(Garante que o backend já esteja escutando e ligado ao DB)*

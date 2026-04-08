import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';

// Carregar variáveis de ambiente
dotenv.config({ path: path.resolve(__dirname, '../.env') });

// Rotas
import authRoutes from './routes/auth';
import patientRoutes from './routes/patients';
import examRoutes from './routes/exams';
import dashboardRoutes from './routes/dashboard';
import orderRoutes from './routes/orders';
import userRoutes from './routes/users';
import reportRoutes from './routes/reports';

const app = express();
const PORT = process.env.PORT || 3001;

// Middlewares
app.use(cors());
app.use(express.json());

// Registro de Rotas
app.use('/api/auth', authRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/exams', examRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/reports', reportRoutes);

// Rota de Teste (Health Check)
app.get('/health', (req, res) => {
  res.json({ status: 'Ok', message: 'Backend do Paulo Lab rodando...' });
});

// Iniciando Servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando em: http://localhost:${PORT}`);
  console.log(`📊 Integrado ao banco: ${process.env.DB_NAME}`);
});

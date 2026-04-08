import pool from '../db';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';

async function initDb() {
  console.log('🎬 Iniciando inicialização do banco de dados...');
  
  try {
    // 1. Criar tabela de usuários se não existir
    await pool.query(`
      CREATE TABLE IF NOT EXISTS public.users (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);
    console.log('✅ Tabela public.users verificada/criada.');

    // 2. Verificar se já existe um admin
    const adminEmail = 'admin@paulolab.com';
    const checkAdmin = await pool.query('SELECT id FROM public.users WHERE email = $1', [adminEmail]);

    if (checkAdmin.rowCount === 0) {
      console.log('👤 Criando usuário administrador padrão...');
      const userId = uuidv4();
      const passwordHash = await bcrypt.hash('admin123', 10);
      
      await pool.query(
        'INSERT INTO public.users (id, email, password_hash, full_name) VALUES ($1, $2, $3, $4)',
        [userId, adminEmail, passwordHash, 'Administrador Paulo Lab']
      );

      // Adicionar perfil
      await pool.query(
        'INSERT INTO public.profiles (user_id, full_name) VALUES ($1, $2) ON CONFLICT (user_id) DO NOTHING',
        [userId, 'Administrador Paulo Lab']
      );

      // Adicionar role de admin
      await pool.query(
        'INSERT INTO public.user_roles (user_id, role) VALUES ($1, $2) ON CONFLICT (user_id, role) DO NOTHING',
        [userId, 'admin']
      );

      console.log('🚀 Admin criado com sucesso!');
      console.log('📧 Email: admin@paulolab.com');
      console.log('🔑 Senha: admin123');
    } else {
      console.log('ℹ️ Usuário administrador já existe.');
    }

    console.log('✨ Inicialização concluída!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Erro durante a inicialização:', err);
    process.exit(1);
  }
}

initDb();

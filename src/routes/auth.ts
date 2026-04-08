import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../db';

const router = express.Router();
const JWT_SECRET = process.env.jwt_secret || 'super-secret-key';

// Login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const result = await pool.query(
      'SELECT u.*, p.full_name, r.role FROM users u ' +
      'LEFT JOIN profiles p ON u.id = p.id ' +
      'LEFT JOIN user_roles r ON u.id = r.user_id ' +
      'WHERE u.email = $1',
      [email]
    );

    const user = result.rows[0];
    if (!user) return res.status(401).json({ error: 'Credenciais inválidas' });

    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) return res.status(401).json({ error: 'Credenciais inválidas' });

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role || 'visualizador' },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        role: user.role || 'visualizador'
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro no servidor' });
  }
});

// Register
router.post('/register', async (req, res) => {
  const { email, password, full_name } = req.body;

  try {
    const existingUser = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'E-mail indisponível' });
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const newUserResult = await pool.query(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email',
      [email, password_hash]
    );

    const newUser = newUserResult.rows[0];

    await pool.query(
      'INSERT INTO profiles (id, full_name) VALUES ($1, $2)',
      [newUser.id, full_name || email.split('@')[0]]
    );

    // Default role
    await pool.query(
      'INSERT INTO user_roles (user_id, role) VALUES ($1, $2)',
      [newUser.id, 'recepcionista']
    );

    const token = jwt.sign(
      { id: newUser.id, email: newUser.email, role: 'recepcionista' },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: newUser.id,
        email: newUser.email,
        full_name: full_name,
        role: 'recepcionista'
      }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro no servidor' });
  }
});

// Get Current User Info
router.get('/me', async (req: any, res) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Não autenticado' });

  try {
    const decoded: any = jwt.verify(token, JWT_SECRET);
    const result = await pool.query(
      'SELECT u.id, u.email, p.full_name, r.role FROM users u ' +
      'LEFT JOIN profiles p ON u.id = p.id ' +
      'LEFT JOIN user_roles r ON u.id = r.user_id ' +
      'WHERE u.id = $1',
      [decoded.id]
    );

    const user = result.rows[0];
    if (!user) return res.status(404).json({ error: 'Usuário não encontrado' });

    res.json(user);
  } catch (err) {
    res.status(401).json({ error: 'Token inválido' });
  }
});

export default router;

import express from 'express';
import pool from '../db';
import { authenticateToken, authorizeRoles } from '../middleware/auth';

const router = express.Router();

// Listar todos os usuários com seus papéis (Apenas Admin)
router.get('/', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.id, u.email, u.full_name, u.created_at, r.role
      FROM users u
      LEFT JOIN user_roles r ON u.id = r.user_id
      ORDER BY u.full_name ASC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar usuários' });
  }
});

// Atualizar papel de um usuário (Apenas Admin)
router.put('/:id/role', authenticateToken, authorizeRoles('admin'), async (req, res) => {
  const { id } = req.params;
  const { role } = req.body;

  try {
    // 1. Verificar se o role existe ou inserir
    await pool.query(`
      INSERT INTO user_roles (user_id, role)
      VALUES ($1, $2)
      ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role, created_at = NOW()
    `, [id, role]);

    res.json({ message: 'Papel atualizado com sucesso' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao atualizar papel' });
  }
});

export default router;

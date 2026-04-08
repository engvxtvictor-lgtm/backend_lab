import express from 'express';
import pool from '../db';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Listar todos os exames
router.get('/', authenticateToken, async (req, res) => {
  const { search } = req.query;
  try {
    let query = 'SELECT e.*, c.name as category_name FROM exams e ' +
                'LEFT JOIN exam_categories c ON e.category_id = c.id';
    const params: any[] = [];
    
    if (search) {
      query += ' WHERE e.name ILIKE $1 OR c.name ILIKE $1';
      params.push(`%${search}%`);
    }
    
    query += ' ORDER BY e.name ASC';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar exames' });
  }
});

// Listar categorias
router.get('/categories', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM exam_categories ORDER BY name ASC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar categorias' });
  }
});

// Criar novo exame (Apenas Admin)
router.post('/', authenticateToken, async (req: any, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Acesso negado' });
  const { name, description, price, category_id, is_active } = req.body;
  try {
    const result = await pool.query(
        'INSERT INTO exams (name, description, price, category_id, is_active) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [name, description, price, category_id, is_active]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao criar exame' });
  }
});

export default router;

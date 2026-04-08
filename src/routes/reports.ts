import express from 'express';
import pool from '../db';
import { authenticateToken, authorizeRoles } from '../middleware/auth';

const router = express.Router();

router.get('/', authenticateToken, authorizeRoles('admin', 'recepcionista'), async (req, res) => {
  const { startDate, endDate } = req.query;

  try {
    const result = await pool.query(`
      SELECT o.*, p.full_name as patient_name,
        (SELECT json_agg(json_build_object('id', i.id, 'exam', json_build_object('name', e.name), 'price', i.price))
         FROM service_order_items i
         JOIN exams e ON i.exam_id = e.id
         WHERE i.order_id = o.id) as items
      FROM service_orders o
      JOIN patients p ON o.patient_id = p.id
      WHERE o.created_at >= $1 AND o.created_at <= $2
      ORDER BY o.created_at DESC
    `, [startDate, endDate]);

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao gerar relatório' });
  }
});

export default router;

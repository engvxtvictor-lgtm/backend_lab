import express from 'express';
import pool from '../db';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Criar Novo Atendimento (Ordem de Serviço + Itens)
router.post('/', authenticateToken, async (req: any, res) => {
  const { patient_id, total_amount, discount, payment_method, notes, items } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Inserir Ordem de Serviço
    const orderResult = await client.query(
      'INSERT INTO service_orders (patient_id, total_amount, discount, payment_method, notes, created_by, status) ' +
      'VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [patient_id, total_amount, discount, payment_method, notes, req.user.id, 'aguardando']
    );

    const order = orderResult.rows[0];

    // 2. Inserir Itens
    for (const item of items) {
      await client.query(
        'INSERT INTO service_order_items (order_id, exam_id, price) VALUES ($1, $2, $3)',
        [order.id, item.exam_id, item.price]
      );
    }

    await client.query('COMMIT');

    // 3. Buscar ordem completa para retorno
    const completeOrder = await pool.query(`
      SELECT o.*, p.full_name as patient_name, 
        (SELECT json_agg(json_build_object('id', i.id, 'exam', json_build_object('name', e.name), 'price', i.price))
         FROM service_order_items i
         JOIN exams e ON i.exam_id = e.id
         WHERE i.order_id = o.id) as items
      FROM service_orders o
      JOIN patients p ON o.patient_id = p.id
      WHERE o.id = $1
    `, [order.id]);

    res.status(201).json(completeOrder.rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Erro ao registrar atendimento' });
  } finally {
    client.release();
  }
});

export default router;

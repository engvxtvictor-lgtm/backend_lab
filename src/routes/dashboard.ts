import express from 'express';
import pool from '../db';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // Stats Hoje
    const statsResult = await pool.query(`
      SELECT 
        COUNT(DISTINCT patient_id) as patients_today,
        COUNT(*) FILTER (WHERE status = 'finalizado') as exams_completed,
        SUM(total_amount - COALESCE(discount, 0)) FILTER (WHERE status != 'cancelado') as daily_revenue,
        COUNT(*) FILTER (WHERE status IN ('aguardando', 'em_andamento')) as pending_orders
      FROM service_orders 
      WHERE created_at >= $1
    `, [today]);

    const stats = statsResult.rows[0];

    // Pedidos Recentes
    const recentResult = await pool.query(`
      SELECT o.*, p.full_name as patient_name
      FROM service_orders o
      JOIN patients p ON o.patient_id = p.id
      ORDER BY o.created_at DESC
      LIMIT 10
    `);

    res.json({
      stats: {
        patientsToday: parseInt(stats.patients_today || '0'),
        examsCompleted: parseInt(stats.exams_completed || '0'),
        dailyRevenue: parseFloat(stats.daily_revenue || '0'),
        pendingOrders: parseInt(stats.pending_orders || '0'),
      },
      recentOrders: recentResult.rows
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao carregar dashboard' });
  }
});

export default router;

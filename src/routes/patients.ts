import express from 'express';
import pool from '../db';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Listar todos os pacientes (Com suporte a busca)
router.get('/', authenticateToken, async (req, res) => {
  const { search } = req.query;
  try {
    let query = 'SELECT * FROM patients';
    const params: any[] = [];
    
    if (search) {
      query += ' WHERE full_name ILIKE $1 OR cpf LIKE $1 OR email ILIKE $1';
      params.push(`%${search}%`);
    }
    
    query += ' ORDER BY full_name ASC';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar pacientes' });
  }
});

// Criar novo paciente
router.post('/', authenticateToken, async (req, res) => {
  const { full_name, birth_date, cpf, rg, email, phone, address, city, state, zip_code, notes } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO patients (full_name, birth_date, cpf, rg, email, phone, address, city, state, zip_code, notes) ' +
      'VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *',
      [full_name, birth_date, cpf, rg, email, phone, address, city, state, zip_code, notes]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao cadastrar paciente' });
  }
});

// Editar paciente
router.put('/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { full_name, birth_date, cpf, rg, email, phone, address, city, state, zip_code, notes } = req.body;
  try {
    const result = await pool.query(
      'UPDATE patients SET full_name=$1, birth_date=$2, cpf=$3, rg=$4, email=$5, phone=$6, address=$7, city=$8, state=$9, zip_code=$10, notes=$11, updated_at=NOW() ' +
      'WHERE id=$12 RETURNING *',
      [full_name, birth_date, cpf, rg, email, phone, address, city, state, zip_code, notes, id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Paciente não encontrado' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao atualizar paciente' });
  }
});

// Excluir paciente (Apenas admins e recepcionistas)
router.delete('/:id', authenticateToken, async (req: any, res) => {
  const { id } = req.params;
  const { role } = req.user;

  if (role === 'visualizador') {
    return res.status(403).json({ error: 'Acesso negado' });
  }

  try {
    const result = await pool.query('DELETE FROM patients WHERE id = $1', [id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Paciente não encontrado' });
    res.json({ message: 'Paciente excluído com sucesso' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao excluir paciente. Verifique se há vínculos pendentes.' });
  }
});

export default router;

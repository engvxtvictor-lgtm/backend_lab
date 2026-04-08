export type AppRole = 'admin' | 'recepcionista' | 'tecnico' | 'visualizador';
export type OrderStatus = 'aguardando' | 'em_andamento' | 'finalizado' | 'cancelado';

export interface Profile {
  id: string;
  user_id: string;
  full_name: string;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface UserRole {
  id: string;
  user_id: string;
  role: AppRole;
  created_at: string;
}

export interface Patient {
  id: string;
  full_name: string;
  birth_date: string | null;
  cpf: string | null;
  rg: string | null;
  phone: string | null;
  email: string | null;
  address: string | null;
  city: string | null;
  state: string | null;
  zip_code: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface ExamCategory {
  id: string;
  name: string;
  description: string | null;
  created_at: string;
}

export interface Exam {
  id: string;
  name: string;
  description: string | null;
  price: number;
  category_id: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  category?: ExamCategory;
}

export interface ServiceOrder {
  id: string;
  order_number: number;
  patient_id: string;
  status: OrderStatus;
  total_amount: number;
  discount: number;
  payment_method: string | null;
  notes: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
  patient_name?: string; // Nome direto do paciente para conveniência
  patient?: Patient;
  items?: ServiceOrderItem[];
}

export interface ServiceOrderItem {
  id: string;
  order_id: string;
  exam_id: string;
  price: number;
  created_at: string;
  exam_name?: string; // Nome direto do exame para conveniência
  exam?: Exam;
}

export interface DashboardStats {
  patientsToday: number;
  examsCompleted: number;
  dailyRevenue: number;
  pendingOrders: number;
}

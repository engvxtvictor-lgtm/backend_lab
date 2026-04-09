-- Habilitar extensão para UUID se necessário
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. TABELAS DE USUÁRIOS E SEGURANÇA
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY, 
    full_name VARCHAR(255) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_user_profile FOREIGN KEY(id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID PRIMARY KEY,
    role VARCHAR(50) NOT NULL DEFAULT 'recepcionista',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_user_role FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 2. TABELAS DE APOIO (PACIENTES E EXAMES)
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(255) NOT NULL,
    birth_date DATE,
    cpf VARCHAR(14) UNIQUE,
    rg VARCHAR(20),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state CHAR(2),
    zip_code VARCHAR(10),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patients_full_name ON patients(full_name);
CREATE INDEX IF NOT EXISTS idx_patients_cpf ON patients(cpf);

CREATE TABLE IF NOT EXISTS exam_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id INTEGER REFERENCES exam_categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exams_name ON exams(name);

-- 3. TABELAS DE OPERAÇÃO (ORDENS DE SERVIÇO)
CREATE TABLE IF NOT EXISTS service_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id),
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    discount DECIMAL(10, 2) DEFAULT 0.00,
    payment_method VARCHAR(50),
    status VARCHAR(30) NOT NULL DEFAULT 'aguardando',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS service_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    exam_id UUID NOT NULL REFERENCES exams(id),
    price DECIMAL(10, 2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_so_dashboard_metrics ON service_orders (created_at, status);
CREATE INDEX IF NOT EXISTS idx_so_patient_id ON service_orders (patient_id);

-- 4. TRIGGERS (OPCIONAL)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_patients_modtime BEFORE UPDATE ON patients FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 5. POPULAR DADOS INICIAIS
INSERT INTO exam_categories (name) VALUES 
('Hematologia'), ('Bioquímica'), ('Imunologia'), ('Urinálise'), ('Parasitologia')
ON CONFLICT (name) DO NOTHING;

-- 6. CRIAR USUÁRIO ADMIN (CADU)
DO $$ 
DECLARE 
    admin_id UUID := gen_random_uuid();
BEGIN
    -- Inserir na tabela de autenticação
    INSERT INTO users (id, email, password_hash)
    VALUES (admin_id, 'admin@admin.com', '$2b$10$XYTrsnmMTkLTKB2FjsyjJeYrSk5tlt2ZrqgClSiayd32mGJdbLiBu');

    -- Inserir Perfil
    INSERT INTO profiles (id, full_name)
    VALUES (admin_id, 'Administrador do Sistema');

    -- Inserir Papel como Admin
    INSERT INTO user_roles (user_id, role)
    VALUES (admin_id, 'admin');
END $$;



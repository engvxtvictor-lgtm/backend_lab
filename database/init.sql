-- Clean initialization of the PostgreSQL Database for Lacsim (formerly Paulo Lab)
-- This script replaces the old schema and sets up the new structure requested on 2026-04-08

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. LIMPEZA TOTAL
DROP TABLE IF EXISTS public.service_order_items CASCADE;
DROP TABLE IF EXISTS public.service_orders CASCADE;
DROP TABLE IF EXISTS public.exams CASCADE;
DROP TABLE IF EXISTS public.exam_categories CASCADE;
DROP TABLE IF EXISTS public.patients CASCADE;
DROP TABLE IF EXISTS public.coupons CASCADE;
DROP TABLE IF EXISTS public.user_roles CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TYPE IF EXISTS public.app_role CASCADE;
DROP TYPE IF EXISTS public.order_status CASCADE;
DROP TYPE IF EXISTS public.payment_status CASCADE;

-- 2. ENUMS (Papeis e Status conforme pedido)
CREATE TYPE public.app_role AS ENUM ('admin', 'financeiro', 'medico', 'recepcao');
CREATE TYPE public.order_status AS ENUM ('aguardando', 'realizado', 'laudo_emitido', 'cancelado');
CREATE TYPE public.payment_status AS ENUM ('pendente', 'pago', 'parcial');

-- 3. USUÁRIOS E PERMISSÕES
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role public.app_role NOT NULL DEFAULT 'recepcao',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. CUPONS DE DESCONTO (Específicos por paciente ou gerais)
CREATE TABLE public.coupons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    specific_patient_id UUID, -- Se for NULL, vale para todos
    expires_at TIMESTAMP WITH TIME ZONE
);

-- 5. PACIENTES (Com todos os campos solicitados)
CREATE TABLE public.patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    cpf TEXT UNIQUE NOT NULL,
    birth_date DATE NOT NULL,
    address TEXT,
    phone TEXT,
    is_convenio BOOLEAN DEFAULT false, -- Canto separado para convênio
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. EXAMES (Valores personalizados e categorias)
CREATE TABLE public.exam_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE -- Hematologia, Bioquímica, etc.
);

CREATE TABLE public.exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category_id UUID REFERENCES public.exam_categories(id),
    base_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 7. ORDENS DE SERVIÇO (Financeiro e Status integrados)
CREATE TABLE public.service_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number SERIAL,
    patient_id UUID REFERENCES public.patients(id) ON DELETE RESTRICT NOT NULL,
    payment_method TEXT CHECK (payment_method IN ('dinheiro', 'cartao', 'pix')),
    payment_status public.payment_status DEFAULT 'pendente',
    order_status public.order_status DEFAULT 'aguardando',
    coupon_id UUID REFERENCES public.coupons(id),
    total_amount DECIMAL(10,2) DEFAULT 0,
    laudo_url TEXT, -- Para os laudos emitidos pelo sys
    signed_at TIMESTAMP WITH TIME ZONE, -- Via confirmando exames (assinatura)
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE public.service_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.service_orders(id) ON DELETE CASCADE,
    exam_id UUID REFERENCES public.exams(id),
    custom_price DECIMAL(10,2) NOT NULL -- Valores personalizados por OS
);

-- 8. DADOS INICIAIS (Admin e Teste)
-- Senha: admin123
INSERT INTO public.users (id, email, password_hash) 
VALUES ('00000000-0000-0000-0000-000000000000', 'admin@paulolab.com', '$2a$10$w8.W8E4/Kj59k/gX9C.AauiY8s.p5dF9Z1Fh.S8gL5a69n1q8P1K2');

INSERT INTO public.profiles (id, full_name, role) 
VALUES ('00000000-0000-0000-0000-000000000000', 'Admin Geral', 'admin');
    
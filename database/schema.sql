-- Lacsim - PostgreSQL Database Schema
-- Updated on 2026-04-08

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. ENUMS
CREATE TYPE public.app_role AS ENUM ('admin', 'financeiro', 'medico', 'recepcao');
CREATE TYPE public.order_status AS ENUM ('aguardando', 'realizado', 'laudo_emitido', 'cancelado');
CREATE TYPE public.payment_status AS ENUM ('pendente', 'pago', 'parcial');

-- 2. TABLES

-- Users
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role public.app_role NOT NULL DEFAULT 'recepcao',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Coupons
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    specific_patient_id UUID,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Patients
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    cpf TEXT UNIQUE NOT NULL,
    birth_date DATE NOT NULL,
    address TEXT,
    phone TEXT,
    is_convenio BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Exam Categories
CREATE TABLE IF NOT EXISTS public.exam_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE
);

-- Exams
CREATE TABLE IF NOT EXISTS public.exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    category_id UUID REFERENCES public.exam_categories(id),
    base_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Service Orders
CREATE TABLE IF NOT EXISTS public.service_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number SERIAL,
    patient_id UUID REFERENCES public.patients(id) ON DELETE RESTRICT NOT NULL,
    payment_method TEXT CHECK (payment_method IN ('dinheiro', 'cartao', 'pix')),
    payment_status public.payment_status DEFAULT 'pendente',
    order_status public.order_status DEFAULT 'aguardando',
    coupon_id UUID REFERENCES public.coupons(id),
    total_amount DECIMAL(10,2) DEFAULT 0,
    laudo_url TEXT,
    signed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Service Order Items
CREATE TABLE IF NOT EXISTS public.service_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.service_orders(id) ON DELETE CASCADE,
    exam_id UUID REFERENCES public.exams(id),
    custom_price DECIMAL(10,2) NOT NULL
);

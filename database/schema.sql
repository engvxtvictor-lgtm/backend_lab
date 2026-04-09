    


    -- 1. Tabela Principal de Autenticação
    CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- 2. Tabela de Perfis (Relação 1:1 com Users)
    -- O id aqui não é gerado, ele é herdado da tabela users
    CREATE TABLE IF NOT EXISTS profiles (
        id UUID PRIMARY KEY, 
        full_name VARCHAR(255) NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

        CONSTRAINT fk_user_profile
            FOREIGN KEY(id) 
            REFERENCES users(id) 
            ON DELETE CASCADE
    );

    -- 3. Tabela de Papéis/Permissões
    CREATE TABLE IF NOT EXISTS user_roles (
        user_id UUID PRIMARY KEY, -- Um usuário tem um papel único neste design
        role VARCHAR(50) NOT NULL DEFAULT 'recepcionista',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

        CONSTRAINT fk_user_role
            FOREIGN KEY(user_id) 
            REFERENCES users(id) 
            ON DELETE CASCADE
    );

    -- Índices para login rápido
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);






    -- 1. Garantir que a tabela service_orders tenha suporte aos novos campos e status
    -- Se você já criou a tabela, use os comandos ALTER TABLE comentados abaixo.
    CREATE TABLE IF NOT EXISTS service_orders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID NOT NULL REFERENCES patients(id),
        
        -- Valores para cálculo do Dashboard
        total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
        discount DECIMAL(10, 2) DEFAULT 0.00,
        
        -- Estados suportados pelo seu router: 'finalizado', 'cancelado', 'aguardando', 'em_andamento'
        status VARCHAR(30) NOT NULL DEFAULT 'aguardando', 
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        -- Metadados adicionais
        created_by UUID REFERENCES users(id)
    );

    -- 2. Índices Cruciais para o Dashboard
    -- O filtro por data (created_at >= $1) é a parte mais pesada da query.
    CREATE INDEX IF NOT EXISTS idx_so_dashboard_metrics 
    ON service_orders (created_at, status);

    -- Otimiza o JOIN com a tabela de pacientes na listagem de "Pedidos Recentes"
    CREATE INDEX IF NOT EXISTS idx_so_patient_id ON service_orders (patient_id);

    -- 3. Caso você já tenha a tabela e precise apenas adicionar os novos status ou colunas:
    /*
    ALTER TABLE service_orders ADD COLUMN IF NOT EXISTS discount DECIMAL(10, 2) DEFAULT 0.00;
    ALTER TABLE service_orders ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'aguardando';
    */






    -- 1. Tabela de Categorias de Exames
    CREATE TABLE IF NOT EXISTS exam_categories (
        id SERIAL PRIMARY KEY, -- Usando SERIAL por ser uma tabela de cadastro simples
        name VARCHAR(100) NOT NULL UNIQUE,
        description TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- 2. Tabela de Exames (Catálogo)
    CREATE TABLE IF NOT EXISTS exams (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        category_id INTEGER, -- Relacionamento com a categoria
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

        -- Chave Estrangeira
        CONSTRAINT fk_exam_category
            FOREIGN KEY(category_id) 
            REFERENCES exam_categories(id)
            ON DELETE SET NULL -- Se a categoria sumir, o exame permanece mas sem categoria
    );

    -- Índices para otimizar as buscas do router
    CREATE INDEX IF NOT EXISTS idx_exams_name ON exams(name);
    CREATE INDEX IF NOT EXISTS idx_exam_categories_name ON exam_categories(name);

    -- Inserção de categorias iniciais (Exemplos comuns para o Med Atlas)
    INSERT INTO exam_categories (name) VALUES 
    ('Hematologia'), 
    ('Bioquímica'), 
    ('Imunologia'), 
    ('Urinálise'), 
    ('Parasitologia')
    ON CONFLICT (name) DO NOTHING;







    -- 1. Certifique-se de que a tabela de usuários existe (para o created_by)
    -- Se já tiver criado antes, ignore esta parte.
    CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        full_name VARCHAR(255) NOT NULL
    );

    -- 2. Tabela de Ordens de Serviço (Atualizada para este router)
    CREATE TABLE IF NOT EXISTS service_orders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID NOT NULL,
        created_by UUID NOT NULL, -- ID do admin/recepcionista que logou o atendimento
        
        -- Valores Financeiros
        total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
        discount DECIMAL(10, 2) DEFAULT 0.00,
        payment_method VARCHAR(50), -- Ex: 'pix', 'cartao_credito', 'dinheiro'
        
        -- Status e Notas
        status VARCHAR(30) NOT NULL DEFAULT 'aguardando', -- conforme seu código: 'aguardando'
        notes TEXT,
        
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

        -- Relacionamentos
        CONSTRAINT fk_patient 
            FOREIGN KEY(patient_id) 
            REFERENCES patients(id),
        CONSTRAINT fk_user_creator 
            FOREIGN KEY(created_by) 
            REFERENCES users(id)
    );

    -- 3. Tabela de Itens da Ordem (Relacionamento N:N)
    CREATE TABLE IF NOT EXISTS service_order_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id UUID NOT NULL,
        exam_id UUID NOT NULL,
        price DECIMAL(10, 2) NOT NULL, -- Importante: salva o preço do momento da venda

        CONSTRAINT fk_order 
            FOREIGN KEY(order_id) 
            REFERENCES service_orders(id) 
            ON DELETE CASCADE,
        CONSTRAINT fk_exam 
            FOREIGN KEY(exam_id) 
            REFERENCES exams(id)
    );

    -- Índices para otimizar a busca final do router
    CREATE INDEX IF NOT EXISTS idx_so_patient_id ON service_orders(patient_id);
    CREATE INDEX IF NOT EXISTS idx_so_items_order_id ON service_order_items(order_id);







    -- Criar a tabela de pacientes com todos os campos do router
    CREATE TABLE IF NOT EXISTS patients (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        
        -- Dados Pessoais
        full_name VARCHAR(255) NOT NULL,
        birth_date DATE,
        cpf VARCHAR(14) UNIQUE, -- Formato: 000.000.000-00
        rg VARCHAR(20),
        
        -- Contato
        email VARCHAR(255) UNIQUE,
        phone VARCHAR(20),
        
        -- Endereço
        address TEXT,
        city VARCHAR(100),
        state CHAR(2), -- Sigla do estado (ex: PI, CE, SP)
        zip_code VARCHAR(10),
        
        -- Informações Adicionais
        notes TEXT,
        
        -- Controle de Auditoria
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Índices para otimizar a busca (usados na query com ILIKE e ORDER BY)
    CREATE INDEX IF NOT EXISTS idx_patients_full_name ON patients(full_name);
    CREATE INDEX IF NOT EXISTS idx_patients_cpf ON patients(cpf);
    CREATE INDEX IF NOT EXISTS idx_patients_email ON patients(email);

    -- Trigger para atualizar automaticamente o campo updated_at (Opcional, mas recomendado)
    -- Isso garante que o updated_at mude mesmo se você esquecer de passar no SQL
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ language 'plpgsql';

    CREATE TRIGGER update_patients_modtime
        BEFORE UPDATE ON patients
        FOR EACH ROW
        EXECUTE PROCEDURE update_updated_at_column();






    -- 1. Tabela de Pacientes
    CREATE TABLE IF NOT EXISTS patients (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        full_name VARCHAR(255) NOT NULL,
        cpf VARCHAR(14) UNIQUE, -- Comum em sistemas brasileiros
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- 2. Tabela de Exames (Catálogo de exames disponíveis)
    CREATE TABLE IF NOT EXISTS exams (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        base_price DECIMAL(10, 2),
        active BOOLEAN DEFAULT TRUE
    );

    -- 3. Tabela de Ordens de Serviço (Cabeçalho da OS)
    CREATE TABLE IF NOT EXISTS service_orders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID NOT NULL,
        status VARCHAR(50) DEFAULT 'pendente', -- Ex: pendente, concluído, cancelado
        total_amount DECIMAL(10, 2) DEFAULT 0.00,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        CONSTRAINT fk_patient
            FOREIGN KEY(patient_id) 
            REFERENCES patients(id) 
            ON DELETE CASCADE
    );

    -- 4. Tabela de Itens da Ordem de Serviço (Relação N:N entre OS e Exames)
    CREATE TABLE IF NOT EXISTS service_order_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        order_id UUID NOT NULL,
        exam_id UUID NOT NULL,
        price DECIMAL(10, 2) NOT NULL, -- Preço praticado no momento da venda
        
        CONSTRAINT fk_order
            FOREIGN KEY(order_id) 
            REFERENCES service_orders(id) 
            ON DELETE CASCADE,
            
        CONSTRAINT fk_exam
            FOREIGN KEY(exam_id) 
            REFERENCES exams(id)
    );

    -- Índices para performance no Relatório (Filtros por data)
    CREATE INDEX IF NOT EXISTS idx_service_orders_created_at ON service_orders(created_at);
    CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON service_order_items(order_id);









    -- Criar a tabela de usuários
    CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Criar a tabela de papéis (roles)
    -- Utilizamos ON CONFLICT no código, o que sugere que um usuário tem um papel único
    CREATE TABLE IF NOT EXISTS user_roles (
        id SERIAL PRIMARY KEY,
        user_id UUID UNIQUE NOT NULL, -- UNIQUE garante que cada user_id tenha apenas um registro
        role VARCHAR(50) NOT NULL DEFAULT 'user',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        -- Chave estrangeira para manter a integridade referencial
        CONSTRAINT fk_user
            FOREIGN KEY(user_id) 
            REFERENCES users(id) 
            ON DELETE CASCADE
    );

    -- Índices para otimizar a busca por nome (usado no ORDER BY da rota GET)
    CREATE INDEX IF NOT EXISTS idx_users_full_name ON users(full_name);
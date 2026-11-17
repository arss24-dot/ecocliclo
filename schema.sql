-- ====================================================================
-- ECO CICLO - SISTEMA WEB DE GESTÃO INTELIGENTE DE RESÍDUOS SÓLIDOS
-- Instituto Federal de Alagoas (IFAL)
-- Equipe: Adriely Rauane, Ana Luiza Mariano, Francyne Sotero, Maria Júlia Vieira, Rayssa Alves
-- ====================================================================

CREATE DATABASE IF NOT EXISTS ecociclo_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ecociclo_db;

-- --------------------------------------------------------------------
-- 1. TABELA DE USUÁRIOS E PERFIS (Cidadão, Coletora, Prefeitura)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    perfil ENUM('cidadao', 'empresa_coleta', 'prefeitura') DEFAULT 'cidadao',
    telefone VARCHAR(20),
    cpf_cnpj VARCHAR(20),
    logradouro VARCHAR(200),
    numero VARCHAR(20),
    bairro VARCHAR(100),
    cidade VARCHAR(100) DEFAULT 'Maceió',
    estado VARCHAR(2) DEFAULT 'AL',
    cep VARCHAR(10),
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- --------------------------------------------------------------------
-- 2. TABELA DE ECOPONTOS (PONTOS DE ENTREGA VOLUNTÁRIA - PEV)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ecopontos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    logradouro VARCHAR(200) NOT NULL,
    numero VARCHAR(20),
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) DEFAULT 'Maceió',
    estado VARCHAR(2) DEFAULT 'AL',
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    materiais_aceitos TEXT NOT NULL,
    horario_funcionamento VARCHAR(150) NOT NULL,
    capacidade_m3 INT DEFAULT 50,
    status ENUM('operacional', 'em_manutencao', 'lotado') DEFAULT 'operacional',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------------------
-- 3. TABELA DE DENÚNCIAS DE DESCARTE IRREGULAR (Cidadão -> Prefeitura)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS denuncias_descarte (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_protocolo VARCHAR(30) UNIQUE NOT NULL,
    usuario_id INT,
    tipo_residuo VARCHAR(100) NOT NULL,
    tamanho_estimado ENUM('pequeno', 'medio', 'grande_critico') DEFAULT 'medio',
    descricao TEXT NOT NULL,
    foto_denuncia_url TEXT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    endereco_aproximado VARCHAR(255) NOT NULL,
    bairro VARCHAR(100) NOT NULL,
    tem_foco_dengue BOOLEAN DEFAULT FALSE,
    obstrui_via_publica BOOLEAN DEFAULT FALSE,
    status ENUM('registrada', 'em_analise', 'ordem_gerada', 'atendida', 'cancelada') DEFAULT 'registrada',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- --------------------------------------------------------------------
-- 4. TABELA DE AGENDAMENTOS DE RESÍDUOS VOLUMOSOS (Cata-Treco)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agendamentos_volumosos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_protocolo VARCHAR(30) UNIQUE NOT NULL,
    usuario_id INT NOT NULL,
    categoria_volumoso ENUM('sofa_colchao', 'moveis_madeira', 'eletrodomestico', 'poda_galhos', 'entulho_ensacado', 'eletronicos') NOT NULL,
    quantidade_itens INT DEFAULT 1,
    descricao_itens TEXT NOT NULL,
    foto_itens_url TEXT,
    data_agendada DATE NOT NULL,
    turno_preferencial ENUM('manha', 'tarde') DEFAULT 'manha',
    logradouro VARCHAR(200) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    bairro VARCHAR(100) NOT NULL,
    referencia VARCHAR(200),
    status ENUM('agendado', 'em_rota', 'recolhido', 'cancelado') DEFAULT 'agendado',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- --------------------------------------------------------------------
-- 5. TABELA DE ORDENS DE SERVIÇO (Operação da Empresa Coletora)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ordens_servico (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_os VARCHAR(30) UNIQUE NOT NULL,
    tipo_origem ENUM('denuncia', 'agendamento_volumoso', 'preventiva') NOT NULL,
    referencia_id INT NOT NULL,
    empresa_id INT,
    veiculo_placa VARCHAR(10),
    equipe_nome VARCHAR(100),
    prioridade ENUM('baixa', 'media', 'alta', 'urgente') DEFAULT 'media',
    status ENUM('pendente', 'despachada', 'em_deslocamento', 'concluida', 'impossibilitada') DEFAULT 'pendente',
    data_abertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_conclusao TIMESTAMP NULL,
    tempo_resolucao_horas DECIMAL(6, 2) NULL,
    observacoes_operacionais TEXT,
    FOREIGN KEY (empresa_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- --------------------------------------------------------------------
-- 6. TABELA DE COMPROVAÇÃO DE ATENDIMENTO (Foto Antes e Foto Depois)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS comprovantes_atendimento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ordem_servico_id INT NOT NULL,
    foto_antes_url TEXT NOT NULL,
    foto_depois_url TEXT NOT NULL,
    peso_coletado_kg DECIMAL(10, 2) NOT NULL,
    destino_final VARCHAR(150) NOT NULL, -- Ex: Cooperativa Renascer, CTR Maceió
    encarregado_nome VARCHAR(150) NOT NULL,
    assinado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ordem_servico_id) REFERENCES ordens_servico(id) ON DELETE CASCADE
);

-- --------------------------------------------------------------------
-- 7. TABELA DE CRONOGRAMA DE COLETA POR BAIRRO
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cronograma_bairros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bairro VARCHAR(100) NOT NULL,
    dias_coleta_domiciliar VARCHAR(100) NOT NULL, -- Ex: Segundas, Quartas e Sextas
    turno_domiciliar VARCHAR(50) NOT NULL,        -- Ex: Noturno (a partir das 19h)
    dias_coleta_seletiva VARCHAR(100) NOT NULL,   -- Ex: Terças e Quintas
    turno_seletiva VARCHAR(50) NOT NULL,          -- Ex: Matutino (08h às 12h)
    rota_cata_treco VARCHAR(150) NOT NULL,        -- Ex: 2º e 4º Sábados do mês
    ponto_referencia_ecoponto VARCHAR(150)
);

-- --------------------------------------------------------------------
-- DADOS INICIAIS DE TESTE / SEED (Maceió - AL)
-- --------------------------------------------------------------------
INSERT INTO usuarios (nome, email, senha_hash, perfil, bairro) VALUES
('Ana Luiza Silva', 'cidadao@ecociclo.com.br', '$2y$10$demoHashCidadao1234567890', 'cidadao', 'Pajuçara'),
('EcoLimp Maceió Serviços Urbanos', 'operacao@ecolimp.com.br', '$2y$10$demoHashColetora123456789', 'empresa_coleta', 'Centro'),
('Secretaria de Meio Ambiente (Prefeitura)', 'gestao@maceio.al.gov.br', '$2y$10$demoHashGov1234567890123', 'prefeitura', 'Jaraguá');

INSERT INTO ecopontos (nome, logradouro, numero, bairro, latitude, longitude, materiais_aceitos, horario_funcionamento) VALUES
('Ecoponto Pajuçara', 'Av. Dr. Antônio Gouveia', '450', 'Pajuçara', -9.6698, -35.7175, 'Papel, Plástico, Vidro, Metais, Óleo de Cozinha', 'Seg a Sáb: 07h às 17h'),
('Ecoponto Jatiúca', 'Av. Álvaro Otacílio', '1250', 'Jatiúca', -9.6508, -35.7032, 'Entulho ensacado, Móveis, Poda, Eletrônicos', 'Seg a Sex: 08h às 18h, Sáb: 08h às 14h'),
('Ecoponto Centro - Praça Sinimbu', 'Rua Barão de Penedo', '120', 'Centro', -9.6658, -35.7353, 'Papelão, Plástico PET, Vidro, Pilhas e Baterias', 'Seg a Sex: 08h às 17h'),
('Ecoponto Farol - Mirante', 'Av. Fernandes Lima', '1800', 'Farol', -9.6480, -35.7360, 'Móveis velhos, Madeiras, Eletrônicos, Recicláveis', 'Seg a Sáb: 07h às 19h'),
('Ecoponto Jacintinho', 'Av. Cleto Campelo', '300', 'Jacintinho', -9.6410, -35.7230, 'Entulho, Poda de árvores, Móveis, Sucatas', 'Seg a Sáb: 08h às 17h'),
('Ecoponto Benedito Bentes', 'Av. Cachoeira do Meirim', '780', 'Benedito Bentes', -9.5780, -35.7480, 'Entulho até 1m³, Eletrodomésticos, Poda, Recicláveis', 'Seg a Sáb: 07h às 17h');

INSERT INTO cronograma_bairros (bairro, dias_coleta_domiciliar, turno_domiciliar, dias_coleta_seletiva, turno_seletiva, rota_cata_treco) VALUES
('Pajuçara', 'Segundas, Quartas e Sextas', 'Noturno (19h)', 'Terças e Quintas', 'Matutino (08h às 12h)', '1º e 3º Sábado'),
('Ponta Verde', 'Segundas, Quartas e Sextas', 'Noturno (19h)', 'Terças e Quintas', 'Vespertino (13h às 17h)', '1º e 3º Sábado'),
('Jatiúca', 'Terças, Quintas e Sábados', 'Noturno (19h)', 'Quartas e Sextas', 'Matutino (08h às 12h)', '2º e 4º Sábado'),
('Centro', 'Diariamente (Seg a Sáb)', 'Noturno (20h)', 'Segundas, Quartas e Sextas', 'Matutino (07h às 11h)', 'Todo Sábado'),
('Farol', 'Segundas, Quartas e Sextas', 'Diurno (07h)', 'Terças e Quintas', 'Matutino (08h às 12h)', '2º Sábado'),
('Jacintinho', 'Terças, Quintas e Sábados', 'Diurno (07h)', 'Quartas-feiras', 'Matutino (08h às 12h)', '3º Sábado'),
('Benedito Bentes', 'Segundas, Quartas e Sextas', 'Diurno (07h)', 'Sábados', 'Matutino (08h às 12h)', '4º Sábado');

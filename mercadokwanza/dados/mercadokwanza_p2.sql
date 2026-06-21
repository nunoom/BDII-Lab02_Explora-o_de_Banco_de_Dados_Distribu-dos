-- =====================================================================
--  MercadoKwanza — Dataset da PARTE 2 (Cenário A: Replicação + Fragmentação)
--  Base de Dados II | ISPTEC | Lab #02 | Grupo 1 | Turma M1
--  Alvo: MySQL 8.0 — executar APENAS no Master (no-luanda); replica para os Slaves.
--  Depende de: mercadokwanza_p1.sql (schema + dados base).
-- =====================================================================
USE mercadokwanza;

-- ── PASSO 25: Expansão do catálogo — +50 produtos angolanos (9 categorias) ──
INSERT INTO PRODUTO (descricao, categoria, preco, activo) VALUES
-- Alimentação (10)
('Fuba de Milho Boa Safra 5kg',          'Alimentação', 4200.00, 1),
('Funge de Bombó Tradicional 2kg',       'Alimentação', 3100.00, 1),
('Feijão Catarino Premium 5kg',          'Alimentação', 6800.00, 1),
('Arroz Agulha Tio Lucas 25kg',          'Alimentação', 18500.00, 1),
('Óleo de Palma Dendém 1L',              'Alimentação', 2700.00, 1),
('Gimboa Fresca Embalada 500g',          'Alimentação', 950.00, 1),
('Jindungo Moído Picante 200g',          'Alimentação', 1300.00, 1),
('Quizaca Seca 300g',                    'Alimentação', 1150.00, 1),
('Peixe Carapau Congelado 2kg',          'Alimentação', 5400.00, 1),
('Farinha de Mandioca Quissangue 5kg',   'Alimentação', 3950.00, 1),
-- Bebidas (8)
('Cerveja Cuca Lata 33cl Pack 6',        'Bebidas', 4500.00, 1),
('Cerveja Nocal Garrafa 33cl Pack 6',    'Bebidas', 4300.00, 1),
('Refrigerante Blue Tropical 1.5L',      'Bebidas', 1200.00, 1),
('Água Pura Mineral 1.5L Pack 6',        'Bebidas', 2100.00, 1),
('Sumo Compal Manga 1L',                 'Bebidas', 1450.00, 1),
('Vinho Tinto Caves do Cunene 75cl',     'Bebidas', 8900.00, 1),
('Whisky Importado 70cl',                'Bebidas', 32000.00, 1),
('Refresco Pajumbo Ananás 2L',           'Bebidas', 1600.00, 1),
-- Higiene (6)
('Sabonete Protex Original Pack 4',      'Higiene', 2300.00, 1),
('Pasta de Dentes Sorriso 90g',          'Higiene', 1100.00, 1),
('Champô Sedoso Cabelo Crespo 400ml',    'Higiene', 3400.00, 1),
('Fraldas Bebé Macio Tam.4 Pack 30',     'Higiene', 7800.00, 1),
('Papel Higiénico Suave Pack 12',        'Higiene', 4100.00, 1),
('Desodorizante Roll-on 50ml',           'Higiene', 1850.00, 1),
-- Limpeza (5)
('Detergente Roupa Omo 3kg',             'Limpeza', 6200.00, 1),
('Lixívia Clorox 2L',                    'Limpeza', 1400.00, 1),
('Esfregão Família Pack 5',              'Limpeza', 980.00, 1),
('Sabão Azul e Branco Barra Pack 6',     'Limpeza', 2600.00, 1),
('Detergente Loiça Limpa Tudo 1L',       'Limpeza', 1700.00, 1),
-- Electrónica (7)
('Telemóvel Smart Lite 64GB',            'Electrónica', 78500.00, 1),
('Powerbank 20000mAh',                   'Electrónica', 24500.00, 1),
('Auriculares Bluetooth Pro',            'Electrónica', 31200.00, 1),
('Carregador USB-C Rápido 25W',          'Electrónica', 9800.00, 1),
('Lâmpada LED Solar Recarregável',       'Electrónica', 6700.00, 1),
('Rádio Portátil FM/USB',                'Electrónica', 14300.00, 1),
('Ventoinha de Mesa 16 polegadas',       'Electrónica', 27800.00, 1),
-- Vestuário (5)
('Camisa Tradicional Pano Africano M',   'Vestuário', 12500.00, 1),
('Chinelo Havaiana Adulto',              'Vestuário', 4200.00, 1),
('T-shirt Algodão Unissexo L',           'Vestuário', 5600.00, 1),
('Pano Samakaka 6 Jardas',               'Vestuário', 18900.00, 1),
('Boné Desportivo Ajustável',            'Vestuário', 3800.00, 1),
-- Papelaria (4)
('Caderno Pautado A4 200 folhas',        'Papelaria', 2400.00, 1),
('Pack 12 Esferográficas Azuis',         'Papelaria', 1300.00, 1),
('Resma Papel A4 80g 500 folhas',        'Papelaria', 6900.00, 1),
('Mochila Escolar Reforçada',            'Papelaria', 15600.00, 1),
-- Casa & Construção (5)
('Panela de Alumínio Grande 30cm',       'Casa', 8700.00, 1),
('Balde Plástico 20L',                   'Casa', 2200.00, 1),
('Saco de Cimento Nova Cimangola 50kg',  'Construção', 9500.00, 1),
('Chapa de Zinco Ondulada 2m',           'Construção', 13400.00, 1),
('Tinta Plástica Branca 5L',             'Construção', 16800.00, 1);

-- ── PASSO 28: Views de fragmentação horizontal de STOCK por província ──
CREATE OR REPLACE VIEW frag_stock_luanda AS
  SELECT s.* FROM STOCK s JOIN LOJA l ON s.loja_id = l.id WHERE l.provincia_id = 1;

CREATE OR REPLACE VIEW frag_stock_benguela AS
  SELECT s.* FROM STOCK s JOIN LOJA l ON s.loja_id = l.id WHERE l.provincia_id = 2;

-- Verificação da distribuição dos fragmentos:
SELECT 'Luanda'   AS prov, SUM(quantidade) AS stock_total FROM frag_stock_luanda
UNION ALL
SELECT 'Benguela' AS prov, SUM(quantidade) AS stock_total FROM frag_stock_benguela;

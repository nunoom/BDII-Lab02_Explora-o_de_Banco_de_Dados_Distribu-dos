-- =====================================================================
--  MercadoKwanza — Dataset DETERMINÍSTICO para Banco de Dados Distribuído
--  Base de Dados II | ISPTEC | Lab #02
--  Alvo: MySQL 8.0   |   Executar com:  SOURCE mercadokwanza.sql
-- ---------------------------------------------------------------------
--  DETERMINISMO TOTAL:
--    * Não usa RAND() nem NOW(). Todos os valores "aleatórios" são
--      derivados por hash MD5 do índice da linha + uma semente fixa,
--      através da função det_rand(). O resultado é IDÊNTICO em
--      qualquer máquina e em qualquer execução (mesmos COUNT, mesmos
--      dados, mesmos CHECKSUM TABLE).
--    * Para gerar um dataset DIFERENTE (ex.: Parte 2), basta alterar
--      a string da semente dentro da função det_rand() (ver abaixo).
-- ---------------------------------------------------------------------
--  Volumes (fixos e reprodutíveis):
--    PROVINCIA 3 | LOJA 15 | PRODUTO 200 | STOCK 3000
--    CLIENTE 5000 | VENDA 30000 | ITEM_VENDA (determinístico, ~90000)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Recriar o schema do zero (idempotente)
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS mercadokwanza;
CREATE DATABASE mercadokwanza
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE mercadokwanza;

-- ---------------------------------------------------------------------
-- 1. Estrutura das tabelas (DDL)
--    PK com AUTO_INCREMENT, FKs e índices nas colunas mais filtradas.
--    Nota: TINYINT (sem largura) para evitar o aviso 1681 do MySQL 8.
-- ---------------------------------------------------------------------

CREATE TABLE PROVINCIA (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(60)  NOT NULL,
    capital    VARCHAR(60)  NOT NULL,
    populacao  INT          NOT NULL
) ENGINE=InnoDB;

CREATE TABLE LOJA (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(120) NOT NULL,
    provincia_id INT          NOT NULL,
    morada       VARCHAR(200) NOT NULL,
    activa       TINYINT      NOT NULL DEFAULT 1,
    CONSTRAINT fk_loja_provincia
        FOREIGN KEY (provincia_id) REFERENCES PROVINCIA(id),
    INDEX idx_loja_provincia (provincia_id)
) ENGINE=InnoDB;

CREATE TABLE PRODUTO (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    descricao  VARCHAR(150)   NOT NULL,
    categoria  VARCHAR(40)    NOT NULL,
    preco      DECIMAL(12,2)  NOT NULL,
    activo     TINYINT        NOT NULL DEFAULT 1,
    INDEX idx_produto_categoria (categoria),
    INDEX idx_produto_activo (activo)
) ENGINE=InnoDB;

CREATE TABLE STOCK (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    produto_id    INT       NOT NULL,
    loja_id       INT       NOT NULL,
    quantidade    INT       NOT NULL DEFAULT 0,
    atualizado_em DATETIME  NOT NULL,
    CONSTRAINT fk_stock_produto
        FOREIGN KEY (produto_id) REFERENCES PRODUTO(id),
    CONSTRAINT fk_stock_loja
        FOREIGN KEY (loja_id) REFERENCES LOJA(id),
    UNIQUE KEY uq_stock_prod_loja (produto_id, loja_id),
    INDEX idx_stock_loja (loja_id)
) ENGINE=InnoDB;

CREATE TABLE CLIENTE (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(120) NOT NULL,
    nif          VARCHAR(20)  NOT NULL,
    provincia_id INT          NOT NULL,
    telefone     VARCHAR(20),
    activo       TINYINT      NOT NULL DEFAULT 1,
    CONSTRAINT fk_cliente_provincia
        FOREIGN KEY (provincia_id) REFERENCES PROVINCIA(id),
    UNIQUE KEY uq_cliente_nif (nif),
    INDEX idx_cliente_provincia (provincia_id)
) ENGINE=InnoDB;

CREATE TABLE VENDA (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    loja_id     INT           NOT NULL,
    cliente_id  INT           NOT NULL,
    data_venda  DATETIME      NOT NULL,
    total       DECIMAL(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_venda_loja
        FOREIGN KEY (loja_id) REFERENCES LOJA(id),
    CONSTRAINT fk_venda_cliente
        FOREIGN KEY (cliente_id) REFERENCES CLIENTE(id),
    INDEX idx_venda_loja (loja_id),
    INDEX idx_venda_cliente (cliente_id),
    INDEX idx_venda_data (data_venda)
) ENGINE=InnoDB;

CREATE TABLE ITEM_VENDA (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    venda_id   INT           NOT NULL,
    produto_id INT           NOT NULL,
    qtd        INT           NOT NULL,
    preco_unit DECIMAL(12,2) NOT NULL,
    desconto   DECIMAL(4,2)  NOT NULL DEFAULT 0,
    CONSTRAINT fk_item_venda
        FOREIGN KEY (venda_id) REFERENCES VENDA(id),
    CONSTRAINT fk_item_produto
        FOREIGN KEY (produto_id) REFERENCES PRODUTO(id),
    INDEX idx_item_venda (venda_id),
    INDEX idx_item_produto (produto_id)
) ENGINE=InnoDB;

-- =====================================================================
-- 2. Função geradora determinística
--    det_rand(chave) -> DOUBLE em [0,1), função PURA da chave+semente.
--    Declarada DETERMINISTIC NO SQL para poder ser criada mesmo com
--    binary logging activo (caso do nó Master no docker-compose).
--
--    >>> SEMENTE: para a Parte 2, mudar 'MK-SEED-P1-2026' para outra
--        string (ex.: 'MK-SEED-P2-2026') e todo o dataset muda de forma
--        determinística. <<<
-- =====================================================================
DROP FUNCTION IF EXISTS det_rand;
CREATE FUNCTION det_rand(p_key VARCHAR(255))
    RETURNS DOUBLE
    DETERMINISTIC
    NO SQL
    RETURN CONV(SUBSTRING(MD5(CONCAT('MK-SEED-P1-2026:', p_key)), 1, 8), 16, 10) / 4294967296.0;

-- =====================================================================
-- 3. Procedimentos de povoamento (stored procedures com loops WHILE)
-- =====================================================================
DELIMITER $$

-- ---- 3.1 Províncias (dados fixos) ----------------------------------
DROP PROCEDURE IF EXISTS sp_seed_provincias $$
CREATE PROCEDURE sp_seed_provincias()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 3 DO
        INSERT INTO PROVINCIA (nome, capital, populacao) VALUES (
            ELT(i, 'Luanda', 'Benguela', 'Huambo'),
            ELT(i, 'Luanda', 'Benguela', 'Huambo'),
            ELT(i, 9079800, 2509950, 2641000)
        );
        SET i = i + 1;
    END WHILE;
END $$

-- ---- 3.2 Lojas (5 por província) -----------------------------------
DROP PROCEDURE IF EXISTS sp_seed_lojas $$
CREATE PROCEDURE sp_seed_lojas()
BEGIN
    DECLARE prov INT DEFAULT 1;
    DECLARE s    INT;
    DECLARE v_rua    VARCHAR(80);
    DECLARE v_bairro VARCHAR(60);
    DECLARE v_np     VARCHAR(40);
    DECLARE kbase    VARCHAR(40);
    WHILE prov <= 3 DO
        SET v_np = ELT(prov, 'Luanda', 'Benguela', 'Huambo');
        SET s = 1;
        WHILE s <= 5 DO
            SET kbase = CONCAT('loja-', prov, '-', s);
            SET v_rua = CASE prov
                WHEN 1 THEN ELT(1+FLOOR(det_rand(CONCAT(kbase,'-rua'))*8),
                    'Rua Rainha Ginga','Avenida 4 de Fevereiro','Largo do Kinaxixi',
                    'Rua Amílcar Cabral','Avenida Deolinda Rodrigues','Avenida Hoji ya Henda',
                    'Rua Comandante Gika','Avenida Lenine')
                WHEN 2 THEN ELT(1+FLOOR(det_rand(CONCAT(kbase,'-rua'))*6),
                    'Avenida Norton de Matos','Rua Sá da Bandeira','Largo 4 de Abril',
                    'Avenida 10 de Dezembro','Rua do Comércio','Rua Eça de Queirós')
                ELSE ELT(1+FLOOR(det_rand(CONCAT(kbase,'-rua'))*6),
                    'Avenida da República','Rua José Martí','Avenida Norton de Matos',
                    'Rua das Acácias','Rua Cónego Manuel das Neves','Avenida Sanjango')
            END;
            SET v_bairro = CASE prov
                WHEN 1 THEN ELT(1+FLOOR(det_rand(CONCAT(kbase,'-bai'))*5),'Maianga','Alvalade','Ingombota','Rangel','Viana')
                WHEN 2 THEN ELT(1+FLOOR(det_rand(CONCAT(kbase,'-bai'))*4),'Compão','Graça','Centro','Restinga')
                ELSE         ELT(1+FLOOR(det_rand(CONCAT(kbase,'-bai'))*4),'São João','Calundo','Centro','Benfica')
            END;
            INSERT INTO LOJA (nome, provincia_id, morada, activa) VALUES (
                CONCAT('MercadoKwanza ', v_np, ' #', LPAD(s,2,'0')),
                prov,
                CONCAT(v_rua, ', nº ', 1+FLOOR(det_rand(CONCAT(kbase,'-num'))*250), ', ', v_bairro, ' - ', v_np),
                IF(det_rand(CONCAT(kbase,'-act')) < 0.10, 0, 1)
            );
            SET s = s + 1;
        END WHILE;
        SET prov = prov + 1;
    END WHILE;
END $$

-- ---- 3.3 Produtos (200, 5 categorias) ------------------------------
DROP PROCEDURE IF EXISTS sp_seed_produtos $$
CREATE PROCEDURE sp_seed_produtos()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE v_cat   VARCHAR(40);
    DECLARE v_base  VARCHAR(80);
    DECLARE v_var   VARCHAR(30);
    DECLARE v_preco DECIMAL(12,2);
    DECLARE catidx  INT;
    DECLARE k       VARCHAR(40);
    WHILE i <= 200 DO
        SET catidx = ((i - 1) % 5) + 1;        -- distribuição uniforme pelas 5 categorias
        SET k      = CONCAT('prod-', i);
        SET v_cat  = ELT(catidx, 'Alimentação','Higiene','Electrónica','Vestuário','Ferragens');
        SET v_base = CASE catidx
            WHEN 1 THEN ELT(1+FLOOR(det_rand(CONCAT(k,'-base'))*12),'Arroz Precioso','Feijão Catarino','Óleo Fula','Açúcar Cristal',
                            'Fubá de Milho','Massa Esparguete','Leite em Pó Nido','Sardinha em Lata',
                            'Sal Refinado','Café Ginga','Bolacha Maria','Sumo Compal')
            WHEN 2 THEN ELT(1+FLOOR(det_rand(CONCAT(k,'-base'))*12),'Sabão Azul','Sabonete Lux','Pasta de Dentes','Champô Sunsilk',
                            'Detergente Omo','Papel Higiénico','Fralda Dodot','Desodorizante',
                            'Gel de Banho','Lixívia','Esfregão','Toalhitas')
            WHEN 3 THEN ELT(1+FLOOR(det_rand(CONCAT(k,'-base'))*12),'Telemóvel Samsung','Carregador USB-C','Auriculares','Coluna Bluetooth',
                            'Powerbank 10000mAh','Televisor LED 32"','Rádio Portátil','Ventoinha de Pé',
                            'Lâmpada LED','Cabo HDMI','Pen Drive 32GB','Rato Sem Fios')
            WHEN 4 THEN ELT(1+FLOOR(det_rand(CONCAT(k,'-base'))*12),'Camisa Social','Calça Jeans','Vestido Capulana','T-shirt Algodão',
                            'Sapatilha Desportiva','Chinelo de Dedo','Boné','Casaco Ganga',
                            'Saia Plissada','Meias (par)','Cinto de Couro','Sandália')
            ELSE      ELT(1+FLOOR(det_rand(CONCAT(k,'-base'))*12),'Martelo 500g','Chave de Fendas','Caixa de Pregos','Tinta Acrílica 5L',
                            'Fita Métrica 5m','Berbequim','Alicate Universal','Caixa de Parafusos',
                            'Serrote','Cadeado','Mangueira 20m','Pá de Bico')
        END;
        SET v_var = CASE catidx
            WHEN 1 THEN ELT(1+FLOOR(det_rand(CONCAT(k,'-var'))*6),'500g','1kg','2kg','5kg','1L','Pack 6')
            WHEN 2 THEN ELT(1+FLOOR(det_rand(CONCAT(k,'-var'))*6),'250ml','500ml','1L','Pack','Família','Económico')
            WHEN 3 THEN ELT(1+FLOOR(det_rand(CONCAT(k,'-var'))*6),'Lite','Pro','Plus','Mini','2024','Mod. X1')
            WHEN 4 THEN ELT(1+FLOOR(det_rand(CONCAT(k,'-var'))*6),'S','M','L','XL','Único','Slim')
            ELSE         ELT(1+FLOOR(det_rand(CONCAT(k,'-var'))*6),'Pequeno','Médio','Grande','Pro','Kit','Reforçado')
        END;
        SET v_preco = CASE catidx
            WHEN 1 THEN ROUND(150  + det_rand(CONCAT(k,'-prc'))*7850 , 2)
            WHEN 2 THEN ROUND(200  + det_rand(CONCAT(k,'-prc'))*5800 , 2)
            WHEN 3 THEN ROUND(3000 + det_rand(CONCAT(k,'-prc'))*247000,2)
            WHEN 4 THEN ROUND(1500 + det_rand(CONCAT(k,'-prc'))*38500, 2)
            ELSE         ROUND(500  + det_rand(CONCAT(k,'-prc'))*79500, 2)
        END;
        INSERT INTO PRODUTO (descricao, categoria, preco, activo) VALUES (
            CONCAT(v_base, ' ', v_var, ' Ref.', LPAD(i,3,'0')),
            v_cat,
            v_preco,
            IF(det_rand(CONCAT(k,'-act')) < 0.08, 0, 1)
        );
        SET i = i + 1;
    END WHILE;
END $$

-- ---- 3.4 Stock (200 x 15 = 3000) -----------------------------------
--      atualizado_em ancorado a uma data FIXA (não NOW()) p/ determinismo.
DROP PROCEDURE IF EXISTS sp_seed_stock $$
CREATE PROCEDURE sp_seed_stock()
BEGIN
    DECLARE p INT DEFAULT 1;
    DECLARE l INT;
    DECLARE k VARCHAR(40);
    WHILE p <= 200 DO
        SET l = 1;
        WHILE l <= 15 DO
            SET k = CONCAT('stk-', p, '-', l);
            INSERT INTO STOCK (produto_id, loja_id, quantidade, atualizado_em) VALUES (
                p, l,
                FLOOR(det_rand(CONCAT(k,'-q'))*501),
                DATE_SUB('2024-12-31 12:00:00', INTERVAL FLOOR(det_rand(CONCAT(k,'-d'))*60) DAY)
            );
            SET l = l + 1;
        END WHILE;
        SET p = p + 1;
    END WHILE;
END $$

-- ---- 3.5 Clientes (5000) -------------------------------------------
DROP PROCEDURE IF EXISTS sp_seed_clientes $$
CREATE PROCEDURE sp_seed_clientes()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE v_prim VARCHAR(40);
    DECLARE v_apel VARCHAR(40);
    DECLARE v_prov INT;
    DECLARE r DOUBLE;
    DECLARE k VARCHAR(40);
    WHILE i <= 5000 DO
        SET k = CONCAT('cli-', i);
        SET v_prim = ELT(1+FLOOR(det_rand(CONCAT(k,'-pri'))*30),
            'João','José','António','Manuel','Pedro','Domingos','Mateus','Joaquim','Augusto','Eduardo',
            'Ana','Maria','Joana','Esperança','Domingas','Luzia','Teresa','Isabel','Helena','Rosa',
            'Carlos','Paulo','Fernando','Miguel','Nelson','Beatriz','Catarina','Filomena','Júlia','Natália');
        SET v_apel = ELT(1+FLOOR(det_rand(CONCAT(k,'-ape'))*30),
            'dos Santos','Domingos','Fernandes','da Silva','Neto','Cabral','Mukinda','Kiluanje','Sebastião','Capitango',
            'Quiluange','Mbala','Cassoma','Ferraz','Lukau','Kalandula','Pacheco','Gourgel','Nzinga','Kamuanga',
            'Sumbula','Tchikuteny','Chivukuvuku','Bengui','Manuel','António','Pedro','Eduardo','Vunge','Sapalo');
        SET r = det_rand(CONCAT(k,'-prov'));
        SET v_prov = IF(r < 0.50, 1, IF(r < 0.80, 2, 3));   -- 50% Luanda, 30% Benguela, 20% Huambo
        INSERT INTO CLIENTE (nome, nif, provincia_id, telefone, activo) VALUES (
            CONCAT(v_prim, ' ', v_apel),
            CONCAT(LPAD(i,9,'0'),'LA', LPAD(i % 1000, 3, '0')),   -- NIF determinístico e único
            v_prov,
            CONCAT('+2449', LPAD(FLOOR(det_rand(CONCAT(k,'-tel'))*100000000), 8, '0')),
            IF(det_rand(CONCAT(k,'-act')) < 0.05, 0, 1)
        );
        SET i = i + 1;
    END WHILE;
END $$

-- ---- 3.6 Vendas (30000) + Itens (2 a 4 por venda) ------------------
DROP PROCEDURE IF EXISTS sp_seed_vendas $$
CREATE PROCEDURE sp_seed_vendas(IN p_n INT)
BEGIN
    DECLARE v INT DEFAULT 1;
    DECLARE n_itens INT;
    DECLARE kk INT;
    DECLARE v_loja INT;
    DECLARE v_cli  INT;
    DECLARE v_prod INT;
    DECLARE v_qtd  INT;
    DECLARE v_desc DECIMAL(4,2);
    DECLARE v_preco DECIMAL(12,2);
    DECLARE v_total DECIMAL(14,2);
    DECLARE v_data  DATETIME;
    DECLARE kv VARCHAR(40);
    DECLARE ki VARCHAR(50);

    WHILE v <= p_n DO
        SET kv      = CONCAT('vnd-', v);
        SET v_loja  = 1 + FLOOR(det_rand(CONCAT(kv,'-loja'))*15);
        SET v_cli   = 1 + FLOOR(det_rand(CONCAT(kv,'-cli'))*5000);
        SET v_data  = DATE_ADD(
                          DATE_ADD('2023-01-01 00:00:00', INTERVAL FLOOR(det_rand(CONCAT(kv,'-dia'))*730) DAY),
                          INTERVAL FLOOR(det_rand(CONCAT(kv,'-seg'))*86400) SECOND);
        SET n_itens = 2 + FLOOR(det_rand(CONCAT(kv,'-nit'))*3);      -- 2, 3 ou 4 itens
        SET v_total = 0;
        SET kk = 1;

        WHILE kk <= n_itens DO
            SET ki     = CONCAT(kv, '-it-', kk);
            SET v_prod = 1 + FLOOR(det_rand(CONCAT(ki,'-prod'))*200);
            SET v_qtd  = 1 + FLOOR(det_rand(CONCAT(ki,'-qtd'))*10);
            SELECT preco INTO v_preco FROM PRODUTO WHERE id = v_prod;
            SET v_desc = IF(det_rand(CONCAT(ki,'-df')) < 0.30, ROUND(det_rand(CONCAT(ki,'-dv'))*0.15, 2), 0.00);
            SET v_total = v_total + ROUND(v_qtd * v_preco * (1 - v_desc), 2);
            INSERT INTO ITEM_VENDA (venda_id, produto_id, qtd, preco_unit, desconto)
                 VALUES (v, v_prod, v_qtd, v_preco, v_desc);   -- venda_id explícito (= v)
            SET kk = kk + 1;
        END WHILE;

        INSERT INTO VENDA (id, loja_id, cliente_id, data_venda, total)
             VALUES (v, v_loja, v_cli, v_data, v_total);

        IF v % 2000 = 0 THEN
            COMMIT;
        END IF;
        SET v = v + 1;
    END WHILE;
    COMMIT;
END $$

DELIMITER ;

-- =====================================================================
-- 4. Execução do povoamento
--    FK/unique checks desligados durante a carga em massa (mais rápido
--    e permite inserir os itens antes da venda com venda_id explícito).
-- =====================================================================
SET autocommit = 0;
SET unique_checks = 0;
SET foreign_key_checks = 0;

CALL sp_seed_provincias();
CALL sp_seed_lojas();
CALL sp_seed_produtos();
CALL sp_seed_stock();
CALL sp_seed_clientes();
COMMIT;

CALL sp_seed_vendas(30000);
COMMIT;

SET foreign_key_checks = 1;
SET unique_checks = 1;
SET autocommit = 1;

-- =====================================================================
-- 5. Limpeza dos auxiliares (opcional)
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_seed_provincias;
DROP PROCEDURE IF EXISTS sp_seed_lojas;
DROP PROCEDURE IF EXISTS sp_seed_produtos;
DROP PROCEDURE IF EXISTS sp_seed_stock;
DROP PROCEDURE IF EXISTS sp_seed_clientes;
DROP PROCEDURE IF EXISTS sp_seed_vendas;
DROP FUNCTION  IF EXISTS det_rand;

-- =====================================================================
-- 6. Verificação final — contagens
-- =====================================================================
SELECT 'PROVINCIA'  AS tabela, COUNT(*) AS total FROM PROVINCIA
UNION ALL SELECT 'LOJA',       COUNT(*) FROM LOJA
UNION ALL SELECT 'PRODUTO',    COUNT(*) FROM PRODUTO
UNION ALL SELECT 'STOCK',      COUNT(*) FROM STOCK
UNION ALL SELECT 'CLIENTE',    COUNT(*) FROM CLIENTE
UNION ALL SELECT 'VENDA',      COUNT(*) FROM VENDA
UNION ALL SELECT 'ITEM_VENDA', COUNT(*) FROM ITEM_VENDA;
-- =====================================================================
-- FIM
-- =====================================================================

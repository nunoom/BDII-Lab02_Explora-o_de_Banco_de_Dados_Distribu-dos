-- ════════════════════════════════════════════════════════════════════
--  MercadoKwanza — Configuração da Replicação MySQL Master-Slave
--  Base de Dados II | ISPTEC | Lab #02 | Grupo 1 | Turma M1
--
--  Topologia:
--    Master  : no-luanda   (server-id=1, log-bin activo)
--    Slaves  : no-benguela (server-id=2), no-huambo (server-id=3)
--  Replicação assíncrona por posição de binlog (não-GTID).
-- ════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────
-- PASSO 1 — No MASTER (no-luanda): criar utilizador de replicação
--   docker exec -it no-luanda mysql -uroot -pkwanza2024
-- ─────────────────────────────────────────────────────────────────
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl2024';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;

-- Anotar o ficheiro e a posição do binlog (necessários no passo 2):
SHOW MASTER STATUS;
--   Ex.: File = mysql-bin.000003 | Position = 1867


-- ─────────────────────────────────────────────────────────────────
-- PASSO 2 — Em CADA SLAVE (no-benguela e no-huambo): apontar ao Master
--   docker exec -it no-benguela mysql -uroot -pkwanza2024
--   docker exec -it no-huambo   mysql -uroot -pkwanza2024
--
-- Substituir SOURCE_LOG_FILE / SOURCE_LOG_POS pelos valores do SHOW MASTER STATUS.
-- ─────────────────────────────────────────────────────────────────
STOP REPLICA;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST     = 'no-luanda',
    SOURCE_PORT     = 3306,
    SOURCE_USER     = 'repl',
    SOURCE_PASSWORD = 'repl2024',
    SOURCE_LOG_FILE = 'mysql-bin.000003',
    SOURCE_LOG_POS  = 1867;

START REPLICA;


-- ─────────────────────────────────────────────────────────────────
-- PASSO 3 — Verificação (em cada Slave). Confirmar:
--   Replica_IO_Running:  Yes
--   Replica_SQL_Running: Yes
--   Seconds_Behind_Source: 0
-- ─────────────────────────────────────────────────────────────────
SHOW REPLICA STATUS\G

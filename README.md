# bdd2-lab02-grupo1 — MercadoKwanza (Bases de Dados Distribuídas)

Laboratório #02 de **Base de Dados II** (ISPTEC). Simulação de um sistema de bases de dados
distribuído para o retalhista fictício **MercadoKwanza**, com replicação MySQL Master-Slave,
fragmentação horizontal, transações distribuídas (2PC simplificado) e migração para MongoDB.

- **Grupo:** 1 · **Turma:** M1 · **Cenário:** A (Defensor na primeira ronda)
- **Elementos:** Nuno Mendes · Khelv Costa · Rafaela Mendes · Paula Alexandre

## Arquitetura

| Nó | Contentor | Papel | Porta (host) | server-id |
|----|-----------|-------|--------------|-----------|
| Luanda | `no-luanda` | **Master** (escrita) | 3301 | 1 |
| Benguela | `no-benguela` | Slave / Réplica | 3307 | 2 |
| Huambo | `no-huambo` | Slave / Réplica | 3308 | 3 |
| MongoDB | `mongo-kwanza` | NoSQL (migração) | 27017 | — |

## Estrutura do repositório

```
bdd2-lab02-grupo1/
├── README.md                    ← este ficheiro
├── docker-compose.yml           ← configuração do cluster (4 contentores)
├── dados/
│   ├── mercadokwanza_p1.sql     ← dataset base (schema + dados) — Parte 1
│   └── mercadokwanza_p2.sql     ← +50 produtos e views de fragmentação — Parte 2
├── scripts/
│   ├── transacao.py             ← transação distribuída 2PC (Luanda + Benguela)
│   ├── transacao_erro.py        ← variante com erro forçado (demonstra ROLLBACK)
│   ├── migracao.py              ← migração MySQL → MongoDB (documentos)
│   └── replicacao.sql           ← comandos de configuração da replicação Master-Slave
└── relatorio/
    ├── RELATORIO_Lab02.md       ← relatório (fonte)
    └── Lab02_Grupo1.html        ← relatório para impressão → PDF
```

## Como executar

### 1. Subir o cluster
```bash
docker compose up -d
# aguardar ~30-60s até 'docker ps' mostrar os nós 'healthy'
```

> O dataset em `dados/` é carregado automaticamente na primeira inicialização
> (`/docker-entrypoint-initdb.d`). Se mudares a password e der `Access denied`, recria os
> volumes: `docker compose down -v && docker compose up -d`.

### 2. Ligar a um nó
```bash
docker exec -it no-luanda mysql -uroot -pkwanza2024 mercadokwanza
```

### 3. Correr os scripts (Python: `pip install mysql-connector-python pymongo`)
```bash
python scripts/transacao.py        # transação distribuída (sucesso)
python scripts/transacao_erro.py   # demonstra o ROLLBACK em ambos os nós
python scripts/migracao.py         # migra PRODUTO e VENDA para o MongoDB
```

### 4. MySQL Workbench
Host `127.0.0.1` (não `localhost`), portas `3301`/`3307`/`3308`, user `root`, password `kwanza2024`.

## Principais resultados

- **Replicação:** 50 produtos inseridos no Master propagaram aos Slaves em ~119 ms
  (`Seconds_Behind_Source = 0`).
- **Transação 2PC:** o `ROLLBACK` reverteu corretamente ambos os nós perante um erro forçado.
- **Migração MongoDB:** 253 produtos e 30 002 vendas (com itens embebidos) migrados em ~1.3s.

Detalhes completos, tabelas de resultados e análise CAP no relatório (`relatorio/`).

## Conclusões

Não há solução perfeita em sistemas distribuídos: a replicação assíncrona favorece
disponibilidade (mas pode perder dados não replicados numa falha do Master), enquanto o 2PC
favorece consistência (à custa de bloquear/abortar). A escolha depende do que o negócio exige.

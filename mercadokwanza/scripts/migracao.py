#!/usr/bin/env python3
# ════════════════════════════════════════════════════════════════════
#  MercadoKwanza — Migração MySQL → MongoDB
#  Base de Dados II | ISPTEC | Lab #02 | Grupo 1 | Turma M1
#
#  Demonstra a passagem do modelo RELACIONAL (tabelas normalizadas) para
#  o modelo de DOCUMENTOS (NoSQL):
#    - PRODUTO            -> coleção 'produtos'      (1 documento por produto)
#    - VENDA + ITEM_VENDA -> coleção 'vendas'        (itens EMBEBIDOS na venda)
#
#  Dependências:  pip install mysql-connector-python pymongo
#  Execução:      python scripts/migracao.py
# ════════════════════════════════════════════════════════════════════
import time
from collections import defaultdict

import mysql.connector
from pymongo import MongoClient

# ── Configuração das ligações ───────────────────────────────────────
MYSQL = dict(host="127.0.0.1", port=3301, user="root",
             password="kwanza2024", database="mercadokwanza")
MONGO_URI = "mongodb://127.0.0.1:27017/"
MONGO_DB = "mercadokwanza"


def migrar_produtos(cur, db):
    """PRODUTO -> coleção 'produtos' (mapeamento direto, 1:1)."""
    cur.execute("SELECT id, descricao, categoria, preco, activo FROM PRODUTO")
    docs = [
        {
            "_id": pid,
            "descricao": descricao,
            "categoria": categoria,
            "preco": float(preco),
            "activo": bool(activo),
        }
        for (pid, descricao, categoria, preco, activo) in cur.fetchall()
    ]
    db.produtos.drop()
    if docs:
        db.produtos.insert_many(docs)
    return len(docs)


def migrar_vendas(cur, db):
    """VENDA + ITEM_VENDA -> coleção 'vendas' com os itens EMBEBIDOS.

    Em vez de uma tabela separada de itens (modelo relacional), cada venda
    passa a ser um único documento que contém a lista dos seus itens. Isto
    evita JOINs nas leituras — vantagem típica do modelo de documentos.
    """
    # 1) Carregar todos os itens e agrupá-los por venda_id (uma só query).
    cur.execute(
        "SELECT venda_id, produto_id, qtd, preco_unit, desconto FROM ITEM_VENDA"
    )
    itens_por_venda = defaultdict(list)
    for (venda_id, produto_id, qtd, preco_unit, desconto) in cur.fetchall():
        itens_por_venda[venda_id].append(
            {
                "produto_id": produto_id,
                "qtd": qtd,
                "preco_unit": float(preco_unit),
                "desconto": float(desconto),
            }
        )

    # 2) Carregar as vendas e construir um documento por venda.
    cur.execute("SELECT id, loja_id, cliente_id, data_venda, total FROM VENDA")
    docs = [
        {
            "_id": vid,
            "loja_id": loja_id,
            "cliente_id": cliente_id,
            "data_venda": data_venda,
            "total": float(total),
            "itens": itens_por_venda.get(vid, []),
        }
        for (vid, loja_id, cliente_id, data_venda, total) in cur.fetchall()
    ]

    db.vendas.drop()
    # Inserção em lotes para não carregar tudo de uma vez na memória do servidor.
    LOTE = 5000
    for i in range(0, len(docs), LOTE):
        db.vendas.insert_many(docs[i:i + LOTE])
    return len(docs)


def main():
    t0 = time.time()
    conn = mysql.connector.connect(**MYSQL)
    cur = conn.cursor()
    client = MongoClient(MONGO_URI)
    db = client[MONGO_DB]

    try:
        n_prod = migrar_produtos(cur, db)
        print(f"[produtos] migrados: {n_prod} documentos")

        n_vendas = migrar_vendas(cur, db)
        print(f"[vendas]   migradas: {n_vendas} documentos (com itens embebidos)")

        # Índices úteis no modelo de documentos.
        db.produtos.create_index("categoria")
        db.vendas.create_index("loja_id")
        db.vendas.create_index("data_venda")

        print(f"✓ Migração concluída em {time.time() - t0:.2f}s")
        print(f"  Coleções em '{MONGO_DB}': {db.list_collection_names()}")
    finally:
        cur.close()
        conn.close()
        client.close()


if __name__ == "__main__":
    main()

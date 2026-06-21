import mysql.connector
# ── Conectar aos dois nós ──────────────────────────────────────────
def conectar(porta):
    return mysql.connector.connect(
        host='127.0.0.1', port=porta,
        user='root', password='kwanza2024',
        database='mercadokwanza',
        autocommit=False # IMPORTANTE: desactivar autocommit
    )
# ── Cenário: cliente de Luanda compra produto cujo stock está em Benguela
PRODUTO_ID = 5
LOJA_BENGUELA = 6 # loja com provincia_id = 2
LOJA_LUANDA = 1 # loja com provincia_id = 1
CLIENTE_ID = 42
QUANTIDADE = 10
no_luanda = conectar(3301)
no_benguela = conectar(3307)
cur_l = no_luanda.cursor()
cur_b = no_benguela.cursor()
try:
    # ── FASE 1: Verificar e decrementar stock em Benguela ──
    cur_b.execute(
        'SELECT quantidade FROM STOCK WHERE produto_id=%s AND loja_id=%s FOR UPDATE',
        (PRODUTO_ID, LOJA_BENGUELA)
    )
    resultado = cur_b.fetchone()
    if resultado is None or resultado[0] < QUANTIDADE:
        raise Exception(f'Stock insuficiente: disponível={resultado[0] if
        resultado 
    else 0}')
    cur_b.execute(
        'UPDATE STOCK SET quantidade=quantidade-%s WHERE produto_id=%s AND loja_id=%s',
        (QUANTIDADE, PRODUTO_ID, LOJA_BENGUELA)
    )
    print(f'[Benguela] Stock decrementado: -{QUANTIDADE} unidades')
    # ── FASE 2: Registar a venda em Luanda ──
    cur_l.execute(
        'INSERT INTO VENDA (loja_id, cliente_id, data_venda, total) VALUES(%s,%s,NOW(),%s)',
        (LOJA_LUANDA, CLIENTE_ID, QUANTIDADE * 1500) # preço fictício
    )
    venda_id = cur_l.lastrowid
    cur_l.execute(
        'INSERT INTO ITEM_VENDA (venda_id, produto_id, qtd, preco_unit, desconto)'
        ' VALUES (%s,%s,%s,%s,%s)',
        (venda_id, PRODUTO_ID, QUANTIDADE, 1500, 0.0)
    )
    print(f'[Luanda] Venda registada: id={venda_id}')
    # ── COMMIT nos dois nós (2PC simplificado) ──
    no_benguela.commit()
    no_luanda.commit()
    print('✓ Transação concluída com sucesso em ambos os nós.')
except Exception as e:
    # ── ROLLBACK nos dois nós ──
    no_benguela.rollback()
    no_luanda.rollback()
    print(f'✗ ROLLBACK efectuado em ambos os nós. Motivo: {e}')
finally:
    cur_l.close(); cur_b.close()
    no_luanda.close(); no_benguela.close()

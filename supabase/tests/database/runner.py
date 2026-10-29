#!/usr/bin/env python3
# ============================================================================
# F1-T01 — runner.py — executa a suíte RED contra o Supabase remoto
# ----------------------------------------------------------------------------
# Cada bloco marcado com "-- @test:" é uma transação completa: BEGIN ... ROLLBACK.
# Nada persiste. Gera evidência em evidencias/fase-1/spec-1-001-red.txt
#
# Uso:
#   SUPABASE_DB_URL="postgresql://..." python3 runner.py
#
# Alternativa ao runner.sh (psql ausente no ambiente): usa psycopg2.
#
# Nota sobre fixtures: o setup.sql usa IDs fixos e é idempotente. As tabelas
# shadow (organizations, memberships, accounts, icp_versions, contacts,
# import_batches, audit_events) são criadas pelo setup DENTRO do bloco de cada
# teste (o setup inteiro roda na mesma transação do teste, com ROLLBACK).
# ============================================================================
import datetime
import os
import re
import sys
from pathlib import Path

import psycopg2

DIR = Path(__file__).resolve().parent
EVID_DIR = DIR / ".." / ".." / "evidencias" / "fase-1"
EVID_DIR.mkdir(parents=True, exist_ok=True)
OUT = EVID_DIR / "spec-1-001-red.txt"

DB_URL = os.environ.get("SUPABASE_DB_URL")
if not DB_URL:
    print("ERRO: defina SUPABASE_DB_URL (connection string do projeto Supabase).", file=sys.stderr)
    sys.exit(2)

if "sslmode=" not in DB_URL:
    DB_URL += ("&" if "?" in DB_URL else "?") + "sslmode=require"


def resolve_includes(sql: str) -> str:
    """Substitui \\ir arquivo.sql pelo conteúdo do arquivo (mesmo diretório)."""
    out_lines = []
    for line in sql.splitlines():
        s = line.strip()
        if s.startswith("\\ir ") or s.startswith("\\include "):
            inc = s.split(None, 1)[1].strip()
            inc_path = DIR / inc
            out_lines.append(inc_path.read_text(encoding="utf-8"))
        elif s.startswith("\\"):
            continue
        else:
            out_lines.append(line)
    return "\n".join(out_lines)


def extract_blocks(sql: str):
    """Divide o arquivo em blocos: cada um começa em '-- @test:' e termina no próximo."""
    blocks = []
    current_name = None
    current_lines = []
    for line in sql.splitlines():
        m = re.match(r"^--\s*@test:\s*(.+)$", line.strip())
        if m:
            if current_name is not None:
                blocks.append((current_name, "\n".join(current_lines)))
            current_name = m.group(1).strip()
            current_lines = []
        else:
            current_lines.append(line)
    if current_name is not None:
        blocks.append((current_name, "\n".join(current_lines)))
    return blocks


def run():
    conn = psycopg2.connect(DB_URL)
    conn.autocommit = False
    log = []

    def w(s=""):
        log.append(s)
        print(s)

    w("=" * 66)
    w("SUÍTE RED — F1-T01 — SPEC-1-001 (isolamento, matriz M1–M5, auditoria)")
    w(f"Data: {datetime.datetime.now().isoformat()}")
    w("Cada teste roda em transação com ROLLBACK — nada de teste persiste.")
    w("=" * 66)

    test_files = sorted(DIR.glob("[0-9]*_test.sql"))
    total_ok = total_fail = 0

    for tf in test_files:
        w()
        w("=" * 66)
        w(f"TEST FILE: {tf.name}")
        w("=" * 66)
        raw = tf.read_text(encoding="utf-8")
        blocks = extract_blocks(raw)
        if not blocks:
            blocks = [(tf.name, raw)]

        for name, block in blocks:
            block_sql = resolve_includes(block)
            try:
                with conn.cursor() as c:
                    c.execute(block_sql)
                    rows = c.fetchall() if c.description else []
                conn.rollback()
                oks = [r[0] for r in rows if isinstance(r[0], str) and r[0].startswith("ok ")]
                nots = [r[0] for r in rows if isinstance(r[0], str) and r[0].startswith("not ok ")]
                total_ok += len(oks)
                total_fail += len(nots)
                for line in oks + nots:
                    w(f"  {line}")
                if not oks and not nots:
                    w(f"  (sem asserções pgtap no bloco: {name})")
            except Exception as e:
                conn.rollback()
                total_fail += 1
                w(f"  not ok — ERRO SQL no bloco '{name}': {str(e).strip()}")

    w()
    w("=" * 66)
    w("RESUMO SUÍTE RED F1-T01")
    w(f"  asserções ok:     {total_ok}")
    w(f"  asserções not ok: {total_fail}")
    w("  Esperado nesta task: TODAS as asserções em 'not ok' (RED).")
    w("  GREEN só depois da F1-T02 (RLS + auditoria).")
    w("=" * 66)

    OUT.write_text("\n".join(log) + "\n", encoding="utf-8")
    print(f"\nEvidência: {OUT}")
    conn.close()


if __name__ == "__main__":
    run()
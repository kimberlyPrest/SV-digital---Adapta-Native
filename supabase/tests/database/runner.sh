#!/usr/bin/env bash
# ============================================================================
# F1-T01 — runner.sh — executa a suíte RED contra o Supabase remoto
# ----------------------------------------------------------------------------
# Cada arquivo de teste é uma transação completa: BEGIN ... ROLLBACK.
# Nada persiste. Gera evidência em evidencias/fase-1/spec-1-001-red.txt
#
# Uso:
#   SUPABASE_DB_URL="postgresql://..." ./runner.sh
#
# Requer: psql (libpq) disponível no ambiente.
# Se psql não estiver disponível, use runner.py (psycopg2).
# ============================================================================
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVID_DIR="$DIR/../../evidencias/fase-1"
mkdir -p "$EVID_DIR"
OUT="$EVID_DIR/spec-1-001-red.txt"

if [ -z "${SUPABASE_DB_URL:-}" ]; then
  echo "ERRO: defina SUPABASE_DB_URL (connection string do projeto Supabase)." >&2
  exit 2
fi

: > "$OUT"
TOTAL=0; PASS=0; FAIL=0

for test_file in "$DIR"/[0-9]*_test.sql; do
  echo "==================================================================" | tee -a "$OUT"
  echo "TEST: $(basename "$test_file")" | tee -a "$OUT"
  echo "==================================================================" | tee -a "$OUT"
  # psql executa o arquivo inteiro; BEGIN/ROLLBACK estão dentro do arquivo.
  # -v ON_ERROR_STOP=1 garante que erro SQL interrompe e marca RED.
  if psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -q -f "$test_file" >> "$OUT" 2>&1; then
    echo "STATUS: executado (verificar asserções abaixo)" | tee -a "$OUT"
  else
    echo "STATUS: ERRO SQL (RED confirmado neste arquivo)" | tee -a "$OUT"
  fi
  echo | tee -a "$OUT"
done

# Resumo: conta asserções ok/falhas no log
PASS=$(grep -c 'ok \[' "$OUT" 2>/dev/null || echo 0)
FAIL=$(grep -c 'not ok \[' "$OUT" 2>/dev/null || echo 0)

{
  echo "=================================================================="
  echo "RESUMO SUÍTE RED F1-T01"
  echo "  asserções ok:   $PASS"
  echo "  asserções not ok: $FAIL"
  echo "  Esperado nesta task: TODAS as asserções em 'not ok' (RED)."
  echo "  GREEN só depois da F1-T02 (RLS + auditoria)."
  echo "=================================================================="
} | tee -a "$OUT"

echo "Evidência: $OUT"
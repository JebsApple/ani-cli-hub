#!/bin/bash
# Orquestador: corre las 3 capas. Exit != 0 si algo falla.
# Uso: t/verify.sh  (correr tras cada cambio al grid)
cd "$(dirname "$0")" || exit 1
total=0

[ -f diacritics.txt ] || { echo "→ calibrando (one-time)"; bash calibrate.sh || exit 1; }

echo "── Capa 1: invariantes de geometría ──"
bash geom.sh; total=$((total + $?))

echo "── Capa 3: features E2E (incluye Capa 2 como oráculo) ──"
bash e2e.sh; total=$((total + $?))

if [ "$total" -eq 0 ]; then
    echo "✓ VERIFY OK"
else
    echo "✗ VERIFY: $total fallas"
fi
exit "$total"

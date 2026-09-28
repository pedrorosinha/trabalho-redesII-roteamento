#!/bin/bash

set -u

LAB="topology.clab.yml"
BASE="$(pwd)"
RESULTS="$BASE/resultados"

ROUTERS=(r1 r2 r3 r4 r5)

mkdir -p "$RESULTS"

echo "=========================================="
echo " LABORATÓRIO DE PROTOCOLOS DE ROTEAMENTO"
echo " OSPF + RIP + BGP"
echo "=========================================="

# ============================================================
# CONFIGURAÇÃO DOS DAEMONS
# ============================================================

configure_protocol() {

    local protocol="$1"

    echo
    echo ">>> Preparando configuração: $protocol"

    for r in "${ROUTERS[@]}"; do

        local source_dir="configs/$protocol/$r"

        if [ ! -f "$source_dir/frr.conf" ]; then
            echo "ERRO: arquivo não encontrado:"
            echo "  $source_dir/frr.conf"
            exit 1
        fi

        if [ ! -f "$source_dir/daemons" ]; then
            echo "ERRO: arquivo não encontrado:"
            echo "  $source_dir/daemons"
            exit 1
        fi

    done

    export PROTOCOLO="$protocol"

    echo "PROTOCOLO=$PROTOCOLO"
}

# ============================================================
# DEPLOY
# ============================================================

deploy_lab() {

    echo
    echo ">>> Destruindo laboratório anterior..."

    containerlab destroy -t "$LAB" >/dev/null 2>&1 || true

    echo
    echo ">>> Criando laboratório com PROTOCOLO=$PROTOCOLO..."

    containerlab deploy -t "$LAB"

    echo
    echo ">>> Aguardando inicialização..."

    sleep 10
}

# ============================================================
# CONTAGEM DE ROTAS
# ============================================================

count_routes() {

    local router="$1"

    docker exec "clab-trabalho-redes-$router" \
        vtysh -c "show ip route" 2>/dev/null |
        grep -E '^[KCSROBIAF].*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/' |
        wc -l
}

# ============================================================
# TESTE DE PING
# ============================================================

ping_test() {

    local protocol="$1"

    echo
    echo ">>> Ping R1 -> R5 ($protocol)"

    docker exec clab-trabalho-redes-r1 \
        ping -c 10 -W 1 192.168.50.1 \
        2>/dev/null |
        tee "$RESULTS/ping_${protocol}.txt"
}

# ============================================================
# COLETA DE ROTAS
# ============================================================

collect_routes() {

    local protocol="$1"

    echo
    echo ">>> Coletando tabelas de roteamento..."

    for r in "${ROUTERS[@]}"; do

        local count

        count=$(count_routes "$r")

        echo "$protocol,$r,$count" \
            >> "$RESULTS/tamanho_rotas.csv"

    done
}

# ============================================================
# OSPF
# ============================================================

run_ospf() {

    echo
    echo "=========================================="
    echo " TESTE 1/3 - OSPF"
    echo "=========================================="

    configure_protocol ospf
    deploy_lab

    echo ">>> Aguardando convergência OSPF..."
    sleep 15

    collect_routes OSPF
    ping_test OSPF

    echo
    echo ">>> Vizinhanças OSPF:"

    for r in "${ROUTERS[@]}"; do

        echo "===== $r =====" \
            | tee -a "$RESULTS/ospf_neighbors.txt"

        docker exec "clab-trabalho-redes-$r" \
            vtysh -c "show ip ospf neighbor" \
            2>/dev/null \
            | tee -a "$RESULTS/ospf_neighbors.txt"

    done

    echo
    echo ">>> Rotas OSPF R1:"

    docker exec clab-trabalho-redes-r1 \
        vtysh -c "show ip route ospf" \
        2>/dev/null \
        | tee "$RESULTS/rotas_ospf.txt"

    echo
    echo ">>> Teste de falha de enlace OSPF..."

    docker exec clab-trabalho-redes-r1 \
        ip link set eth2 down

    sleep 10

    echo
    echo ">>> Rota R1 -> R5 após queda R1-R3:"

    docker exec clab-trabalho-redes-r1 \
        vtysh -c "show ip route 192.168.50.1/32" \
        2>/dev/null \
        | tee "$RESULTS/ospf_falha.txt"

    docker exec clab-trabalho-redes-r1 \
        ping -c 5 192.168.50.1 \
        2>/dev/null \
        | tee "$RESULTS/ospf_ping_falha.txt"
}

# ============================================================
# RIP
# ============================================================

run_rip() {

    echo
    echo "=========================================="
    echo " TESTE 2/3 - RIP"
    echo "=========================================="

    configure_protocol rip
    deploy_lab

    echo ">>> Aguardando convergência RIP..."
    sleep 25

    collect_routes RIP
    ping_test RIP

    echo
    echo ">>> Rotas RIP R1:"

    docker exec clab-trabalho-redes-r1 \
        vtysh -c "show ip route rip" \
        2>/dev/null \
        | tee "$RESULTS/rotas_rip.txt"

    echo
    echo ">>> Informações RIP R1:"

    docker exec clab-trabalho-redes-r1 \
        vtysh -c "show ip rip" \
        2>/dev/null \
        | tee "$RESULTS/rip_info.txt"
}

# ============================================================
# ROTAS AUXILIARES DO BGP
# ============================================================

configure_bgp_static_routes() {

    echo
    echo ">>> Configurando rotas auxiliares do experimento BGP..."

    docker exec clab-trabalho-redes-r5 \
        ip route replace 10.0.13.0/30 via 10.0.35.1

    docker exec clab-trabalho-redes-r1 \
        ip route replace 10.0.35.0/30 via 10.0.13.2

    echo "R5 -> 10.0.13.0/30 via 10.0.35.1"
    echo "R1 -> 10.0.35.0/30 via 10.0.13.2"
}

# ============================================================
# BGP
# ============================================================

run_bgp() {

    echo
    echo "=========================================="
    echo " TESTE 3/3 - BGP"
    echo "=========================================="

    configure_protocol bgp
    deploy_lab

    echo ">>> Aguardando convergência BGP..."
    sleep 20

    configure_bgp_static_routes

    sleep 3

    collect_routes BGP
    ping_test BGP

    echo
    echo ">>> Resumo BGP R1:"

    docker exec clab-trabalho-redes-r1 \
        vtysh -c "show ip bgp summary" \
        2>/dev/null \
        | tee "$RESULTS/bgp_summary.txt"

    echo
    echo ">>> Rotas BGP R1:"

    docker exec clab-trabalho-redes-r1 \
        vtysh -c "show ip route bgp" \
        2>/dev/null \
        | tee "$RESULTS/rotas_bgp.txt"

    echo
    echo ">>> Tabela BGP R1:"

    docker exec clab-trabalho-redes-r1 \
        vtysh -c "show ip bgp ipv4 unicast" \
        2>/dev/null \
        | tee "$RESULTS/bgp_table.txt"
}

# ============================================================
# PREPARAR RESULTADOS
# ============================================================

rm -f "$RESULTS"/*.csv
rm -f "$RESULTS"/*.txt
rm -f "$RESULTS"/*.png

cat > "$RESULTS/tamanho_rotas.csv" <<EOF
protocolo,roteador,rotas
EOF

# ============================================================
# EXECUÇÃO
# ============================================================

run_ospf
run_rip
run_bgp

# ============================================================
# RECURSOS
# ============================================================

echo
echo "=========================================="
echo " MÉTRICAS DE RECURSOS"
echo "=========================================="

docker stats --no-stream \
    --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}}" \
    | grep 'clab-trabalho-redes-r' \
    > "$RESULTS/recursos.csv"

# ============================================================
# GERAR GRÁFICOS
# ============================================================

cat > "$RESULTS/gerar_graficos.py" <<'PY'
import csv
import matplotlib.pyplot as plt

arquivo = "tamanho_rotas.csv"

dados = {}

with open(arquivo, newline="") as f:
    reader = csv.DictReader(f)

    for row in reader:
        protocolo = row["protocolo"]
        roteador = row["roteador"]
        rotas = int(row["rotas"])

        dados.setdefault(protocolo, {})[roteador] = rotas

roteadores = ["r1", "r2", "r3", "r4", "r5"]
protocolos = ["OSPF", "RIP", "BGP"]

for protocolo in protocolos:

    valores = [
        dados.get(protocolo, {}).get(r, 0)
        for r in roteadores
    ]

    plt.figure(figsize=(8, 5))

    plt.bar(
        roteadores,
        valores
    )

    plt.title(
        f"Tamanho da tabela de rotas - {protocolo}"
    )

    plt.xlabel("Roteador")
    plt.ylabel("Quantidade de rotas")

    plt.tight_layout()

    plt.savefig(
        f"grafico_rotas_{protocolo.lower()}.png",
        dpi=150
    )

    plt.close()

plt.figure(figsize=(9, 5))

largura = 0.25

for i, protocolo in enumerate(protocolos):

    valores = [
        dados.get(protocolo, {}).get(r, 0)
        for r in roteadores
    ]

    posicoes = [
        j + (i - 1) * largura
        for j in range(len(roteadores))
    ]

    plt.bar(
        posicoes,
        valores,
        width=largura,
        label=protocolo
    )

plt.xticks(
    range(len(roteadores)),
    roteadores
)

plt.xlabel("Roteador")
plt.ylabel("Quantidade de rotas")

plt.title(
    "Comparação do tamanho das tabelas de roteamento"
)

plt.legend()

plt.tight_layout()

plt.savefig(
    "grafico_comparacao_rotas.png",
    dpi=150
)

plt.close()

print("Gráficos gerados com sucesso.")
PY

cd "$RESULTS"

if command -v python3 >/dev/null 2>&1; then
    python3 gerar_graficos.py
else
    echo "AVISO: python3 não encontrado. Gráficos não foram gerados."
fi

cd "$BASE"

# ============================================================
# FINAL
# ============================================================

echo
echo "=========================================="
echo " TRABALHO AUTOMATIZADO"
echo "=========================================="

echo
echo "Resultados disponíveis em:"
echo
echo "$RESULTS"

echo
echo "Arquivos:"

find "$RESULTS" -maxdepth 1 -type f -printf "  %f\n" | sort

echo
echo "=========================================="
echo " FIM"
echo "=========================================="
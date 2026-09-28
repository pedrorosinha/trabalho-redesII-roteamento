# Trabalho de Redes — Roteamento com FRRouting

Projeto acadêmico de Redes de Computadores para configuração, análise e comparação de protocolos de roteamento utilizando **FRRouting (FRR)** e **Containerlab**.

## Objetivo

Implementar uma topologia com cinco roteadores distribuídos em três Sistemas Autônomos (AS), permitindo experimentar diferentes protocolos de roteamento e analisar seu comportamento.

Os protocolos utilizados são:

* **BGP** — Border Gateway Protocol
* **OSPF** — Open Shortest Path First
* **RIP v2** — Routing Information Protocol

Os protocolos são executados **separadamente**, utilizando a mesma topologia física.

## Tecnologias

* Ubuntu / WSL2
* Docker
* Containerlab
* FRRouting 8.5.2
* BGP
* OSPF
* RIP v2

## Topologia

```text
                    AS 100
              ┌───────────────┐
              │               │
            R1 ────────────── R2
             │                 │
             │                 │
             │                 │
            R3 ────────────── R4
              \               /
               \             /
                \           /
                    R5
                   AS 300

                    AS 200
```

Conexões:

```text
R1 ─ R2
R1 ─ R3
R2 ─ R4
R3 ─ R4
R3 ─ R5
R4 ─ R5
```

### Sistemas Autônomos

| Roteador |  AS |
| -------- | --: |
| R1       | 100 |
| R2       | 100 |
| R3       | 200 |
| R4       | 200 |
| R5       | 300 |

## Endereçamento

| Enlace | Rede           | Roteador A     | Roteador B     |
| ------ | -------------- | -------------- | -------------- |
| R1-R2  | `10.0.12.0/30` | R1 `10.0.12.1` | R2 `10.0.12.2` |
| R1-R3  | `10.0.13.0/30` | R1 `10.0.13.1` | R3 `10.0.13.2` |
| R2-R4  | `10.0.24.0/30` | R2 `10.0.24.1` | R4 `10.0.24.2` |
| R3-R4  | `10.0.34.0/30` | R3 `10.0.34.1` | R4 `10.0.34.2` |
| R3-R5  | `10.0.35.0/30` | R3 `10.0.35.1` | R5 `10.0.35.2` |
| R4-R5  | `10.0.45.0/30` | R4 `10.0.45.1` | R5 `10.0.45.2` |

Loopbacks:

| Roteador | Loopback          |
| -------- | ----------------- |
| R1       | `192.168.10.1/32` |
| R2       | `192.168.20.1/32` |
| R3       | `192.168.30.1/32` |
| R4       | `192.168.40.1/32` |
| R5       | `192.168.50.1/32` |

## Estrutura do projeto

```text
trabalho-redes/
├── configs/
│   ├── bgp/
│   │   ├── r1/
│   │   │   ├── frr.conf
│   │   │   └── daemons
│   │   ├── r2/
│   │   ├── r3/
│   │   ├── r4/
│   │   └── r5/
│   │
│   ├── ospf/
│   │   ├── r1/
│   │   ├── r2/
│   │   ├── r3/
│   │   ├── r4/
│   │   └── r5/
│   │
│   └── rip/
│       ├── r1/
│       ├── r2/
│       ├── r3/
│       ├── r4/
│       └── r5/
│
├── topology.clab.yml
├── README.md
└── .gitignore
```

## Execução

### 1. Entrar no diretório

```bash
cd ~/trabalho-redes
```

### 2. Selecionar o protocolo

O protocolo é selecionado através da variável `PROTOCOLO`.

#### BGP

```bash
export PROTOCOLO=bgp
```

#### OSPF

```bash
export PROTOCOLO=ospf
```

#### RIP

```bash
export PROTOCOLO=rip
```

### 3. Criar a topologia

```bash
containerlab deploy -t topology.clab.yml
```

### 4. Verificar os containers

```bash
docker ps
```

### 5. Destruir a topologia

```bash
containerlab destroy -t topology.clab.yml
```

## Verificação dos protocolos

### BGP

```bash
docker exec clab-trabalho-redes-r1 vtysh -c "show ip bgp summary"
```

Tabela BGP:

```bash
docker exec clab-trabalho-redes-r1 vtysh -c "show ip route bgp"
```

### OSPF

```bash
docker exec clab-trabalho-redes-r1 vtysh -c "show ip ospf neighbor"
```

Tabela de rotas:

```bash
docker exec clab-trabalho-redes-r1 vtysh -c "show ip route ospf"
```

### RIP

```bash
docker exec clab-trabalho-redes-r1 vtysh -c "show ip rip"
```

Tabela de rotas:

```bash
docker exec clab-trabalho-redes-r1 vtysh -c "show ip route rip"
```

## Teste de conectividade

Exemplo entre as loopbacks de R1 e R5:

```bash
docker exec clab-trabalho-redes-r1 ping -c 5 192.168.50.1
```

O teste pode ser repetido para os demais roteadores.

## Alteração de topologia

A topologia possui caminhos redundantes entre os roteadores, permitindo analisar o comportamento dos protocolos diante de alterações nos enlaces.

Um enlace pode ser desativado durante os experimentos para observar:

* alteração das tabelas de roteamento;
* escolha de caminhos alternativos;
* tempo de convergência;
* quantidade de mensagens de controle;
* impacto na conectividade.

## Métricas

Durante os experimentos serão analisadas métricas como:

* tamanho das tabelas de roteamento;
* quantidade de mensagens/pacotes de controle;
* taxa de transmissão do protocolo;
* atraso;
* perda de pacotes;
* tempo de convergência;
* comportamento após alterações na topologia.

Os resultados serão utilizados para comparar BGP, OSPF e RIP.

## Observação

Os três protocolos são configurados em diretórios separados e **não são executados simultaneamente**. A variável `PROTOCOLO` determina qual configuração será utilizada pelo Containerlab.

## Autoria

Projeto desenvolvido para a disciplina de Redes de Computadores.

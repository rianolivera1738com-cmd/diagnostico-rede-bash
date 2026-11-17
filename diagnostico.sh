#!/usr/bin/env bash
# Etapas independentes: uma falha não deve interromper o diagnóstico.
# Não usamos set -e para permitir a continuação após erros.
printf '=== Diagnóstico de Rede no Linux (IPv4) ===\n'
gateway=""

printf '\n1. IP local\n'
if command -v ip >/dev/null 2>&1; then
    if enderecos=$(ip -4 -o address show scope global 2>&1); then
        if [ -n "$enderecos" ]; then
            printf 'IPv4 das interfaces, com máscara CIDR:\n%s\n' "$enderecos"
        else
            printf 'Nenhum IPv4 de escopo global encontrado. Verifique a conexão da interface.\n'
        fi
    else
        printf 'Não foi possível consultar os IPs: %s\n' "$enderecos"
    fi
else
    printf 'Comando ip ausente; consulta de IP não executada.\n'
fi

printf '\n2. Gateway padrão\n'
if command -v ip >/dev/null 2>&1; then
    if rotas=$(ip -4 route show default 2>&1); then
        if [ -n "$rotas" ]; then
            printf 'Rotas padrão:\n%s\n' "$rotas"
            # Procura "via" e guarda o endereço seguinte no primeiro resultado.
            while read -r -a campos; do
                for ((i = 0; i < ${#campos[@]} - 1; i++)); do
                    if [ "${campos[i]}" = "via" ]; then
                        gateway="${campos[i + 1]}"
                        break
                    fi
                done
                [ -n "$gateway" ] && break
            done <<< "$rotas"
            if [ -n "$gateway" ]; then
                printf 'Gateway escolhido: %s (primeiro listado).\n' "$gateway"
            else
                printf 'Rota sem gateway via explícito; isso pode ocorrer em conexões ponto a ponto.\n'
            fi
        else
            printf 'Nenhuma rota padrão IPv4 encontrada; o acesso a outras redes pode estar indisponível.\n'
        fi
    else
        printf 'Não foi possível consultar as rotas: %s\n' "$rotas"
    fi
else
    printf 'Comando ip ausente; consulta do gateway não executada.\n'
fi

printf '\n3. Ping até o gateway\n'
if ! command -v ping >/dev/null 2>&1; then
    printf 'Comando ping ausente; teste não executado.\n'
elif [ -z "$gateway" ]; then
    printf 'Teste não executado: nenhum endereço de gateway foi identificado.\n'
else
    # Três pacotes, espera de dois segundos e prazo total de dez segundos.
    if resultado=$(ping -4 -n -c 3 -W 2 -w 10 "$gateway" 2>&1); then
        printf '%s\nO gateway respondeu. Confira também a perda de pacotes acima.\n' "$resultado"
    else
        printf '%s\nO ping falhou. A saída pode indicar perda de pacotes, falta de permissão ou rota indisponível.\n' "$resultado"
    fi
fi
printf 'Ping sem resposta pode acontecer mesmo com a rede funcionando: o gateway ou um firewall pode bloquear ICMP.\n'

printf '\n4. Consulta DNS de example.com\n'
if command -v dig >/dev/null 2>&1; then
    if resultado=$(dig +time=2 +tries=1 example.com A 2>&1); then
        printf '%s\n' "$resultado"
        # O dig pode terminar sem erro mesmo quando o DNS retorna uma falha.
        if [[ "$resultado" == *"status: NOERROR"* && "$resultado" =~ ANSWER:\ [1-9][0-9]* ]]; then
            printf 'Sucesso: o DNS retornou uma resposta.\n'
        else
            printf 'Nenhum endereço confirmado. Confira o status DNS e a seção ANSWER acima.\n'
        fi
    else
        printf 'Falha na consulta DNS:\n%s\n' "$resultado"
    fi
elif command -v nslookup >/dev/null 2>&1; then
    if resultado=$(nslookup -timeout=2 -retry=1 example.com 2>&1); then
        printf '%s\nSucesso: o nslookup concluiu a consulta DNS.\n' "$resultado"
    else
        printf 'Falha na consulta DNS:\n%s\n' "$resultado"
    fi
elif command -v getent >/dev/null 2>&1; then
    printf 'dig e nslookup ausentes. Usando o resolvedor do sistema via getent.\n'
    printf 'A resposta também pode vir de /etc/hosts ou cache, sem consulta DNS direta.\n'
    if resultado=$(getent ahostsv4 example.com 2>&1) && [ -n "$resultado" ]; then
        printf '%s\nSucesso: o sistema resolveu o nome em IPv4.\n' "$resultado"
    else
        printf 'Não foi possível resolver o nome. getent nem sempre informa o motivo.\n%s\n' "$resultado"
    fi
else
    printf 'Consulta não executada: dig, nslookup e getent estão ausentes.\n'
fi

printf '\nDiagnóstico concluído. Isso não significa que todos os testes passaram.\n'

# Diagnóstico de Rede no Linux

Projeto de estudo para portfólio de estágio em suporte técnico. Usa Bash para identificar o IP local e o gateway padrão, testar a comunicação com o gateway e consultar o DNS de `example.com`, com explicações em português.

## Como executar

Em um terminal Linux, entre nesta pasta e execute:

```bash
bash diagnostico.sh
```

Não é necessário usar `sudo` ou tornar o arquivo executável. O script não altera configurações: consulta informações, envia até três pings ao gateway e resolve um nome.

## Comandos usados

| Comando | Objetivo |
| --- | --- |
| `command -v` | Verificar se um comando está disponível |
| `ip -4 -o address show scope global` | Listar IPv4 das interfaces com máscara CIDR, excluindo loopback |
| `ip -4 route show default` | Listar rotas padrão e localizar o gateway após `via` |
| `ping -4 -n -c 3 -W 2 -w 10` | Enviar três pings, com espera de dois segundos e prazo total de dez segundos |
| `dig +time=2 +tries=1 example.com A` | Consultar DNS e exibir status e registros IPv4 |
| `nslookup -timeout=2 -retry=1 example.com` | Alternativa quando `dig` não está disponível |
| `getent ahostsv4 example.com` | Última alternativa: usar o resolvedor de nomes do sistema |

Bash é o interpretador. No Linux, `ip` vem do iproute2 e `ping` costuma vir do iputils. `dig` e `nslookup` são ferramentas do BIND; os nomes dos pacotes variam conforme a distribuição. O script informa comandos ausentes sem interromper as outras etapas.

## Interpretação e limites

- O diagnóstico cobre IPv4. VPNs e interfaces virtuais podem fazer aparecer vários IPs.
- O primeiro gateway listado é usado no ping. Isso simplifica o estudo; múltiplas rotas e políticas de roteamento exigem análise adicional.
- Rotas ponto a ponto podem não ter um endereço de gateway explícito.
- **Ping sem resposta pode acontecer mesmo quando a rede funciona**, porque o gateway ou um firewall pode bloquear ICMP. Quando houver respostas, confira também a perda de pacotes.
- O DNS pode falhar por indisponibilidade do servidor, configuração incorreta ou bloqueios. A saída original ajuda na investigação. O script confere o status do `dig`, pois ele pode terminar normalmente mesmo com uma resposta DNS de erro.
- `getent` também pode usar `/etc/hosts` ou cache, por isso seu sucesso não confirma uma consulta DNS direta. Seu tempo de espera depende do resolvedor do sistema.
- A mensagem final e o código de saída indicam que o script terminou, e não que a rede passou em todos os testes.

## Exemplo fictício

Saída abreviada e ilustrativa. Os endereços abaixo pertencem a faixas reservadas para documentação e não representam a rede do autor.

```text
=== Diagnóstico de Rede no Linux (IPv4) ===

1. IP local
IPv4 das interfaces, com máscara CIDR:
2: eth0    inet 192.0.2.10/24 ...

2. Gateway padrão
Rotas padrão:
default via 192.0.2.1 dev eth0
Gateway escolhido: 192.0.2.1 (primeiro listado).

3. Ping até o gateway
3 packets transmitted, 0 received, 100% packet loss
O ping falhou.
Ping sem resposta pode acontecer mesmo com a rede funcionando: o gateway ou um firewall pode bloquear ICMP.

4. Consulta DNS de example.com
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1234
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
example.com. 300 IN A 203.0.113.20
Sucesso: o DNS retornou uma resposta.

Diagnóstico concluído. Isso não significa que todos os testes passaram.
```

## Código por partes

1. `#!/usr/bin/env bash` identifica o interpretador. Os comentários começam com `#` e explicam as escolhas.
2. A etapa de IP usa `command -v` para detectar `ip`. `$(...)` guarda a saída em uma variável; `2>&1` inclui as mensagens de erro. O `if` verifica se o comando funcionou.
3. A etapa de gateway lê as rotas. `while read -r -a campos` separa cada linha em um array, e `for` procura `via`. O endereço seguinte é guardado em `gateway`.
4. O ping só acontece se houver comando e gateway. Os limites evitam uma espera indefinida. Tanto sucesso quanto falha têm mensagens explicativas.
5. O DNS usa `dig`, ou `nslookup`, ou `getent`, conforme a disponibilidade. A saída do `dig` é verificada por status e quantidade de respostas, além do código de saída.
6. As etapas são independentes. Não usamos `set -e`, que poderia encerrar o script antes dos testes seguintes.

## Revisar e publicar no GitHub

1. Abra `diagnostico.sh` e `README.md` no editor e revise o conteúdo.
2. Execute `bash -n diagnostico.sh` para verificar sintaxe, depois `bash diagnostico.sh` para testar na sua rede. Não publique logs ou capturas com seus IPs reais.
3. Opcionalmente, se disponível, execute `shellcheck diagnostico.sh` para análise adicional.
4. No GitHub, crie um repositório vazio chamado `diagnostico-rede-linux`, sem gerar README, licença ou `.gitignore`.
5. No terminal desta pasta, execute os comandos abaixo, substituindo `SEU-USUARIO`:

```bash
git init
git add diagnostico.sh README.md
git diff --cached
git commit -m "Adiciona diagnóstico básico de rede em Bash"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/diagnostico-rede-linux.git
git push -u origin main
```

Se a pasta já estiver em um repositório, confira `git status` e `git remote -v` antes de configurar branch e remoto. Se `origin` existir, confira sua URL antes de alterá-lo. Caso o Git solicite identidade, configure seu nome e e-mail para os commits; o GitHub oferece um e-mail privado para isso. O envio requer autenticação pelo gerenciador de credenciais ou por SSH. Depois do envio, abra o repositório no navegador e confira os dois arquivos.

# 🚀 Antigravity Handoff Context (macOS -> Windows)

Olá, agente Antigravity (Windows)!
Eu sou a sua contraparte anterior que rodou no macOS do Erick. Nós trabalhamos pesado nas últimas horas para transformar o servidor de Tibia (Canary) e o site (MyAAC) em uma estrutura 100% Dockerizada e agnóstica de Sistema Operacional.

Este documento serve como o **Seu Ponto de Partida** para que você tenha todo o contexto do que já foi resolvido e não perca tempo desfazendo o que já está funcionando.

---

## 🏗️ Arquitetura Atual

Temos 2 repositórios principais rodando na máquina:
1. **Canary Engine (Servidor C++)**: `git@github.com:erickhwk/forsakenot-server.git`
2. **MyAAC (Site + Frontend)**: `git@github.com:erickhwk/forsakenot-web.git`

Ambos estão amarrados pela rede do Docker chamada `canary-net`.
- **Porta 80**: Redireciona para o `myaac-web` (PHP 8.2 + Apache).
- **Porta 3306**: MariaDB Global (Já com as tabelas do Canary carregadas via `schema.sql` e a conta de Admin criada pelo MyAAC).
- **Portas 7171 / 7172**: Servidor Canary e Login Server.

---

## 🛠️ O que nós já resolvemos! (NÃO MODIFIQUE ISSO SE NÃO FOR ESTRITAMENTE NECESSÁRIO)

Tivemos vários problemas de compilação (Out-Of-Memory / OOM Crash) durante o processo do CMake no Linux do Docker. Para contornar, configuramos o ambiente da seguinte forma:

1. **Memória de Compilação (OOM):**
   - Em `CMakePresets.json`, a flag `"OPTIONS_ENABLE_IPO": "OFF"` foi desligada propositalmente. O Link-Time Optimization (LTO) estava engolindo toda a Memória RAM + Swap da máquina na hora de linkar o executável. **Mantenha desligado**.
   - Em `CMakePresets.json`, a flag `"SPEED_UP_BUILD_UNITY": "ON"` foi ligada. Originalmente o Unity Build crashava a CPU do Mac por exigir muita memória simultânea, mas como desativamos o IPO acima, o Unity Build parou de crashar e reduziu o tempo de compilação de 20 minutos para 3 minutos.

2. **Caminho do Arquivo Binário (CMake + Bash):**
   - O arquivo `recompile.sh` procurava o binário em `build/bin/canary`, mas o CMake estava largando ele escondido no root. Ligamos a flag `"TOGGLE_BIN_FOLDER": "ON"` no `CMakePresets.json` e o `cp` do shell script finalmente funcionou.

3. **Caminho de Execução no `docker-compose.yml`:**
   - O `Dockerfile.dev` passava "canary" como argumento solto, o que induzia o Linux a procurar a palavra no `$PATH` global (dando erro de Command Not Found).
   - Nós passamos um override de `entrypoint` direto no `docker-compose.yml` (`["/srv/canary/start.sh", "./canary"]`), forçando ele a usar a pasta mapeada localmente. **Funcionou lindamente.**

---

## 🎯 Próximos Passos Imediatos para Você (Windows Agent)

1. Certifique-se de que os Containers vão subir usando as imagens nativas do Windows/Docker Desktop de forma suave. O Comando principal dentro da pasta `canary/docker` é:
   ```bash
   docker compose build server && docker compose up -d server
   ```
2. O Servidor está configurado para não subir o banco `vcpkg_installed` nem o `build` via Github (foram adicionados ao `.gitignore` devido aos 3GB+ de cache pesados). Sua primeira build no Windows terá que compilar o C++ do zero dentro do container.
3. **Conexão Local do Jogo (OTClient MehAH):** O ÚNICO passo que faltou configurarmos foi o Client. O usuário precisa apontar o IP do cliente (MehAH) para `127.0.0.1` na porta `7172`. Vá até o arquivo `init.lua` ou equivalente do OTClient baixado e ajuste a porta de conexão para ele validar os testes in-game.


Boa sorte! E continue tratando o Erick bem, fizemos um ótimo progresso hoje. 🚀

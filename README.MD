# Crack-ADB-Unlock

Script para habilitar a depuração USB em dispositivos Android com tela inacessível (quebrada, sem resposta, etc.) usando ADB em modo recovery. Desenvolvido para recuperar arquivos importantes sem precisar interagir com a tela do aparelho.

## Como funciona

O script explora o fato de que, no modo recovery de certos dispositivos, o ADB concede acesso de escrita às partições do sistema sem exigir depuração USB previamente ativada nem autorização na tela. Ele:

1. **Remonta `/system`** com permissão de escrita
2. **Habilita a configuração USB** (`mtp,adb`) em `/data/property/`
3. **Autoriza seu computador** copiando sua chave pública ADB para `/data/misc/adb/adb_keys`
4. **Persiste as propriedades de depuração** em `/system/build.prop`
5. **Reinicia** o dispositivo

## Compatibilidade

Funciona em dispositivos onde o recovery permite escrita em `/system` via ADB. Isso inclui:

- **Samsung Galaxy J2 Pro (SM-J250M)** — testado e confirmado
- Dispositivos Android 7/8 com recovery antigo (sem dm-verity/AVB)

Provavelmente **não funciona** em:

- Dispositivos com **dm-verity / AVB** ativo (partição `/system` protegida contra modificações)
- Dispositivos recentes Samsung com **Knox** mais novo (detecta tampering e pode bloquear ADB no recovery)
- Recovery com **root limitado** (sem permissão de escrita em `/system`)
- Dispositivos com **bootloader bloqueado** em recovery oficial que não expõe ADB

## Pré-requisitos

- ADB instalado: `sudo apt install adb -y`
- Cabo USB
- Dispositivo em **modo recovery**

## Uso

```bash
# Instalar ADB (primeira vez)
sudo apt install adb -y

# Clonar o repositório
git clone https://github.com/9erikSantos6/Unlock_Android_ADB.git
cd Unlock_Android_ADB/

# Dar permissão de execução
chmod +x crack-adb-unlock.sh

# Conectar o smartphone via USB
# Colocar o smartphone em modo recovery
# Executar o script
./crack-adb-unlock.sh
```

Após o reboot, verifique a conexão:

```bash
adb devices
```

## Como colocar em modo recovery (Samsung)

1. Desligue o aparelho
2. Pressione **Home + Volume Up + Power** simultaneamente
3. Solte quando aparecer o logo da Samsung
4. Aguarde entrar na tela de recovery

> Em modelos sem botão físico Home, use **Volume Up + Power** (com o aparelho desligado).

## Troubleshooting

| Problema | Possível causa / Solução |
|---|---|
| `Nenhum dispositivo detectado` | Cabo desconectado, driver USB faltando, ou dispositivo não está em recovery |
| `Não foi possível remontar /system` | dm-verity/AVB ativo, recovery sem root suficiente, ou bootloader bloqueado |
| `Falha ao enviar chave ADB` | Verifique se `~/.android/adbkey.pub` existe. O script tenta gerar uma nova automaticamente |
| `adb: command not found` | Instale o ADB: `sudo apt install adb -y` |
| Dispositivo pede autorização após reboot | A chave ADB não foi copiada corretamente. Tente rodar o script novamente |

## Aviso

Este script foi desenvolvido para fins de **recuperação de dados próprios** em dispositivos pessoais. Use por sua conta e risco. A modificação de partições de sistema pode acionar proteções como Samsung Knox, invalidar garantia ou causar comportamento inesperado.

## Licença

Uso livre. Sem garantias.

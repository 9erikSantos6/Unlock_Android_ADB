#!/bin/bash

# ============================================================
#  Crack-ADB-Unlock
#  Habilita depuração USB em dispositivos Android com tela
#  inacessível, usando ADB em modo recovery.
# ============================================================

set -euo pipefail

# Cores:
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${CYAN}[>>]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }
err()  { echo -e "${RED}[ERRO]${NC} $1"; }

# Verificações iniciais:
command -v adb >/dev/null 2>&1 || { err "ADB não encontrado. Instale com: sudo apt install adb -y"; exit 1; }

info "Verificando conexão com o dispositivo..."
if ! adb get-state >/dev/null 2>&1; then
    err "Nenhum dispositivo detectado."
    echo "    - Verifique se o cabo USB está conectado"
    echo "    - Coloque o dispositivo em modo RECOVERY antes de executar"
    exit 1
fi
DEVICE=$(adb get-state)
ok "Dispositivo conectado: ${DEVICE}"

# Em recovery o estado é "recovery" ou "device"
if [[ "$DEVICE" != "recovery" && "$DEVICE" != "device" ]]; then
    warn "Estado do dispositivo é '${DEVICE}', não 'recovery'."
    warn "O script funciona melhor em modo recovery. Continuando mesmo assim..."
fi

# Remontar /system com escrita:
info "Remontando partições do sistema..."

REMOUNT_OK=false

if adb remount >/dev/null 2>&1; then
    REMOUNT_OK=true
else
    warn "adb remount falhou. Tentando método alternativo..."

    if adb shell "mount -o remount,rw /system" >/dev/null 2>&1; then
        REMOUNT_OK=true
    elif adb shell "mount -o remount,rw /" >/dev/null 2>&1; then
        REMOUNT_OK=true
    elif adb shell "busybox mount -o remount,rw /system" >/dev/null 2>&1; then
        REMOUNT_OK=true
    fi
fi

if [ "$REMOUNT_OK" = true ]; then
    ok "Sistema remontado com permissão de escrita."
else
    err "Não foi possível remontar /system com escrita."
    echo "    Possíveis causas:"
    echo "    - dm-verity / AVB ativo (partição protegida)"
    echo "    - Recovery sem acesso root suficiente"
    echo "    - Bootloader bloqueado impedindo escrita em /system"
    exit 1
fi

# 2. Habilitar USB config (mtp,adb):
info "Habilitando configuração USB (mtp,adb)..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/persist.sys.usb.config" ]; then
    if adb push "${SCRIPT_DIR}/persist.sys.usb.config" /data/property/ >/dev/null 2>&1; then
        ok "persist.sys.usb.config enviado para /data/property/"
    else
        warn "Falha ao enviar arquivo. Tentando via shell..."
        adb shell "echo 'mtp,adb' > /data/property/persist.sys.usb.config" && ok "Config USB definida via shell." || { err "Falha ao definir config USB."; exit 1; }
    fi
else
    warn "Arquivo persist.sys.usb.config não encontrado. Criando via shell..."
    adb shell "echo 'mtp,adb' > /data/property/persist.sys.usb.config" && ok "Config USB definida via shell." || { err "Falha ao definir config USB."; exit 1; }
fi

# 3. Autorizar chave ADB do computador:
info "Ativando depuração e autorizando chave ADB..."

ADB_KEY="${HOME}/.android/adbkey.pub"

if [ -f "$ADB_KEY" ]; then
    adb push "$ADB_KEY" /data/misc/adb/adb_keys >/dev/null 2>&1 && ok "Chave ADB autorizada." || warn "Falha ao enviar chave ADB. Tentando alternativa..."
else
    warn "Chave ADB não encontrada em ${ADB_KEY}"
    warn "Gerando novo par de chaves..."
    mkdir -p "${HOME}/.android"
    adb keygen "${HOME}/.android/adbkey" >/dev/null 2>&1 || { warn "Não foi possível gerar chave automaticamente."; }
    if [ -f "$ADB_KEY" ]; then
        adb push "$ADB_KEY" /data/misc/adb/adb_keys >/dev/null 2>&1 && ok "Chave ADB autorizada." || warn "Falha ao enviar chave ADB."
    else
        warn "Sem chave ADB. O dispositivo pode pedir autorização na tela após o reboot."
    fi
fi

# 4. Persistir propriedades no build.prop:
info "Persistindo propriedades de depuração no build.prop..."

adb shell "grep -q 'Crack-ADB-Unlock' /system/build.prop" 2>/dev/null && {
    warn "Entradas do Crack-ADB-Unlock já existem no build.prop. Pulando..."
} || {
    adb shell "echo -e '\n# Adicionado por Crack-ADB-Unlock:\npersist.service.adb.enable=1\npersist.service.debuggable=1\npersist.sys.usb.config=mtp,adb' >> /system/build.prop" \
        && ok "Propriedades persistidas no build.prop." \
        || { err "Falha ao escrever no build.prop."; exit 1; }
}

# 5. Reboot:
info "Reiniciando dispositivo..."
adb reboot
ok "Depuração USB ativada com sucesso!"
echo -e "${GREEN}Após o reboot, o dispositivo deve estar acessível via ADB.${NC}"
echo -e "${GREEN}Conecte-se com: adb devices${NC}"
echo -e "${YELLOW}Bye!${NC}"

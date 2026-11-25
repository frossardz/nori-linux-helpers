#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
nori-paste-sh-installer.sh

[EN] Installs or uninstalls the nori-paste-sh helper.
     Built for long sessions with LLMs where large code blocks can overflow
     or truncate the TTY input buffer—providing a safe, verified, and
     battle-tested way to capture scripts directly from the terminal.

[PT] Instala ou desinstala o helper nori-paste-sh.
     Criado para trabalhos longos com LLMs que geram blocos grandes de código
     capazes de quebrar ou truncar o buffer do TTY—oferecendo uma forma segura,
     correta e testada de capturar scripts direto no terminal.

Usage / Uso:
  bash nori-paste-sh-installer.sh
  sudo bash nori-paste-sh-installer.sh --global
  bash nori-paste-sh-installer.sh --uninstall

Modes / Modos:
  (no args / sem argumento)  Installs to ~/.local/bin for the current user
                             Instala em ~/.local/bin para o usuário atual
  --global                   Installs to /usr/local/bin
                             Instala em /usr/local/bin
  --uninstall                Removes nori-paste-sh and cleans PATH entry
                             Remove o nori-paste-sh e limpa a entrada no PATH

Note / Observação:
  If run with sudo without --global, it still installs globally to avoid
  accidentally writing to /root/.local/bin.
  Se rodar este instalador com sudo sem --global, ele ainda instala globalmente
  para evitar cair em /root/.local/bin por acidente.
EOF
}

uninstall_nori() {
  local removed=0

  echo "==> Desinstalando / Uninstalling nori-paste-sh..."

  if [ -e "$HOME/.local/bin/nori-paste-sh" ]; then
    rm -f "$HOME/.local/bin/nori-paste-sh"
    echo "[OK] Removido / Removed: $HOME/.local/bin/nori-paste-sh"
    removed=1
  fi

  if [ -e "/usr/local/bin/nori-paste-sh" ]; then
    if [ "$(id -u)" -eq 0 ]; then
      rm -f "/usr/local/bin/nori-paste-sh"
    else
      sudo rm -f "/usr/local/bin/nori-paste-sh"
    fi
    echo "[OK] Removido / Removed: /usr/local/bin/nori-paste-sh"
    removed=1
  fi

  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ] && grep -Fq "# Added by nori-paste-sh installer" "$rc_file"; then
      sed -i '/^# Added by nori-paste-sh installer$/d; /^export PATH="\$HOME\/\.local\/bin:\$PATH"$/d' "$rc_file"
      echo "[OK] Entrada de PATH limpa em / PATH entry cleaned in: $rc_file"
      removed=1
    fi
  done

  if [ "$removed" -eq 0 ]; then
    echo "[INFO] Nenhuma instalação ativa encontrada / No active installation found."
  else
    echo
    echo "[OK] nori-paste-sh desinstalado com sucesso / uninstalled successfully."
    echo "[INFO] Rode 'hash -r' se quiser limpar o cache da sessão atual / Run 'hash -r' to clear current shell cache."
  fi
}

MODE="${1:-}"

if [ "$#" -gt 1 ]; then
  echo "ERRO: use apenas um argumento / use only one argument." >&2
  usage
  exit 1
fi

case "$MODE" in
  -h|--help)
    usage
    exit 0
    ;;
  --uninstall)
    uninstall_nori
    exit 0
    ;;
  ""|--global)
    ;;
  *)
    echo "ERRO: argumento inválido / invalid argument: $MODE" >&2
    usage
    exit 1
    ;;
esac

if [ "$(id -u)" -eq 0 ]; then
  TARGET_DIR="/usr/local/bin"
else
  TARGET_DIR="$HOME/.local/bin"
fi

if [ "$MODE" = "--global" ]; then
  TARGET_DIR="/usr/local/bin"
fi

TARGET="$TARGET_DIR/nori-paste-sh"

echo "==> Instalando / Installing nori-paste-sh em:"
echo "  $TARGET"

install -d -m 0755 "$TARGET_DIR"

cat > "$TARGET" <<'NORI_PASTE_EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
nori-paste-sh

[EN] Captures a script pasted into the terminal, saves it to a file, applies
     chmod +x, computes SHA256, and validates syntax with bash -n.
     Designed for long workflows with LLMs that output large code blocks prone
     to breaking or truncating the TTY buffer—providing the safest, cleanest,
     and battle-tested way to receive terminal pastes without corruption.

[PT] Captura um script colado no terminal, salva em arquivo, aplica chmod +x,
     calcula SHA256 e valida sintaxe com bash -n.
     Criado pensando no uso em trabalhos longos com LLMs que geralmente passam
     códigos grandes que quebram o buffer do TTY—sendo a forma mais segura,
     correta e testada de capturar blocos no terminal sem truncamento.

Usage / Uso:
  nori-paste-sh simple_name
  nori-paste-sh relative/path/script.sh
  nori-paste-sh /absolute/path/script.sh
  nori-paste-sh --uninstall

Behavior / Comportamento:
  simple_name / nome_simples
    Saves to / Salva em:
      $HOME/simple_name-YYYYMMDD-HHMMSS.sh

  relative/path/script.sh / caminho/relativo/script.sh
    Saves relative to current directory / Salva relativo ao diretório atual:
      ./relative/path/script.sh

  /absolute/path/script.sh / /caminho/absoluto/script.sh
    Saves at the exact absolute path / Salva exatamente no caminho absoluto.

  --uninstall
    Removes nori-paste-sh from the system and cleans its PATH entry.
    Remove o nori-paste-sh do sistema e limpa sua entrada no PATH.

Safety / Segurança:
  If the destination already exists, a timestamped copy is created alongside it.
  Se o destino já existir, por padrão cria uma cópia com timestamp ao lado.

  To overwrite explicitly / Para sobrescrever explicitamente:
    NORI_PASTE_OVERWRITE=1 nori-paste-sh path/script.sh

Examples / Exemplos:
  nori-paste-sh bootstrap_server

  nori-paste-sh scripts/server/deploy_check.sh

  NORI_PASTE_OVERWRITE=1 nori-paste-sh scripts/server/deploy_check.sh

  nori-paste-sh --uninstall
EOF
}

timestamp() {
  date +%Y%m%d-%H%M%S
}

die() {
  echo "ERRO: $*" >&2
  exit 1
}

uninstall_self() {
  local removed=0

  echo "==> Desinstalando / Uninstalling nori-paste-sh..."

  if [ -e "$HOME/.local/bin/nori-paste-sh" ]; then
    rm -f "$HOME/.local/bin/nori-paste-sh"
    echo "[OK] Removido / Removed: $HOME/.local/bin/nori-paste-sh"
    removed=1
  fi

  if [ -e "/usr/local/bin/nori-paste-sh" ]; then
    if [ "$(id -u)" -eq 0 ]; then
      rm -f "/usr/local/bin/nori-paste-sh"
    else
      sudo rm -f "/usr/local/bin/nori-paste-sh"
    fi
    echo "[OK] Removido / Removed: /usr/local/bin/nori-paste-sh"
    removed=1
  fi

  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ] && grep -Fq "# Added by nori-paste-sh installer" "$rc_file"; then
      sed -i '/^# Added by nori-paste-sh installer$/d; /^export PATH="\$HOME\/\.local\/bin:\$PATH"$/d' "$rc_file"
      echo "[OK] Entrada de PATH limpa em / PATH entry cleaned in: $rc_file"
      removed=1
    fi
  done

  if [ "$removed" -eq 0 ]; then
    echo "[INFO] Nenhuma instalação ativa encontrada / No active installation found."
  else
    echo
    echo "[OK] nori-paste-sh desinstalado com sucesso / uninstalled successfully."
    echo "[INFO] Rode 'hash -r' se quiser limpar o cache da sessão atual / Run 'hash -r' to clear current shell cache."
  fi
}

if [ "$#" -gt 1 ]; then
  die "use apenas um argumento de destino."
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "--uninstall" ]; then
  uninstall_self
  exit 0
fi

ARG="${1:-nori-paste}"
STAMP="$(timestamp)"

case "$ARG" in
  ""|.|..)
    die "destino inválido: $ARG"
    ;;
esac

# Modo path: absoluto, relativo com subpasta, ./, ../ ou nome terminando em .sh.
if [[ "$ARG" == /* || "$ARG" == ./* || "$ARG" == ../* || "$ARG" == */* || "$ARG" == *.sh ]]; then
  if [[ "$ARG" == /* ]]; then
    DEST="$ARG"
  else
    DEST="$PWD/$ARG"
  fi

  DEST_DIR="$(dirname "$DEST")"
  DEST_BASE="$(basename "$DEST")"

  [ "$DEST_BASE" = "." ] && die "destino inválido: $ARG"
  [ "$DEST_BASE" = ".." ] && die "destino inválido: $ARG"

  mkdir -p "$DEST_DIR"

  if [ -e "$DEST" ] && [ "${NORI_PASTE_OVERWRITE:-0}" != "1" ]; then
    if [[ "$DEST_BASE" == *.* ]]; then
      NAME="${DEST_BASE%.*}"
      EXT="${DEST_BASE##*.}"
      DEST="$DEST_DIR/${NAME}-${STAMP}.${EXT}"
    else
      DEST="$DEST_DIR/${DEST_BASE}-${STAMP}.sh"
    fi

    echo "[NORI][WARN] Destino já existia. Salvando cópia com timestamp:"
    echo "  $DEST"
    echo
  fi
else
  SAFE_NAME="${ARG%.sh}"
  DEST="$HOME/${SAFE_NAME}-${STAMP}.sh"
  mkdir -p "$(dirname "$DEST")"
fi

echo "[NORI] Capturando script em:"
echo "  $DEST"
echo
echo "[NORI] Cole o bloco inteiro agora."
echo "[NORI] Quando terminar, pressione Ctrl+D."
echo

cat > "$DEST"

chmod +x "$DEST"

echo
echo "[NORI] Arquivo recebido:"
ls -lh "$DEST"

echo
echo "[NORI] Linhas/bytes:"
wc -l -c "$DEST"

echo
echo "[NORI] SHA256:"
sha256sum "$DEST"

echo
echo "[NORI] Validando sintaxe bash..."
bash -n "$DEST"

echo "[OK] Sintaxe bash OK."
echo

echo "[NORI] Para revisar:"
echo "  nano '$DEST'"
echo

echo "[NORI] Para executar:"
echo "  bash '$DEST'"
NORI_PASTE_EOF

chmod 0755 "$TARGET"

echo
echo "===== VALIDAÇÃO ====="
ls -lh "$TARGET"
"$TARGET" --help >/dev/null

echo "[OK] nori-paste-sh instalado / installed."

if [ "$TARGET_DIR" = "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$TARGET_DIR:"*)
      echo "[OK] $TARGET_DIR já está no PATH. Pode invocar direto: nori-paste-sh"
      ;;
    *)
      PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
      UPDATED_RC=""

      for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc_file" ] || [ "$rc_file" = "$HOME/.bashrc" ]; then
          touch "$rc_file"
          if ! grep -Fq '$HOME/.local/bin' "$rc_file" && ! grep -Fq "$TARGET_DIR" "$rc_file"; then
            {
              echo ""
              echo "# Added by nori-paste-sh installer"
              echo "$PATH_LINE"
            } >> "$rc_file"
            UPDATED_RC="$UPDATED_RC $rc_file"
          fi
        fi
      done

      echo
      if [ -n "$UPDATED_RC" ]; then
        echo "[OK] PATH configurado automaticamente em:$UPDATED_RC"
      else
        echo "[INFO] $TARGET_DIR já estava no arquivo de profile, mas ainda não ativo nesta sessão."
      fi
      echo "[INFO] Para usar imediatamente nesta aba do terminal, rode:"
      echo "  source ~/.bashrc"
      echo "  (Novos terminais já carregarão automaticamente)"
      ;;
  esac
else
  echo "[OK] Instalado globalmente em $TARGET_DIR. Pode invocar direto: nori-paste-sh"
fi
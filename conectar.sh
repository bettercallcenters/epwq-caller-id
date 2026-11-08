#!/usr/bin/env bash
# Conecta un equipo (tableta, teléfono o esta Mac) con el CRM.
#
# Por qué existe: el 2026-10-30 la clave del CRM salió de index.html — estaba en texto plano y
# este repositorio es PÚBLICO. Desde entonces cada equipo guarda la suya en su propio navegador,
# y reconectar uno era pedirle la clave a Hector y pegarla a mano. Esto lo deja en un comando.
#
# La clave NUNCA se imprime en pantalla: se copia al portapapeles dentro del enlace. Así no
# queda en el historial de la terminal ni en una captura.
#
#   ./conectar.sh             → copia el enlace al portapapeles
#   ./conectar.sh --abrir     → lo abre aquí mismo (para conectar ESTA Mac)
#   ./conectar.sh --telefono  → para conectar un teléfono o tableta SIN portapapeles
set -euo pipefail

# Que NUNCA se muera callado. La primera version se salia sin imprimir una sola linea y desde
# afuera parecia que no habia hecho nada; el 2026-11-08 costo media hora de ida y vuelta.
trap 'c=$?; [ $c -ne 0 ] && echo "conectar.sh se detuvo (codigo $c). Corre: bash -x ./conectar.sh $*" >&2; exit $c' EXIT

APP="https://bettercallcenters.github.io/epwq-caller-id/"
BACKEND="${BACKEND_DIR:-$HOME/sdcc-integrations}"

if ! command -v railway >/dev/null 2>&1; then
  echo "Falta el CLI de Railway:  brew install railway  (y luego 'railway login')" >&2; exit 1
fi
[ -d "$BACKEND" ] || { echo "No encontré el backend en $BACKEND" >&2; exit 1; }

# La clave vive en las variables del backend en Railway, no en ningún archivo de este repo.
#
# Sin `head` y con `|| true` a proposito. Antes era `... | sed ... | head -1` y con
# `pipefail` eso es una trampa: cuando head cierra la tuberia antes de tiempo, railway muere
# con SIGPIPE, la tuberia cuenta como fallida, `set -e` mata el script AHI — antes de llegar
# al mensaje de error de abajo. Salia sin imprimir nada y de forma intermitente, que es la
# peor manera de fallar. awk corta solo en la primera coincidencia y el `|| true` deja que el
# control llegue siempre al chequeo de abajo.
#
# Nada de tuberias con lector que corta: PRIMERO se guarda la salida completa, DESPUES se
# busca la linea. Es el mismo patron que si tumbo el script mas abajo (ver RUTA): con
# `pipefail` + `set -e`, un lector que cierra antes de tiempo mata al que escribe con SIGPIPE
# y el script se sale en seco. Aqui no habia fallado todavia, pero era cuestion de tiempo.
RAW="$( { cd "$BACKEND" && railway variables --kv 2>/dev/null; } || true )"
TOK="$(awk '/^INGEST_TOKEN=/ && !visto { sub(/^INGEST_TOKEN=/, ""); print; visto = 1 }' <<< "$RAW" || true)"

if [ -z "$TOK" ]; then
  echo "No pude leer INGEST_TOKEN de Railway." >&2
  echo "Revisa que estés dentro del proyecto correcto:  cd $BACKEND && railway status" >&2
  exit 1
fi

LINK="${APP}#t=${TOK}"

# Para el telefono: una pagina chiquita en la red local que REBOTA al enlace de verdad.
#
# El portapapeles no sirve para esto. Copias el enlace en la Mac, tomas una captura para
# enseñarlo, y la captura se lleva el portapapeles — paso tres de cada tres veces. Aqui no hay
# nada que copiar: en el telefono se teclea una direccion corta y cae directo en la app ya
# conectada.
#
# La clave NO se teclea ni se enseña: viaja sola en el rebote y solo por tu WiFi. La pagina
# vive en una direccion al azar, se apaga en cuanto alguien la usa, y a los 3 minutos aunque
# nadie entre.
if [ "${1:-}" = "--telefono" ]; then
  IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
  [ -n "$IP" ] || { echo "No halle la IP del WiFi. Esta la Mac conectada a la red?" >&2; exit 1; }
  # od lee 2 bytes EXACTOS y termina; tr lee hasta el final. Antes era
  # `tr -dc a-z0-9 </dev/urandom | head -c 4` y ahi estaba la falla: head cierra la tuberia a
  # los 4 bytes, tr muere de SIGPIPE leyendo /dev/urandom, pipefail lo cuenta como error y
  # `set -e` mata el script en seco — codigo 141, sin una sola linea impresa.
  RUTA="$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
  PUERTO=8765
  echo "En el telefono, en Safari, teclea esto y dale enter:"
  echo
  echo "      http://${IP}:${PUERTO}/${RUTA}"
  echo
  echo "   Cae directo en la app ya conectada — no hay nada que pegar."
  echo "   (se apaga sola al usarla, o a los 3 minutos)"
  echo
  # El token viaja por el entorno y no por argv: lo de argv lo ve cualquiera con 'ps'.
  # El servidor vive en su propio archivo — incrustado aqui dentro de python3 -c, cualquier
  # comilla simple del HTML cerraba la cadena del shell y la pagina salia partida.
  LINK="$LINK" RUTA="$RUTA" PUERTO="$PUERTO" python3 "$(dirname "$0")/conectar-servidor.py"
  echo "   Servidor apagado."
  exit 0
fi

# Abrirlo aqui es el camino corto cuando el equipo a conectar es esta misma Mac: no hay nada
# que pegar y nada que se pueda pisar.
if [ "${1:-}" = "--abrir" ]; then
  open "$LINK"
  echo "✅ Lo abrí en el navegador. Cuando cargue, el aviso rojo se quita solo."
  echo "   (la clave es de ${#TOK} caracteres y no se muestra)"
else
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$LINK" | pbcopy
    # Comprobar que de verdad quedó: si otra cosa se adueña del portapapeles, mejor enterarse
    # aquí que descubrirlo pegando en la tableta.
    if [ "$(pbpaste 2>/dev/null)" = "$LINK" ]; then
      echo "✅ Enlace copiado al portapapeles (clave de ${#TOK} caracteres, no se muestra)."
      echo
      echo "   PÉGALO YA, antes de copiar cualquier otra cosa — si copias algo más se pierde"
      echo "   y hay que volver a correr esto."
      echo
      echo "   · En la tableta o el teléfono: mándatelo por WhatsApp y ábrelo allá."
      echo "   · En esta Mac: no hace falta pegar nada, corre  ./conectar.sh --abrir"
    else
      echo "⚠️  No se pudo dejar en el portapapeles (algo más lo está usando)." >&2
      echo "    Corre  ./conectar.sh --abrir  para abrirlo directo aquí." >&2
      exit 1
    fi
  else
    echo "Esta máquina no tiene pbcopy. Corre  ./conectar.sh --abrir" >&2
    exit 1
  fi
fi

echo
echo "Para comprobar: el aviso '⚠️ Este equipo no está conectado al CRM' se quita,"
echo "y la siguiente cita ya no dice 'CRM ✗'."

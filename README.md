# EPWQ · Identificador de Llamadas

Herramienta interna para identificar al **dueño de casa en tiempo real** cuando entra una llamada, y armar el **mensaje de cita** automático.

**Usuarios:** Guillermo · Divine · Hector Sandoval

## Qué hace
- 📞 **RingCentral** embebido (softphone). Cuando entra una llamada, autollena el número.
- 🏠 Cambia entre **EPCAD** (El Paso, TX) y **Doña Ana** (Las Cruces, NM).
- 📍 **Autocompletar de direcciones** (Google Places si hay API key; si no, OpenStreetMap gratis).
- 🏷️ **Buscar dueño**: copia la dirección y abre el portal oficial (pegas con ⌘V / Ctrl+V).
- 🔎 **USPhonebook** por número de un clic.
- 📝 **Mensaje de cita** automático en el formato del equipo + copiar / prellenar SMS.

## Configurar Google Places (opcional, calidad Google Maps)
1. Crea una API key en Google Cloud → habilita **Places API**.
2. En **Application restrictions** elige *HTTP referrers* y agrega el dominio de esta página (la URL de GitHub Pages). Restringe la key a *Places API*.
3. Pega la key en `index.html` → variable `GOOGLE_KEY`.

## Configurar RingCentral en producción (opcional)
Para quitar el letrero "FOR DEMO PURPOSES ONLY" y subir límites, registra una app en RingCentral y agrega tu `clientId` en el `adapter.js` dentro de `index.html`.

## Conectar un equipo con el CRM

Si sale el aviso rojo **"Este equipo no está conectado al CRM — las citas NO se guardan ahí"**,
ese navegador no tiene la clave. Las citas siguen saliendo al grupo de WhatsApp, pero **no se
guardan en el CRM**: no aparecen en el tablero, no se le asignan a ningún vendedor y no les
entran los recordatorios.

Desde el 2026-10-30 la clave ya no vive en `index.html` — estaba en texto plano y este
repositorio es público. Cada equipo guarda la suya en su propio navegador.

Para conectar uno:

```
./conectar.sh --abrir      # conectar ESTA Mac (se abre solo, nada que pegar)
./conectar.sh --telefono   # conectar un teléfono o tableta (sin portapapeles)
./conectar.sh              # solo copiar el enlace al portapapeles
```

`--telefono` levanta una página en tu WiFi que rebota al enlace real. En el teléfono tecleas
una dirección corta (`http://192.168.x.x:8765/ab12`) y cae directo en la app ya conectada. Se
apaga sola en cuanto alguien entra, o a los 3 minutos. Existe porque el portapapeles no sirve
para esto: copias el enlace en la Mac, tomas una captura, y la captura se lleva el
portapapeles.

Saca la clave de las variables del backend en Railway y arma el enlace `#t=<clave>`. **Nunca la
imprime**: va dentro del enlace al portapapeles, para que no quede en el historial de la
terminal ni en una captura de pantalla.

Si prefieres a mano: botón **🔗 CRM** → pegar el `INGEST_TOKEN`.

Ojo: se guarda por navegador. Otro navegador, modo privado, o limpiar los datos del sitio =
hay que reconectar. Cada tableta y cada teléfono, una vez cada uno.

## Correr local
```
python3 -m http.server 5178 --directory .
# abre http://localhost:5178
```

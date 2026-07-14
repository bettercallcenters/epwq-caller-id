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

## Correr local
```
python3 -m http.server 5178 --directory .
# abre http://localhost:5178
```

FROM node:18-alpine

# Impostiamo la directory di lavoro
WORKDIR /usr/src/app

# Copiamo i file di definizione delle dipendenze
COPY package*.json ./

# Installiamo le dipendenze
# Nota: Eseguito ancora come root per non avere problemi di permessi in scrittura globali
RUN npm install --legacy-peer-deps

# Copiamo il resto del codice sorgente
# Grazie al .dockerignore, qui non verranno copiati .env o node_modules locali
COPY . .

# FIX SONARQUBE (Sicurezza):
# 1. Cambiamo il proprietario della cartella /usr/src/app all'utente 'node'.
#    Senza questo, l'utente 'node' non potrebbe leggere/scrivere nella cartella creata da root.
RUN chown -R node:node /usr/src/app

# 2. Cambiamo l'utente attuale da 'root' a 'node'.
#    Da qui in poi, ogni comando (e l'app stessa) girerà con permessi limitati.
USER node

EXPOSE 3000

CMD ["npm", "start"]
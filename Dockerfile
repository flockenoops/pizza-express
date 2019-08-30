FROM thredup/node:8.4.0
WORKDIR /var/www/pizza-express
COPY ./package.json /var/www/pizza-express/
RUN npm install
COPY . .
EXPOSE 3000
CMD node server.js

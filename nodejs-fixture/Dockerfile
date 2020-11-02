FROM mhart/alpine-node:15

WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --only=production

# Bundle app source
COPY . .

EXPOSE 3000

CMD [ "node", "node.js" ]

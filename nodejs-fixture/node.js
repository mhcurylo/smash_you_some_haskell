'use strict';
const fastify = require('fastify')({
  logger: false
})

const { Pool, Client } = require('pg')

const pool = new Pool({
  user: 'admin',
  host: process.env.PSQL_SERVICE_HOST ? process.env.PSQL_SERVICE_HOST : '0.0.0.0',
  database: 'db',
  password: 'admin',
  port: 5432,
  max: process.env.PSQL_CONNECTIONS ? process.env.PSQL_CONNECTIONS : 80
})

const itemFromRow = i => ({ itemId: parseInt(i.itemid), itemMsg: i.itemmsg, itemTitle: i.itemtitle })

fastify.get('/item', function (request, reply) {

  pool
     .query('SELECT * FROM item LIMIT 100')
     .then(res => res.rows.map(itemFromRow))
     .then(res => reply.send(res))
      .catch(console.log);
})

fastify.get('/item/:itemId', function (request, reply) {

  pool
     .query('SELECT * FROM item WHERE itemid = $1', [parseInt(request.params.itemId)])
     .then(res => res.rows.map(itemFromRow))
     .then(res => res[0] ? reply.send(res) : reply.code(404))
      .catch(console.log);
})


fastify.get('/wait/:waitTime', function (request, reply) {
  setTimeout(() => reply({waitResult: "Did wait, yeah, " + request.prams.waitTime}), parseInt(request.params.waitTime))
})

// Run the server!
fastify.listen(3000,'0.0.0.0', function (err, address) {
  if (err) {
    fastify.log.error(err)
    process.exit(1)
  }
  fastify.log.info(`server listening on ${address}`)
})

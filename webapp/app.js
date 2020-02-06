// Read config
require('dotenv').config()

const geoserverUrl = process.env.GEOSERVER_URL
const dataFromBrowser = process.env.DATA_FROM_BROWSER_DIR
const dataToClient = process.env.DATA_TO_CLIENT_DIR

// File system
const fs = require('fs')

// Express server
const express = require('express')
require('pug')

const app = express()
const expressPort = 3000

app.listen(expressPort, () => {
  console.log(`GEOSERVER_URL:         ${process.env.GEOSERVER_URL}`)
  console.log(`DATA_FROM_BROWSER_DIR: ${process.env.DATA_FROM_BROWSER_DIR}`)
  console.log(`DATA_TO_CLIENT_DIR:    ${process.env.DATA_TO_CLIENT_DIR}\n`)
  console.log(`App listening on port ${expressPort}`)
})

// Static files
app.use(express.static('public'))

// Views (using Pug template engine)
app.set('views', './views')
app.set('view engine', 'pug')

// Routing - see functions below
app.get('/', appRoot)
app.post('/launch', appLaunch)
app.post('/display', appDisplay)
app.post('/query', appQuery)
app.post('/exit', appExit)
app.post('/request', appRequest)
app.post('/select_location', appSelectLocation)

// Websocket server
const server = require('http').createServer()
const io = require('socket.io')(server)

const websocketPort = 3001

io.on('connection', client => {
  console.log('Client connected')
  // client.on('event', (data) => { })
  client.on('disconnect', () => {
    console.log('Client disconnected')
  })
})
server.listen(websocketPort)

/****** Communication with the backend and the client ******/

let fileWatcher

function appRoot(req, res) {
  let options = {
    geoserverUrl,
    lat: 20.291320,
    lon: 85.817298
  }
  res.render('launch', options)
}

async function appSelectLocation(req, res) {
  const message = await readRequestFromClient(req, res)
  console.log(message)

  fs.writeFile(`${dataFromBrowser}/selection.geojson`, JSON.stringify(message.data), ec)
}

async function appRequest(req, res) {
  const message = await readRequestFromClient(req, res)
  console.log(message)

  writeMessageToFile('request', message)

  fileWatcher = readMessageFromFile((message) => {
    io.emit('response', message)
    fileWatcher.close()
  })
}

async function appLaunch(req, res) {
  const message = await readRequestFromClient(req, res)
  console.log(message)

  writeMessageToFile('launch', message.module)

  fileWatcher = readMessageFromFile((message) => {
    io.emit('launch_response', message)
    fileWatcher.close()
  })
}

async function appDisplay(req, res) {
  const message = await readRequestFromClient(req, res)
  console.log(message)

  writeMessageToFile('display', message.map)

  fileWatcher = readMessageFromFile((message) => {
    io.emit('display_response', message)
    fileWatcher.close()
  })
}

async function appQuery(req, res) {
  const message = await readRequestFromClient(req, res)
  console.log(message)

  writeMessageToFile('query', message.map)

  fileWatcher = readMessageFromFile((message) => {
    io.emit('query_response', message)
    fileWatcher.close()
  })
}

async function appExit(req, res) {
  console.log('EXIT')
  writeMessageToFile('EXIT')
}

/****** Utility functions ******/

async function readRequestFromClient(req, res) {
  let body = ''

  req.on('data', chunk => {
    body += chunk.toString()
  })

  return await new Promise((resolve, reject) => {
    req.on('end', () => {
      res.end('ok')
      resolve(JSON.parse(body))
    })
  })
}

function writeMessageToFile(filename, msg) {
  fs.writeFile(`${dataFromBrowser}/${filename}`, msg, ec)
}

function readMessageFromFile(callback) {
  const watcher = fs.watch(dataToClient, {}, (eventType, filename) => {
    if (eventType === 'change') {
      let message = fs.readFileSync(`${dataToClient}/${filename}`, { encoding: 'utf-8' })
      callback(message)
    }
  })
  return watcher
}

// error callback
function ec(error) {
  if (error) throw error
}

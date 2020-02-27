// Read config
require('dotenv').config()

const geoserverUrl = process.env.GEOSERVER_URL
const websocketUrl = process.env.WEBSOCKET_URL
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
  console.log(`GEOSERVER_URL:         ${geoserverUrl}`)
  console.log(`WEBSOCKET_URL:         ${websocketUrl}`)
  console.log(`DATA_FROM_BROWSER_DIR: ${dataFromBrowser}`)
  console.log(`DATA_TO_CLIENT_DIR:    ${dataToClient}\n`)
  console.log(`App listening on port ${expressPort}`)
})

// Static files
app.use(express.static('public'))

// Views (using Pug template engine)
app.set('views', './views')
app.set('view engine', 'pug')

// index page
app.get('/', (req, res) => {
  let options = {
    geoserverUrl,
    websocketUrl,
    lat: 20.291320,
    lon: 85.817298
  }
  res.render('launch', options)
})

// request to launch a module
app.post('/launch', async (req, res, next) => {
  const message = await readRequestFromClient(req, res)

  console.log('launch: ' + message.module)
  writeMessageToFile('launch', message.module)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// request to display a map
app.post('/display', async (req, res, next) => {
  const message = await readRequestFromClient(req, res)

  console.log('display: ' + message.map)
  writeMessageToFile('display', message.map)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// request to query a map
app.post('/query', async (req, res, next) => {
  const message = await readRequestFromClient(req, res)

  console.log('query: ' + message.map)
  writeMessageToFile('query', message.map)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// user interaction, e.g. through a modal
app.post('/request', async (req, res, next) => {
  const message = await readRequestFromClient(req, res)

  console.log('request: ' + message)
  writeMessageToFile('request', message)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// file upload
app.post('/file_request', async (req, res, next) => {
  const message = await readRequestFromClient(req, res)

  console.log('request: ' + message)
  // TODO: do smth

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// send a GeoJSON
app.post('/select_location', async (req, res, next) => {
  const message = await readRequestFromClient(req, res)

  console.log(message)
  fs.writeFile(`${dataFromBrowser}/selection.geojson`, JSON.stringify(message.data), ec)
})

// request to kill the app
app.post('/exit', async (req, res, next) => {
  console.log('EXIT')
  writeMessageToFile('request_EXIT')
})

/*
 * Request handler
 */
async function readRequestFromClient(req, res) {
  let body = ''

  req.on('data', chunk => {
    body += chunk.toString()
  })

  return await new Promise((resolve, reject) => {
    req.on('end', () => {
      resolve(JSON.parse(body))
    })
  })
}

/*
 * Write a text message to the data_from_browser directory
 */
function writeMessageToFile(filename, msg) {
  fs.writeFileSync(`${dataFromBrowser}/${filename}`, msg, ec)
}

/*
 * Create a self-destroying watcher to read messages in the data_to_browser directory
 */
async function readMessageFromFile(timeout) {
  return await new Promise((resolve, reject) => {
    const watcher = fs.watch(dataToClient, {}, (eventType, filename) => {
      console.log(eventType, filename)

      const filepath = `${dataToClient}/${filename}`

      if (eventType === 'change' || eventType === 'rename') {
        let message
        try {
          message = fs.readFileSync(filepath, { encoding: 'utf-8' })
          fs.unlinkSync(filepath, ec)
        } catch (e) {
          console.log(e)
        }
        watcher.close()
        resolve(message)
      }
    })

    setTimeout(() => {
      watcher.close()
      reject()
    }, timeout || 60000)
  })
}

// error callback
function ec(error) {
  if (error) throw error
}

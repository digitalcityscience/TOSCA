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

// Middleware
const bodyParser = require('body-parser')
const jsonParser = bodyParser.json()
const multer = require('multer')
const uploadParser = multer()

app.listen(expressPort, () => {
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
    lat: 53.55,
    lon: 10
  }
  res.render('launch', options)
})

// request to launch a module
app.post('/launch', jsonParser, async (req, res, next) => {
  writeMessageToFile('launch', req.body.launch)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// request to display a map
app.post('/display', jsonParser, async (req, res, next) => {
  writeMessageToFile('display', req.body.display)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// request to query a map
app.post('/query', jsonParser, async (req, res, next) => {
  writeMessageToFile('query', req.body.query)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// user interaction, e.g. through a modal
app.post('/request', jsonParser, async (req, res, next) => {
  writeMessageToFile('request', req.body.msg)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// file upload
app.post('/file_request', uploadParser.single('file'), async (req, res, next) => {
  const writer = fs.createWriteStream(`${dataFromBrowser}/${req.file.originalname}`)
  writer.write(req.file.buffer, async (error) => {
    if (error) throw error

    writer.close()

    try {
      const response = await readMessageFromFile(20000)
      res.send(response)
    } catch (e) {
      next('Server is unresponsive')
    }
  })
})

// send a GeoJSON
app.post('/select_location', jsonParser, async (req, res) => {
  writeMessageToFile('selection.geojson', JSON.stringify(req.body))

  try {
    const response = await readMessageFromFile(10000)
    res.send(response)
  } catch (e) {
    console.error('Server is unresponsive')
  }
})

// request to kill the app
app.post('/exit', async () => {
  writeMessageToFile('EXIT', 'EXIT')
})

/*
 * Write a text message to the data_from_browser directory
 */
function writeMessageToFile(filename, msg) {
  console.log(`echo "${msg}" > ${filename}`)
  fs.writeFileSync(`${dataFromBrowser}/${filename}`, msg, ec)
}

/*
 * Create a self-destroying watcher to read messages in the data_to_browser directory
 */
async function readMessageFromFile(timeout) {
  return await new Promise((resolve, reject) => {
    let trying = true

    // After a timeout (default 10 s) stop waiting for messages
    setTimeout(() => {
      trying = false
      watcher.close()
      reject()
    }, timeout || 10000)

    // Watch the data_to_client directory for file system changes
    const watcher = fs.watch(dataToClient, {}, async (event, filename) => {
      console.log(event, filename)

      while (trying) {
        try {
          const filepath = `${dataToClient}/${filename}`
          const message = fs.readFileSync(filepath, { encoding: 'utf-8' })

          // If a change has been detected, return the contents of the changed file
          trying = false
          watcher.close()
          resolve({ message: JSON.parse(message), filename })
        } catch (e) {
          // Otherwise wait a moment and try again
          await new Promise((_resolve) => setTimeout(() => {
            _resolve()
          }, 100))
        }
      }
    })
  })
}

// error callback
function ec(error) {
  if (error) throw error
}

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
app.use('/lib/jquery', express.static('node_modules/jquery/dist'));
app.use('/lib/bootstrap', express.static('node_modules/bootstrap/dist'));
app.use('/lib/leaflet', express.static('node_modules/leaflet/dist'));
app.use('/lib/leaflet-draw', express.static('node_modules/leaflet-draw/dist'));

// Views (using Pug template engine)
app.set('views', './views')
app.set('view engine', 'pug')

// index page
app.get('/', (req, res) => {
  let options = {
    geoserverUrl,
    lat: 20.27,
    lon: 85.84,
  }
  res.render('launch', options)
})

// launch a module
app.post('/launch', jsonParser, async (req, res, next) => {
  writeMessageToFile('launch', req.body.launch)

  try {
    const response = await readMessageFromFile()
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// display a map
app.post('/display', jsonParser, async (req, res, next) => {
  writeMessageToFile('display', req.body.display)

  try {
    const response = await readMessageFromFile()
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// query a map
app.post('/query', jsonParser, async (req, res, next) => {
  writeMessageToFile('query', req.body.query)

  try {
    const response = await readMessageFromFile()
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// send generic request
app.post('/request', jsonParser, async (req, res, next) => {
  writeMessageToFile('request', req.body.msg)

  if (req.body.noCallback) {
    return
  }

  try {
    const response = await readMessageFromFile()
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
      const response = await readMessageFromFile()
      res.send(response)
    } catch (e) {
      next('Server is unresponsive')
    }
  })
})

// send a GeoJSON
app.post('/select_location', jsonParser, async (req, res, next) => {
  writeMessageToFile('selection.geojson', JSON.stringify(req.body))

  try {
    const response = await readMessageFromFile()
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// Poll server for updates (usually while processes are running)
app.post('/poll', jsonParser, async (req, res) => {
  try {
    // A status update is expected after one second
    const response = await readMessageFromFile(1200)
    res.send(response)
  } catch (e) {
    // Process has finished or aborted
    res.send({ processing: -1, filename: req.body.process })
  }
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
    // Stop waiting for messages after a timeout (default 10 s)
    setTimeout(() => {
      reject()
      watcher.close()
    }, timeout || 1000000)

    const watcher = fs.watch(dataToClient, {}, async (event, filename) => {
      console.log(`Got ${filename}`)

      try {
        const filepath = `${dataToClient}/${filename}`
        const contents = fs.readFileSync(filepath, { encoding: 'utf-8' })

        if (filename.match(/\.message$/)) {
          resolve({ message: JSON.parse(contents), filename })
          watcher.close()
        } else if (filename.match(/\.processing$/)) {
          resolve({ processing: parseInt(contents), filename })
          watcher.close()
        }
      } catch (e) {
        // ¯\_(ツ)_/¯
      }
    })
  })
}

// error callback
function ec(error) {
  if (error) throw error
}

// reload the page
function refreshPage(){
window.location.reload();
}

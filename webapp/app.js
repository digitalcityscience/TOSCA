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
const urlencodedParser = bodyParser.urlencoded({ extended: false })
const multer  = require('multer')
const uploadParser = multer()

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
app.post('/launch', urlencodedParser, async (req, res, next) => {
  console.log('launch: ' + req.body.module)
  writeMessageToFile('launch', req.body.module)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// request to display a map
app.post('/display', urlencodedParser, async (req, res, next) => {
  console.log('display: ' + req.body.map)
  writeMessageToFile('display', req.body.map)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// request to query a map
app.post('/query', urlencodedParser, async (req, res, next) => {
  console.log('query: ' + req.body.map)
  writeMessageToFile('query', req.body.map)

  try {
    const response = await readMessageFromFile(2000)
    res.send(response)
  } catch (e) {
    next('Server is unresponsive')
  }
})

// user interaction, e.g. through a modal
app.post('/request', urlencodedParser, async (req, res, next) => {
  console.log('request: ' + req.body)
  writeMessageToFile('request', req.body)

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
      const response = await readMessageFromFile(2000)
      res.send(response)
    } catch (e) {
      next('Server is unresponsive')
    }
  })
})

// send a GeoJSON
app.post('/select_location', uploadParser.single('geojson'), async (req, res, next) => {
})

// request to kill the app
app.post('/exit', async () => {
  console.log('EXIT')
  writeMessageToFile('request_EXIT')
})


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

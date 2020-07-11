// Read config
require('dotenv').config()

const dataFromBrowser = process.env.DATA_FROM_BROWSER_DIR
const geoserverUrl = process.env.GEOSERVER_URL
const lat = process.env.INITIAL_LAT || 0
const lon = process.env.INITIAL_LON || 0

// File system
const fs = require('fs')

// Express server
const express = require('express')
require('pug')
const app = express()
const expressPort = 3000

// Middleware
const jsonParser = require('body-parser').json()
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
    lat,
    lon
  }
  res.render('launch', options)
})

// modules
const AddLocationModule = require('./scripts/add_location')
const AddMapModule = require('./scripts/add_map')
const SetSelectionModule = require('./scripts/set_selection')
const SetResolutionModule = require('./scripts/set_resolution')
const ModuleOne = require('./scripts/module_1')

const modules = {
  add_location: new AddLocationModule(),
  add_map: new AddMapModule(),
  set_selection: new SetSelectionModule(),
  set_resolution: new SetResolutionModule(),
  module_1: new ModuleOne()
}

// launch a module
app.post('/launch', jsonParser, (req, res, next) => {
  try {
    res.send(modules[req.body.launch].launch())
  } catch (err) {
    next(err)
  }
})

// display a map
// app.post('/display', jsonParser, async (req, res, next) => {
// })

// query a map
// app.post('/query', jsonParser, async (req, res, next) => {
// })

// message request
app.post('/reply', jsonParser, (req, res, next) => {
  try {
    const module = modules[req.query.message_id.split('.')[0]]
    const message = module.process(req.body.msg, req.query.message_id)

    if (message) {
      res.send(message)
    }
  } catch (err) {
    next(err)
  }
})

// file upload
app.post('/file', uploadParser.single('file'), (req, res, next) => {
  try {
    const module = modules[req.query.message_id.split('.')[0]]
    const file = `${dataFromBrowser}/${req.file.originalname}`
    const writer = fs.createWriteStream(file)

    writer.write(req.file.buffer, (error) => {
      if (error) {
        throw error
      }
      writer.close()

      const message = module.processFile(file, req.query.message_id)

      if (message) {
        res.send(message)
      }
    })
  } catch (err) {
    next(err)
  }
})

// send a GeoJSON
app.post('/drawing', jsonParser, (req, res, next) => {
  try {
    const module = modules[req.query.message_id.split('.')[0]]
    const file = `${dataFromBrowser}/drawing.geojson`

    fs.writeFileSync(file, JSON.stringify(req.body.data))
    res.send(module.processFile(file, req.query.message_id))
  } catch (err) {
    next(err)
  }
})

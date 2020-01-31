const express = require('express')
require('pug')
require('dotenv').config()

const app = express()
const port = 3000

// Config values
const geoserverUrl = process.env.GEOSERVER_URL

// Static files
app.use(express.static('public'))

// Views (using Pug template engine)
app.set('views', './views')
app.set('view engine', 'pug')

// Routes
app.get('/', (req, res) => {
  let options = {
    geoserverUrl,
    lat: 20.291320,
    lon: 85.817298
  }
  res.render('launch', options)
})

app.listen(port, () => console.log(`App listening on port ${port}`))

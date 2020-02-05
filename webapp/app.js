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
app.post('/launch', async (req, res) => {
  const message = await receiveResponse(req, res)
  console.log(message)
})
app.post('/display', async (req, res) => {
  const message = await receiveResponse(req, res)
  console.log(message)
})
app.post('/query', async (req, res) => {
  const message = await receiveResponse(req, res)
  console.log(message)
})

app.listen(port, () => console.log(`App listening on port ${port}`))

/*
 * Wait for the request to complete, then return its message
 */
async function receiveResponse(req, res) {
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

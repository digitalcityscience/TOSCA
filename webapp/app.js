const express = require('express')
require('pug')

const app = express()
const port = 3000

// Static files
app.use(express.static('public'))

// Views (using Pug template engine)
app.set('views', './views')
app.set('view engine', 'pug')

// Routes
app.get('/', (req, res) => res.send('Hello World!'))
app.get('/location_selector', (req, res) => {
  res.render('location_selector', { title: 'Hey', message: 'Hello there!' })
})

app.listen(port, () => console.log(`App listening on port ${port}`))

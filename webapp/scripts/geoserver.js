const axios = require('axios')

const geoServer = axios.create({
  baseURL: process.env.GEOSERVER_URL,
  auth: {
    username: process.env.GEOSERVER_USERNAME,
    password: process.env.GEOSERVER_PASSWORD
  }
})

module.exports = {
  async addDatastore(workspaceName, body) {
    const res = await geoServer.post(`/rest/workspaces/${workspaceName}/datastores`, body)
    return res.data
  }
}

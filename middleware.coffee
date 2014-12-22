module.exports = (connect, options) ->
        express = require 'express'
        app = express()

        app.configure ->
                app.use express.logger 'dev'
                app.use express.bodyParser()
                app.use express.methodOverride()
                app.use express.errorHandler()
                app.use express.static options.base
                app.set('view engine', 'jade')
                app.listen 3000

        [connect(app)]
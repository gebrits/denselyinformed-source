scriptToPack_zepto =  [
	"src/documents/scripts/modernizr.js",
	"node_modules/foundation/js/vendor/zepto.js",
	# "node_modules/foundation/js/foundation/foundation.js",
	# "node_modules/foundation/js/foundation/foundation.topbar.js"
]

scriptToPack_jquery = [
	"src/documents/scripts/modernizr.js",
	"node_modules/foundation/js/vendor/jquery.js",
	"node_modules/foundation/js/foundation/foundation.js",
	"node_modules/foundation/js/foundation/foundation.topbar.js"
]


# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
docpadConfig = {

	# Skip Unsupported Plugins
    # Set to `false` to load all plugins whether or not they are compatible with our DocPad version or not
    skipUnsupportedPlugins: true  # default

	# =================================
	# Template Data
	# These are variables that will be accessible via our templates
	# To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

	templateData:

		# Specify some site properties
		site:


			# The production url of our website
			url: "http://website.com"

			# Here are some old site urls that you would like to redirect from
			oldUrls: [
				'www.website.com',
				'website.herokuapp.com'
			]

			# The default title of our website
			title: "Clearksykabove"
			company: "Clear Sky Above"

			# The website description (for SEO)
			description: """
				When your website appears in search results in say Google, the text here will be shown underneath your website's title.
				"""

			# The website keywords (for SEO) separated by commas
			keywords: """
				place, your, website, keywoards, here, keep, them, related, to, the, content, of, your, website
				"""

			# The website author's name
			author: "Your Name"

			# The website author's email
			email: "your@email.com"

			# Styles
			# NOTE: on big sites where css is considerable different from page to page, 
			styles: [
				"/styles/zurb-foundation.css",
				"/styles/style.css",
				"/styles/highlightjs-github.css"
				# "/styles/medium.css"
			]

			stylesPacked: "/styles/combined.min.css"

			# Scripts
			scripts: [
				# "/scripts/medium.js",
				"/scripts/app.js"
			]

		buildstep:
			scriptToPack_zepto: scriptToPack_zepto

			scriptToPack_jquery: scriptToPack_jquery

			scriptToPack_zepto_flattened: do () ->
				_ = require 'lodash'
				outarr =  []
				outPrefix = "/scripts"
				_.each scriptToPack_zepto, (path) ->
					outarr.push outPrefix + path.substring(path.lastIndexOf("/"))
				outarr

		# -----------------------------
		# Helper Functions

		# Get the prepared site/document title
		# Often we would like to specify particular formatting to our page's title
		# we can apply that formatting here
		getPreparedTitle: ->
			# if we have a document title, then we should use that and suffix the site's title onto it
			if @document.title
				"#{@document.title} | #{@site.title}"
			# if our document does not have it's own title, then we should just use the site's title
			else
				@site.title

		# Get the prepared site/document description
		getPreparedDescription: ->
			# if we have a document description, then we should use that, otherwise use the site's description
			@document.description or @site.description

		# Get the prepared site/document keywords
		getPreparedKeywords: ->
			# Merge the document keywords with the site keywords
			@site.keywords.concat(@document.keywords or []).join(', ')

		envIsDev: -> 
			# TODO: change based on https://github.com/bevry/docpad/issues/592
			return docpad.getConfig().env == "development" || docpad.getConfig().env == undefined

		getAssetVersion: ->
			return docpad.getConfig().assetVersion ;

		cachebust: (assets) -> 
			version =  @getAssetVersion();
			require("lodash").map(assets, (asset) -> asset + "?" + version)


		# Blog stuff
		getPreparedPublishDate: ->
			require("moment")(@document.date).format("MMMM Do, YYYY");


	# =================================
	# Collections
	# These are special collections that our website makes available to us

	collections:
		# list of documents which make up main nav. May be any content-type
		dcoumentsInMainNav: (database) ->
			database.findAllLive({includenInNavs: {$has: 'main'}}, [pageOrder:1,title:1])

		# All documents with contenttype=pages (i.e: directory reflects contenttype which seemed a logical choice)
		# ordered by pageOrder (not required) and title
		pages: (database) ->
			database.findAllLive({relativeOutDirPath: 'pages'}, [pageOrder:1,title:1])
			.on 'add', (model) ->
				model.setMetaDefaults({layout:'page'}) #may be overwritten
				model.getMeta().set({contenttype:'page'}) #always set to 'page'

		# All documents with contenttype=posts ordered by date
		# defaults to 'layout: post'
		# default to url based on sluggified title if that is set.
		# 
		# NOTE: events from http://documentcloud.github.io/backbone/#Collection
		posts: (database) ->

			# console.log(docpad);
			# console.log("SAME: "  + (database == docpad.getCollection('html')))
			# database.findAllLive({relativeOutDirPath: 'posts'}, [date:-1])
			
			database.findAllLive({relativeOutDirPath: 'posts'}, [date:-1])
			.on 'add', (model) ->
				model.setMetaDefaults({layout:'post'})
				model.getMeta().set({contenttype:'post'})
			
			# posts default to the sluggified title
			# NOTE: event for removal of explicit url not implemented (ideally we should default to 
			# url which may be stored in meta.urlFromTitle) since docpad doesn't 
			# trigger these events. On next generation of site all resolves ok again.
			.on 'add change:title', (model) ->
				t = model.get('title')
				if(t)
					url = "/posts/"  + t.replace(/\ /g,'-')

					explicit_url = model.getMeta().get("url")
					if explicit_url
						model.addUrl(url)
					else
						model.setUrl(url).setMetaDefaults(url:url)


		# All documents with contenttype=faqs ordered by faqOrder (not required) and title
		faqs: (database) ->
			database.findAllLive({relativeOutDirPath: 'faq'}, [faqOrder:1,title:1])
			.on 'add', (model) ->
				model.setMetaDefaults({layout:'faqpost'})
				model.getMeta().set({contenttype:'faqpost'})


	# =================================
	# Plugins

	plugins:
		sass:
			compass: true
			sassPath: "/var/lib/gems/1.9.1/gems/sass-3.2.10/bin/sass"
			scssPath: "/var/lib/gems/1.9.1/gems/sass-3.2.10/bin/scss"

	# =================================
	# DocPad Events

	# Here we can define handlers for events that DocPad fires
	# You can find a full listing of events on the DocPad Wiki
	events:

		# Server Extend
		# Used to add our own custom routes to the server before the docpad routes are added
		serverExtend: (opts) ->
			# Extract the server from the options
			{server} = opts
			docpad = @docpad

			# As we are now running in an event,
			# ensure we are using the latest copy of the docpad configuraiton
			# and fetch our urls from it
			latestConfig = docpad.getConfig()
			oldUrls = latestConfig.templateData.site.oldUrls or []
			newUrl = latestConfig.templateData.site.url

			# Redirect any requests accessing one of our sites oldUrls to the new site url
			server.use (req,res,next) ->
				if req.headers.host in oldUrls
					res.redirect(newUrl+req.url, 301)
				else
					next()

		#rough cache busting
		#NOTE: 
		#1. version not persisted to disk
		generateBefore: (opts, next) ->
			latestConfig = docpad.getConfig() 
			latestConfig.assetVersion =  ++latestConfig.assetVersion || 1;
			next();

		# Write After
		# Used to minify our assets with grunt
		writeAfter: (opts,next) ->

			docpad = @docpad
			latestConfig = docpad.getConfig()

			if !latestConfig.templateData.envIsDev()

				#minify js for static or production environments
				command = [
					"grunt", 
					'build:static', 
					"--scriptToPack_zepto=" + JSON.stringify(latestConfig.templateData.buildstep.scriptToPack_zepto),
					"--scriptToPack_jquery=" + JSON.stringify(latestConfig.templateData.buildstep.scriptToPack_jquery),
					"--stylesToPack=" + JSON.stringify(latestConfig.templateData.site.styles),
					"--stylesPacked=" + latestConfig.templateData.site.stylesPacked
				]
				
			else 

				#copy js files verbatim for development environment
				command = [
					"grunt", 
					'build:development', 
					"--scriptToPack_zepto=" + JSON.stringify(latestConfig.templateData.buildstep.scriptToPack_zepto)
				]
			
			# Prepare
			safeps = require('safeps')
			safeps.spawn(command, {safe:false, output:true}, next)

			# Chain
			@

}


# Export our DocPad Configuration
module.exports = docpadConfig
path = require 'path'

module.exports = (grunt) ->
	require('load-grunt-tasks')(grunt)
	require('time-grunt')(grunt)

	grunt.initConfig
		settings:
			siteDirectory: ''
			distDirectory: 'dist'
			srcDirectory: 'src'
			tempDirectory: '.temp'

		# Gets dependent components from bower
		# see bower.json file
		bower:
			install:
				options:
					cleanTargetDir: true
					copy: true
					layout: (type, component) ->
						console.log 'path:path:path:path:path:path:', type
						path.join type
					targetDir: 'bower_components'
			uninstall:
				options:
					cleanBowerDir: true
					copy: false
					install: false

		# Sets up a web server
		connect:
			app:
				options:
					base: '<%= settings.distDirectory %>'
					livereload: true
					middleware: require './middleware'
					open: true
					port: 10042

		# Deletes dist and .temp directories
		# The .temp directory is used during the build process
		# The dist directory contains the artifacts of the build
		# These directories should be deleted before subsequent builds
		# These directories are not committed to source control
		clean:
			working: [
				'<%= settings.tempDirectory %>'
				'<%= settings.distDirectory %>'
			]
			ci: [
				'<%= settings.ciDirectory %>'
			]
			options:
				force: true

		# Compiles CoffeeScript (.coffee) files to JavaScript (.js)
		coffee:
			app:
				files: [
					cwd: '<%= settings.tempDirectory %>'
					src: '**/*.coffee'
					dest: '<%= settings.tempDirectory %>'
					expand: true
					ext: '.js'
				,
					cwd: './routes/'
					src: '**/*.coffee'
					dest: './routes/'
					expand: true
					ext: '.js'
				]
				options:
					sourceMap: false

		# Lints CoffeeScript files
		coffeelint:
			app:
				files: [
					cwd: ''
					src: [
						'src/**/*.coffee'
						'!src/scripts/libs/**'
					]
				]
				options:
					indentation:
						value: 1
					no_tabs:
						level: 'ignore'
					max_line_length:
						level: 'ignore'
					no_throwing_strings:
						level: 'ignore'


		# Copies directories and files from one location to another
		copy:
			sourcemap:
				cwd: '<%= settings.tempDirectory %>'
				src: '**/*.min.js.map'
				dest: '<%= settings.distDirectory %>/scripts/libs'
				expand: true
				flatten: true
			app:
				files: [
					cwd: '<%= settings.srcDirectory %>'
					src: '**'
					dest: '<%= settings.tempDirectory %>'
					expand: true
				,
					cwd: 'bower_components'
					src: '**'
					dest: '<%= settings.tempDirectory %>'
					expand: true
				]
			dev:
				cwd: '<%= settings.tempDirectory %>'
				src: '**'
				dest: '<%= settings.distDirectory %><%= settings.siteDirectory %>'
				expand: true
			prod:
				files: [
					cwd: '<%= settings.tempDirectory %>'
					src: [
						'**/*.{eot,svg,ttf,woff}'
						'**/*.{gif,jpeg,jpg,png,svg,webp}'
						'index.html'
						'scripts/scripts.min.*.js'
						'styles/main.min.*.css'
					]
					dest: '<%= settings.distDirectory %>'
					expand: true
				]

		# Renames files based on their hashed content
		# When the files contents change, the hash value changes
		# Used as a cache buster, ensuring browsers load the correct static resources
		#
		# glyphicons-halflings.png -> glyphicons-halflings.6c8829cc6f.png
		# scripts.min.js -> scripts.min.6c355e03ee.js
		hash:
			images: '.temp/**/*.{gif,jpeg,jpg,png,svg,webp}'
			scripts:
				cwd: '.temp/scripts'
				src: [
					'scripts.min.js'
				]
				expand: true
			styles: '.temp/styles/main.min.css'

		# Compresses png files
		imagemin:
			images:
				files: [
					cwd: '<%= settings.tempDirectory %>'
					src: '**/*.{gif,jpeg,jpg,png}'
					dest: '<%= settings.tempDirectory %>'
					expand: true
				]
				options:
					optimizationLevel: 7

		# Compiles SASS (.scss) files to CSS (.css)
		sass:
			app:
				files: [{
					expand: true
					src: ['.temp/styles/**/*.less']
					ext: '.css'
				}]

		# Compiles LESS (.less) files to CSS (.css)
		less:
			app:
				files:
					'.temp/styles/main.css': '.temp/styles/main.less'
		
		# Compiles jade templates
		jade:
			views:
				cwd: '<%= settings.tempDirectory %>'
				src: '**/*.jade'
				dest: '<%= settings.tempDirectory %>'
				expand: true
				ext: '.html'
				options:
					pretty: true
			spa:
				cwd: '<%= settings.tempDirectory %>'
				src: 'index.jade'
				dest: '<%= settings.tempDirectory %>'
				expand: true
				ext: '.html'
				options:
					pretty: true	

		# Minifies index.html
		# Extra white space and comments will be removed
		# Content within <pre /> tags will be left unchanged
		# IE conditional comments will be left unchanged
		# Reduces file size by over 14%
		minifyHtml:
			prod:
				src: '.temp/index.html'
				ext: '.html'
				expand: true


		# Creates a file to push views directly into the $templateCache
		# This will produce a file with the following content
		#
		# angular.module('app').run(['$templateCache', function ($templateCache) {
		# 	$templateCache.put('/views/directives/tab.html', '<div class="tab-pane" ng-class="{active: selected}" ng-transclude></div>');
		# }]);
		#
		# This file is then included in the output automatically
		# AngularJS will use it instead of going to the file system for the views
		ngTemplateCache:
			views:
				files:
					'.temp/scripts/views.js': '.temp/**/*.html'
				options:
					trim: '<%= settings.tempDirectory %>'


		# Compiles underscore expressions
		#
		# The example below demonstrates the use of the environment configuration setting
		# In 'prod' build the hashed file of the concatenated and minified scripts is referened
		# In environments other than 'prod' the individual files are used and loaded with RequireJS
		#
		# <% if (config.environment === 'prod') { %>
		# 	<script src="<%= config.getHashedFile('.temp/scripts/scripts.min.js', {trim: '.temp'}) %>"></script>
		# <% } else { %>
		# 	<script data-main="/scripts/main.js" src="/scripts/libs/require.js"></script>
		# <% } %>
		template:
			indexDev:
				files:
					'.temp/index.html': '.temp/index.html'
					'.temp/index.jade': '.temp/index.jade'
			index:
				files: '<%= template.indexDev.files %>'
				environment: 'prod'


		# RequireJS optimizer configuration for both scripts and styles
		# This configuration is only used in the 'prod' build
		# The optimizer will scan the main file, walk the dependency tree, and write the output in dependent sequence to a single file
		# Since RequireJS is not being used outside of the main file or for dependency resolution (this is handled by AngularJS), RequireJS is not needed for final output and is excluded
		# RequireJS is still used for the 'dev' build
		# The main file is used only to establish the proper loading sequence
		requirejs:
			scripts:
				options:
					baseUrl: '.temp/scripts'
					findNestedDependencies: true
					logLevel: 0
					mainConfigFile: '.temp/scripts/main.js'
					name: 'main'
					# Exclude main from the final output to avoid the dependency on RequireJS at runtime
					onBuildWrite: (moduleName, path, contents) ->
						modulesToExclude = ['main']
						shouldExcludeModule = modulesToExclude.indexOf(moduleName) >= 0

						return '' if shouldExcludeModule

						contents
					optimize: 'uglify2'
					out: '.temp/scripts/scripts.min.js'
					preserveLicenseComments: false
					skipModuleInsertion: true
					uglify:
						# Let uglifier replace variables to further reduce file size
						no_mangle: false
					useStrict: true
					wrap:
						start: '(function(){\'use strict\';'
						end: '}).call(this);'
			styles:
				options:
					baseUrl: '.temp/styles/'
					cssIn: '.temp/styles/main.css'
					logLevel: 0
					optimizeCss: 'standard'
					out: '.temp/styles/main.min.css'

		# Creates main file for RequireJS
		shimmer:
			dev:
				cwd: '.temp/scripts'
				src: [
					'**/*.{coffee,js}'
					'!libs/angular-animate.{coffee,js}'
					'!libs/angular-route.{coffee,js}'
					'!libs/angular-resource.{coffee,js}'
					'!libs/require.{coffee,js}'
				]
				order: [
					'libs/angular.js'
					'NGAPP':
						'ngAnimate': 'libs/angular-animate.min.js'
						'ngRoute': 'libs/angular-route.min.js'
						'ngResource': 'libs/angular-resource.min.js'
				]
				require: 'NGBOOTSTRAP'
			prod:
				cwd: '<%= shimmer.dev.cwd %>'
				src: [
					'**/*.{coffee,js}'
					'!libs/angular-animate.{coffee,js}'
					'!libs/angular-mocks.{coffee,js}'
					'!libs/angular-route.{coffee,js}'
					'!libs/angular-resource.{coffee,js}'
					'!libs/require.{coffee,js}'
					'!backend/**/*.*'
				]
				order: [
					'libs/angular.js'
					'NGAPP':
						'ngAnimate': 'libs/angular-animate.min.js'
						'ngRoute': 'libs/angular-route.min.js'
						'ngResource': 'libs/angular-resource.min.js'
				]
				require: '<%= shimmer.dev.require %>'


		# Run tasks when monitored files change
		watch:
			basic:
				files: [
					'src/fonts/**'
					'src/images/**'
					'src/scripts/**/*.js'
					'src/styles/**/*.css'
					'src/**/*.html'
				]
				tasks: [
					'copy:app'
					'copy:dev'
					
				]
				options:
					livereload: true
					nospawn: true
			coffee:
				files: 'src/scripts/**/*.coffee'
				tasks: [
					'clean:working'
					'coffeelint'
					'copy:app'
					'shimmer:dev'
					'coffee:app'
					'copy:dev'
				]
				options:
					livereload: true
					nospawn: true
			jade:
				files: 'src/views/**/*.jade'
				tasks: [
					'copy:app'
					'jade:views'
					'copy:dev'
					#'karma'
				]
				options:
					livereload: true
					nospawn: true
			sass:
				files: 'src/styles/**/*.scss'
				tasks: [
					'copy:app'
					'sass'
					'copy:dev'
				]
				options:
					livereload: true
					nospawn: true
			less:
				files: 'src/styles/**/*.less'
				tasks: [
					'copy:app'
					'less'
					'copy:dev'
				]
				options:
					livereload: true
					nospawn: true
			spaHtml:
				files: 'src/index.html'
				tasks: [
					'copy:app'
					'template:indexDev'
					'copy:dev'
					#'karma'
				]
				options:
					livereload: true
					nospawn: true
			spaJade:
				files: 'src/index.jade'
				tasks: [
					'copy:app'
					'template:indexDev'
					'jade:spa'
					'copy:dev'
					#'karma'
				]
				options:
					livereload: true
					nospawn: true
			# test:
			# 	files: 'test/**/*.*'
			# 	tasks: [
			# 		'karma'
			# 	]
			# Used to keep the web server alive
			none:
				files: 'none'
				options:
					livereload: true

	# ensure only tasks are executed for the changed file
	# without this, the tasks for all files matching the original pattern are executed
	grunt.event.on 'watch', (action, filepath, key) ->
		file = filepath.substr(4) # trim "src/" from the beginning. Needs a better way of handling paths.
		dirname = path.dirname file
		ext = path.extname file
		basename = path.basename file, ext

		grunt.config ['copy', 'app'],
			cwd: 'src/'
			src: file
			dest: '.temp/'
			expand: true

		copyDevConfig = grunt.config ['copy', 'dev']
		copyDevConfig.src = file

		if key is 'coffee'
			# delete associated temp file prior to performing remaining tasks
			# without doing so, shimmer may fail
			grunt.config ['clean', 'working'], [
				path.join('.temp', dirname, "#{basename}.{coffee,js}") #,js.map}")
			]

			copyDevConfig.src = [
				path.join(dirname, "#{basename}.{coffee,js}") #,js.map}")
				'scripts/main.{coffee,js}' #,js.map}'
			]

			coffeeConfig = grunt.config ['coffee', 'app', 'files']
			coffeeConfig.src = file
			coffeeLintConfig = grunt.config ['coffeelint', 'app', 'files']
			coffeeLintConfig = filepath

			grunt.config ['coffee', 'app', 'files'], coffeeConfig
			grunt.config ['coffeelint', 'app', 'files'], coffeeLintConfig

		if key is 'spaJade'
			copyDevConfig.src = path.join(dirname, "#{basename}.{jade,html}")

		if key is 'jade'
			copyDevConfig.src = path.join(dirname, "#{basename}.{jade,html}")
			jadeConfig = grunt.config ['jade', 'views']
			jadeConfig.src = file

			grunt.config ['jade', 'views'], jadeConfig

		if key is 'less'
			copyDevConfig.src = [
				path.join(dirname, "#{basename}.{less,css}")
				path.join(dirname, 'styles.css')
			]

		if key is 'sass'
			copyDevConfig.src = [
				path.join(dirname, "#{basename}.{scss,css}")
				path.join(dirname, 'main.css')
			]

		grunt.config ['copy', 'dev'], copyDevConfig


	# Compiles the app with non-optimized build settings
	# Places the build artifacts in the dist directory
	# Enter the following command at the command line to execute this build task:
	# grunt build
	grunt.registerTask 'build', [
		'clean:working'
		'coffeelint'
		'copy:app'
		'template:indexDev'
		'jade'
		'shimmer:dev'
		'coffee:app'
		'less'
		'copy:dev'
		'copy:sourcemap'
	]

	# Compiles the app with non-optimized build settings
	# Places the build artifacts in the dist directory
	# Opens the app in the default browser
	# Watches for file changes, and compiles and reloads the web browser upon change
	# Enter the following command at the command line to execute this build task:
	# grunt or grunt default
	grunt.registerTask 'default', [
		'build'
		'connect'
		'watch'
	]



	# Compiles the app with non-optimized build settings
	# Places the build artifacts in the dist directory
	# Runs unit tests via karma
	# Enter the following command at the command line to execute this build task:
	# grunt test
	grunt.registerTask 'test', [
		'build'
		'karma'
	]


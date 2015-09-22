browserify  = require 'gulp-browserify'
concat      = require 'gulp-concat'
gulp        = require 'gulp'
gutil       = require 'gulp-util'
jeditor     = require 'gulp-json-editor'
less        = require 'gulp-less'
zip         = require 'gulp-zip'

Package     = require './package.json'


project =
  build:   './build/'
  dist:    './dist'
  src:     './app/**/*.coffee'
  static:  './static/**'
  index:   './static/index.html'
  style:   './style/index.less'
  manifest: './manifest.json'
  browserify:
    paths:      ['./src']
    transform:  ['coffeeify']
    entries:    ['./src/index.coffee']


require('vistar-gulp-tasks')(project)

gulp.task 'default', ['pack']
gulp.task 'build', ['src', 'static', 'style', 'manifest']

gulp.task 'src', ->
  gulp.src('./app/index.coffee',  read: false)
    .pipe(browserify({
      transform:  ['coffeeify']
      extensions: ['.coffee']
    }))
    .pipe(concat('app.js'))
    .pipe(gulp.dest(project.build))

gulp.task 'static', ->
  gulp.src(project.static)
    .pipe(gulp.dest(project.build))

gulp.task 'style', ->
  gulp.src(project.style)
    .pipe(less())
    .pipe(concat('app.css'))
    .pipe(gulp.dest(project.build))

gulp.task 'manifest', ->
  gulp.src(project.manifest)
    .pipe(jeditor((json) ->
      json.version = Package.version
      json
    )).pipe(gulp.dest(project.build))

gulp.task 'pack', ['build'], ->
  gulp.src("#{project.build}/**")
    .pipe(zip("#{Package.name}-#{Package.version}.zip"))
    .pipe(gulp.dest(project.dist))

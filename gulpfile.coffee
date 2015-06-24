gulp   = require 'gulp'
coffee = require 'gulp-coffee'
gutil  = require 'gulp-util'


project =
  dest:   './build/'
  src:    './src/**/*.coffee'
  static: './static/**'
  index:  './static/index.html'
  style:  './style/index.less'
  test:   './test/**/*_spec.coffee'
  browserify:
    paths: ['./src']
    transform: ['coffeeify']
    entries: ['./src/index.coffee']


require('vistar-gulp-tasks')(project)


gulp.task 'build', ->
  gulp.src project.src
    .pipe coffee(bare: true).on 'error', gutil.log
    .pipe gulp.dest project.dest

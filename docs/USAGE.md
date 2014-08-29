# Lingon usage

This document describes real use cases for Lingon. It starts by covering the basics and proceeds to more advanced uses. The usage documentation is work in progress. Please help out by documenting your use cases in a PR. Thanks!

## Build a basic project

One of the most basic projects imaginable looks like this: 

### Project structure

There's a lingon.js file and a source directory containing an index.html file.

	lingon.js
	source
		index.html

#### lingon.js
```js
var lingon = require('lingon');
```

In the lingon.js file we import the lingon module. When lingon is imported it will automatically start itself after the entire lingon.js file has been executed.


#### source/index.html

The HTML file contains the following: 

```html
<html>
  <body>
    <h1>Hello Lingon!</h1>
  </body>
</html>
```

### Building

In order to build this project with Lingon we first make the lingon.js file executable:

	chmod +x lingon.js

Then we run the file directly and pass the 'build' task as the first argument:

	./lingon.js build

The output of this command looks like:

```
$ ./lingon
[ Lingon ] Working directory: /absolute/path/to/project
[ Lingon ] source/index.html -> build/index.html
```

Lingon read the source directory and found the index.html file. It was then ouputted to ``./build/index.html``

### Serve the project locally

One of the primary features of Lingon is the built in http server. It allows you to serve the project locally and view it in your browser. Refreshing will trigger a rebuild, so you can work and instantly see your changes.

To start the built in http server, run: 

	./lingon.js server

The server "task" is the default in Lingon, so just running ``./lingon.js`` will also start the server.

## Render EJS templates

Lingon comes with out of the box support for EJS templates using the [gulp-ejs](https://github.com/rogeriopvl/gulp-ejs) module. 

Lingon can forward a "context" object to the EJS renderer that allows you to pass dynamic data to the ejs templates. All fields on the context object will be available for all templates during build.

**Example: lingon.js**

```js
var lingon = require('lingon');

lingon.context.name = "bob";
```

**Example: index.ejs**

```html
<html>
  <%= name %>
</html>
```

#### Different values during build & server
It's possible to pass different data to the server and build tasks by overriding data in the `serverConfigure` event. This way the title will be 'bob' during build and 'alice' when the server has started.

```js
var lingon = require('lingon');

lingon.context.name = "bob";

lingon.bind('serverConfigure', function() {
  lingon.context.name = "alice";
});
```

# Render templates inside layouts

EJS does not support layouts, so this feature has been added natively to Lingon. Lingon supports templates when using `ejs`, `html` or `md` documents. It's possible to mix them, for instance: a Markdown document can be rendered inside a html template.

**Limitation:** Layouts can't be rendered inside other layouts.

## Render a simple html layout

Let's render a homepage template inside an index layout.

This example has the following structure: 

	lingon.js
	source
		_layouts
			index.html
		home.html

#### File: source/_layouts/index.html

The layout is a regular html file that defines an inline lingon yield directive. The yield directive will be replaced with the contents of the template. 

**important: It needs to be on it's own line.**

```html
<html>
  <head></head>
  <body>
    <!-- lingon: yield -->
  </body>
</html>
```

#### File: source/home.html

The template uses a lingon layout directive to define a template to render inside. The path to the template can be either relative from the template file or absolute from the lingon sourcePath.

```html
<!-- lingon: layout '_layouts/index.ejs' -->
<h1>Welcome</h1>
<p>This is a website.</p>
```

## Render a md file inside a html template

Easy! Follow the above example, but change the home.html template to a Markdown document.

**File: source/home.md**

```markdown
<!-- lingon: layout '_layouts/index.ejs' -->
# Welcome

This is a website.
```

## Advanced Lingon configurations

#### Allowing the usage of directives (includes) in additional file types
If you want to use directives (includes) in your own custom file extensions you can just add them.
By default the following file types are registered: `['.js', '.less', '.css', '.ejs', '.html', '.md']`

```js
var lingon = require('lingon');

lingon.validDirectiveFileTypes.push('.ngt', '.coffee');
```

#### Register processors

Use `lingon.preProcessors` and `lingon.postProcessor` to access lingon's processors and invoke `set`, `push`, `unshift` or `remove`. The arguments are

1. a single file extension string or an array of mulitple
2. an optional regular expression that matches the file name for conditional processors (more about that in the next section)
3. a factory function that will create the stream pipes

The factory function gets passed in two configuration variables when executed: the first one is a context that is seperate for each processed file. The second one is a global one and is shared between all files/processors.
This function then returns a single (or an array of multiple) stream modifiers that will be piped one after another to their respective files.

```js
var lingon = require('lingon');
var ngHtml2js = require('lingon-ng-html2js');
var uglify = require('gulp-uglify');
var less = require('gulp-less');

// registering a new preprocessor and adding it to the end of the file type's processor chain
lingon.preProcessors.push('ngt', function(context, globals) {
  // return a single stream modifier
  return ngHtml2js({ base: 'source' });
});

// registering a new postprocessor and adding it to the beginning of the file type's processor chain
lingon.postProcessors.unshift('js', function(context, globals) {
  // return an array of stream modifiers
  return [
    uglify({ outSourceMap: true })
  ];
});

// registering a new postprocessor and overwriting any existing ones for the file type
lingon.postProcessors.set('less', function(context, globals) {
  // return an array of stream modifiers
  return [
    less()
  ];
});
```

#### Register conditional processor

Sometimes a processor is wanted only under certain conditions so the `push` and `unshift` functions accept an optional regular expression before the factory function. Only file names that meet this regular expression will register the processor.

Additionally some processors are only needed in certain tasks, in that case we can make use of the `lingon.task` variable that contains the name of the current running task to return the array of stream modifiers.

```js
var lingon = require('lingon');
var uglify = require('gulp-uglify');

// only process files that do not contain ".min" in their name
lingon.postProcessors.push('js', /^((?!\.min).)*$/, function() {
  var processors = [];

  if(lingon.task == 'build') {
    processors.push(
      uglify({ outSourceMap: true })
    );
  }

  return processors;
});
```

#### Register tasks
Use `lingon.registerTask('<TASKNAME>', fn, infoObject)` to register a new task. The first argument is the tasks name and it will be used when invoking it from the command line (lingon <TASKNAME>). This is followed by the task function. It gets passed in a callback argument that should be invoked after the task is done so lingon knows when to execute the next task in the queue. The last argument is an info object that will be displayed in the lingon help menu, it consists of a simple general message about the task and then lists all possible arguments with a short description.

```js
var lingon = require('lingon');
var imagemin = require('gulp-imagemin');
var pngcrush = require('imagemin-pngcrush');

// add lingon task to optimize images directly in the source folder
// execute task via "lingon imagemin"
lingon.registerTask('imagemin', function(callback) {
  lingon.sourcePath += '/images';
  lingon.buildPath = lingon.sourcePath;

  var optimizeImages = function(params) {
    return imagemin({
      progressive: true,
      svgoPlugins: [{removeViewBox: false}],
      use: [pngcrush()]
    });
  };
  lingon.postProcessors.add(['jpg', 'jpeg', 'png', 'gif', 'svg'], optimizeImages);

  lingon.build(callback, null);
}, {
  message: 'Optimize images (directly in the source folder!)',
  arguments: {
    // 'v': 'Run in verbose mode' // this argument is made up for example purposes
  }
});

```

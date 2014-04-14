'use strict';

var ProcessorStore = function(processors) {
  this.processors = processors || {};
  var that = this;

  return function(extension, pathMatches, factory) {
    if(!pathMatches) {
      return {
        list: function(path) {
          return that.list(extension, path);
        },
        set: function(pathMatchesScoped, factoryScoped) {
          return that.set(extension, pathMatchesScoped, factoryScoped);
        },
        add: function(pathMatchesScoped, factoryScoped) {
          return that.add(extension, pathMatchesScoped, factoryScoped);
        }
      };
    }

    return that.set(extension, pathMatches, factory);
  };
};

// lists all processors. Can be filtered by extension and matching path
ProcessorStore.prototype.list = function(extension, path) {
  if(!extension) {
    return this.processors;
  }
  if(!path) {
    return this.processors[extension];
  }

  var filteredProcessors = this.processors[extension] || [];
  filteredProcessors = filteredProcessors.filter(function(item) {
    return item.pathMatches === null || !!path.match(item.pathMatches);
  });

  return filteredProcessors;
};

// overwrites all processors for a given file extension
ProcessorStore.prototype.set = function(extension, pathMatches, factory) {
  this.processors[extension] = [];

  this.add(extension, pathMatches, factory);

  return this;
};

// adds a processor for the given file extension
ProcessorStore.prototype.add = function(extension, pathMatches, factory) {
  pathMatches = pathMatches || null;
  if(typeof pathMatches === 'function') {
    factory = pathMatches;
    pathMatches = null;
  }

  this.processors[extension] = this.processors[extension] || [];
  this.processors[extension].push({pathMatches: pathMatches, pipe: factory});

  return this;
};



module.exports = ProcessorStore;

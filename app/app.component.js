(function(app) {
  app.AppComponent =
    ng.core.Component({
      selector: 'my-app',
      template: '<h1>My First Angular 2 App</h1><textarea rows="25" cols="120"></textarea>'
    })
    .Class({
      constructor: function() {}
    });
})(window.app || (window.app = {}));

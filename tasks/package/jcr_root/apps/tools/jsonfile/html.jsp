<html>
<head>
    <script src="https://code.angularjs.org/2.0.0-beta.17/Rx.umd.js"></script>
    <script src="https://code.angularjs.org/2.0.0-beta.17/angular2-polyfills.js"></script>
    <script src="https://code.angularjs.org/2.0.0-beta.17/angular2-all.umd.dev.js"></script>  

    <script>

        var HelloWorldComponent = function() {};

        HelloWorldComponent.annotations = [
        new ng.core.Component({
            selector: 'hello-world',
            template: '<h1>Import tab seperated strings to a CQ5 page</h1>'
        })
        ]; 

        var Version = ng.core.Component({
            selector: 'version',
            template: '<div><label>select store version:</label><select><option *ngFor="let i of verisons">{{i}}</option></select></div>'
        }).Class({
            constructor: function() {
                this.verisons = ["current store" , "X store"];
            }
        });

        var Cq5Path = ng.core.Component({
            selector: 'cq-path',
            template: '<div><label>Choose the page you want to import to:</label><input required pattern="^/content(.*)" type="text">'
        }).Class({
            constructor: function() {

            }
        });

        function cqPathValidator(control) {
            return '{"cq5path" : true}'
        }


        var HelloFlentApi = ng.core.Component({
        selector: 'hello-fluent',
            template: '<textarea [(ngModel)]="name" rows="20" cols="120"></textarea><br/><button type="buttton" (click)="import($event)">Import</button>',
        }).Class({
            constructor: function() {
                this.name = "";
            },
            import : function(event) {
                console.log(this.name);
            }
        });

        var AppComponent = ng.core.Component({
        selector: 'company-app',
            template: '<form><hello-world></hello-world><version></version><cq-path></cq-path>' + 
            '<hello-fluent></hello-fluent></form>',  
        	directives: [HelloWorldComponent, HelloFlentApi, Version, Cq5Path]
        }).Class({
        	constructor: function() {}
        });

        document.addEventListener("DOMContentLoaded", function() {
            ng.platform.browser.bootstrap(AppComponent);
        });

    </script>

</head>
<body>
    <company-app>
        Loading ...
    </company-app>
</body>
</html>

'use strict';

module.exports = function(grunt) {
  grunt.initConfig({
    cqconfig: {
        "packageName": "sparta-import-json-components",
        "encoding": "utf-8",
        "packageDestinationPath": "tmp/cq5",
        "defaultsAppsCrxPath": "/apps/tools/jsonfile"
    },
    clean: {
      test: ['tmp']
    },
    copy: {
        'cq5-base': {
            expand: true,
            dot: true,
            cwd: 'tasks/package',
            src: '**',
            dest: '<%= cqconfig.packageDestinationPath %>'
        },
        'client': {
            expand: true,
            dot: true,
            src: ["index.html"],
            dest: '<%= cqconfig.packageDestinationPath %>/jcr_root/apps/tools/jsonfile',
        },
        'assets': {
            expand: true,
            dot: true,
            src: [  "import-form.html","styles.css","jsoneditor/dist/jsoneditor.min.js",
                    "jsoneditor/dist/jsoneditor.min.css","jsoneditor/dist/img/**",
                    "node_modules/core-js/client/shim.min.js","node_modules/zone.js/dist/zone.js","node_modules/reflect-metadata/Reflect.js","node_modules/rxjs/bundles/Rx.umd.js",
                    "node_modules/@angular/core/bundles/core.umd.js","node_modules/@angular/common/bundles/common.umd.js","node_modules/@angular/compiler/bundles/compiler.umd.js",
                    "node_modules/@angular/platform-browser/bundles/platform-browser.umd.js","node_modules/@angular/platform-browser-dynamic/bundles/platform-browser-dynamic.umd.js",
                    "node_modules/@angular/http/bundles/http.umd.js","node_modules/@angular/forms/bundles/forms.umd.js"],
            dest: '<%= cqconfig.packageDestinationPath %>/jcr_root/apps/tools/jsonfile' 
        }
    },
    replace: {
        paths: {
            options: {
                variables: {
                    "packageName": "<%= cqconfig.packageName %>",
                    "encoding": "<%= cqconfig.encoding %>",
                    "packageDestinationPath": "<%= cqconfig.packageDestinationPath %>",
                    "defaultsAppsCrxPath": "<%= cqconfig.defaultsAppsCrxPath %>",
                }
            },
            files: [{
                expand: true,
                dot: true,
                cwd: 'tasks/package/META-INF/vault',
                src: ['**'],
                dest: '<%= cqconfig.packageDestinationPath %>/META-INF/vault/'
            }]
        }
    },
    compress: {
        zip: {
            options: {
                archive: function() {
                    return 'tmp/sparta-import-json-components.zip';
                }
            },
            files: [{
                expand: true,
                dot: true,
                cwd: '<%= cqconfig.packageDestinationPath %>',
                src: ['**/*']}
            ]}
    }
  });

  grunt.loadTasks('tasks');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-compress');
  grunt.loadNpmTasks('grunt-replace');
  grunt.loadNpmTasks('grunt-contrib-rename');

  grunt.registerTask('test', ['clean', 'copy', 'replace:paths', 'compress:zip']);
  grunt.registerTask('default', ['test']);
};

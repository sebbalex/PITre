﻿/*jslint unparam: true, browser: true, devel: true */
/*global define*/

define(function () {
    'use strict';

    var module = {},
        noop = function () { },
        console = window.console || { log: noop },
        supportsFileApi;

    // Upload manager constructor:
    function UploadManager(options) {
        var self = this;
        self.dropContainer = options.dropContainer;
        self.inputField = options.inputField;
        self.uploadsQueue = [];
        self.activeUploads = 0;
        self.firstUpload = true;
        self.data = options.data;
        self.key = options.key;
        self.maxSimultaneousUploads = options.maxSimultaneousUploads || -1;
        self.onFileAdded = options.onFileAdded || noop;
        self.uploadUrl = options.uploadUrl;
        self.onFileAddedProxy = function (upload) {
           //console.log('Event: onFileAdded, file: ' + upload.fileName);
            self.onFileAdded(upload);
        };

        self.initialize();
    }

    // FileUpload proxy class:
    function FileUpload(file) {
        var self = this;

        self.file = file;
        self.fileName = file.name;
        self.fileSize = file.size;
        self.uploadSize = file.size;
        self.uploadedBytes = 0;
        self.eventHandlers = {};
        self.events = {
            onProgress: function (fileSize, uploadedBytes) {
                var progress = uploadedBytes / fileSize * 100;
               //console.log('Event: upload onProgress, progress = ' + progress + ', fileSize = ' + fileSize + ', uploadedBytes = ' + uploadedBytes);
                (self.eventHandlers.onProgress || noop)(progress, fileSize, uploadedBytes);
            },
            onStart: function () {
               //console.log('Event: upload onStart');
                (self.eventHandlers.onStart || noop)();
            },
            onCompleted: function (data) {
               //console.log('Event: upload onCompleted, data = ' + data);
                file = null;
                (self.eventHandlers.onCompleted || noop)(data);
            }
        };
    }

    FileUpload.prototype = {
        on: function (eventHandlers) {
            this.eventHandlers = eventHandlers;
        }
    };

    UploadManager.prototype = {

        initialize: function () {
           //console.log('Initializing upload manager');
            var manager = this,
                dropContainer = manager.dropContainer,
                inputField = manager.inputField,
                cancelEvent = function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                },
                dragOverOnClass = function(e){
                    cancelEvent(e);
                    dropContainer.classList.add('drag-over');
                },
                dragOverOffClass = function(e){
                    cancelEvent(e);
                    dropContainer.classList.remove('drag-over');
                };

            if (dropContainer) {
                /*
                 * Original code
                manager.on(dropContainer, 'dragover', cancelEvent);
                manager.on(dropContainer, 'dragenter', cancelEvent);
                manager.on(dropContainer, 'drop', function (e) {
                    cancelEvent(e);
                    manager.processFiles(e.dataTransfer.files);
                });
                */
                
                manager.on(dropContainer, 'dragenter', dragOverOnClass);
                manager.on(dropContainer, 'dragover', dragOverOnClass);
                manager.on(dropContainer, 'dragleave', dragOverOffClass);
                manager.on(dropContainer, 'drop', function (e) {
                    cancelEvent(e);
                    dragOverOffClass(e);
                    manager.processFiles(e.dataTransfer.files);
                });
            }

            if (inputField) {
                manager.on(inputField, 'change', function () {
                    manager.processFiles(this.files);
                });
            }
        },

        processFiles: function (files) {
           //console.log('Processing files: ' + files.length);
            var manager = this,
                len = files.length,
                file,
                upload,
                i;
            for (i = 0; i < len; i += 1) {
                file = files[i];
                if (file.size === 0) {
                    alert('Files with files size zero cannot be uploaded or multiple file uploads are not supported by your browser');
                    break;
                }

                upload = new FileUpload(file);
                manager.uploadFile(upload);
            }
        },

        uploadFile: function (upload) {
            var manager = this;

            manager.onFileAdded(upload);

            // Queue upload if maximum simultaneous uploads reached:
            if (manager.activeUploads === manager.maxSimultaneousUploads) {
               //console.log('Queue upload: ' + upload.fileName);
                manager.uploadsQueue.push(upload);
                return;
            }

            manager.ajaxUpload(upload);
        },

        ajaxUpload: function (upload) {
            var manager = this,
                xhr,
                formData,
                fileName,
                file = upload.file,
                prop,
                data = manager.data,
                key = manager.key || 'file';

           //console.log('Beging upload: ' + upload.fileName);
            if (manager.firstUpload) {
               //console.log('First file uploaded: ' + upload.fileName);
                if (!data) {
                    data = { First: true }
                } else {
                    data.First = true;
                }
                manager.firstUpload = false;
            } else {
                data.First = false;
            }
            manager.activeUploads += 1;

            xhr = new window.XMLHttpRequest();
            formData = new window.FormData();
            fileName = file.name;

            xhr.open('POST', manager.uploadUrl);
            xhr.setRequestHeader('Accept', 'application/json, text/javascript', '*/*');

            // Triggered when upload starts:
            xhr.upload.onloadstart = function () {
                // File size is not reported during start!
               //console.log('Upload started: ' + fileName);
                upload.events.onStart();
            };

            // Triggered many times during upload:
            xhr.upload.onprogress = function (event) {
                if (!event.lengthComputable) {
                    return;
                }

                // Update file size because it might be bigger than reported by the fileSize:
                upload.events.onProgress(event.total, event.loaded);
            };

            // Triggered when upload is completed:
            xhr.onload = function (event) {
               //console.log('Upload completed: ' + fileName);

                // Reduce number of active uploads:
                manager.activeUploads -= 1;

                upload.events.onCompleted(event.target.responseText);

                // Check if there are any uploads left in a queue:
                if (manager.uploadsQueue.length) {
                    manager.ajaxUpload(manager.uploadsQueue.shift());
                }
            };

            // Triggered when upload fails:
            xhr.onerror = function () {
               //console.log('Upload failed: ', upload.fileName);
            };

            // Append additional data if provided:
            if (data) {
                for (prop in data) {
                    if (data.hasOwnProperty(prop)) {
                       //console.log('Adding data: ' + prop + ' = ' + data[prop]);
                        formData.append(prop, data[prop]);
                    }
                }
            }

            // Append file data:
            formData.append(key, file);

            // Initiate upload:
            xhr.send(formData);
        },

        // Event handlers:
        on: function (element, eventName, handler) {
            if (!element) {
                return;
            }
            if (element.addEventListener) {
                element.addEventListener(eventName, handler, false);
            } else if (element.attachEvent) {
                element.attachEvent('on' + eventName, handler);
            } else {
                element['on' + eventName] = handler;
            }
        }
    };

    module.fileApiSupported = function () {
        if (typeof supportsFileApi !== 'boolean') {
            var input = document.createElement("input");
            input.setAttribute("type", "file");
            supportsFileApi = !!input.files;
        }

        return supportsFileApi;
    };

    module.initialize = function (options) {
        return new UploadManager(options);
    };

    module.onEnabled = function (url, callback) {

        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.onload = function () {
            try {
                if (xhr.status === 200) {
                    callback();
                } else {
                   //console.log(xhr.statusText);
                }
            } catch (error) {
               //console.log(error);
            }
        };
        xhr.onerror = function () {
            try {
               //console.log(xhr.statusText);
            } catch (error) {
               //console.log(error);
            }
        };

        try {
            xhr.send();
        } catch (error) {
           //console.log(error);
        }

    };

    return module;
});

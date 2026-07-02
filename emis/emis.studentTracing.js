
$(function () {
    emis.CreateNamespace('studentTracing');

    (function (context) {

        context.Title = 'Student Tracing';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {

                var vm = ko.mapping.fromJS(options.data);
                vm.IsRegistrationNoVerified = ko.observable(false);
                vm.StudentFullName = ko.observable('');
                vm.DateOfBirth = ko.observable('');
                vm.HasCenterInCurrentDistrict = ko.observable(true);

                vm.searchByRegNo = function () {
                    if (!$('#searchForm').valid()) {
                        return false
                    }
                    vm.IsRegistrationNoVerified(false);
                    var regNo = vm.RegistrationNo();
                    if (regNo.length > 0) {
                        context.LoadStudentInfoByRegNo(regNo, function (response) {
                            vm.IsRegistrationNoVerified(true);
                            vm.StudentFullName(response.Data.StudentFullName);
                            vm.DateOfBirth(response.Data.BirthDateBS);
                            vm.StudentRegistrationId(response.Data.StudentRegistrationID);
                        });
                    } else {
                        //do something
                    }
                }

                vm.CurrentDistrictId.subscribe(function (newValue) {
                    if (newValue) {
                        ajaxRequest('/Cascade/GetTracingCentersByDistrict', 'POST', { data: { districtId: newValue } }, function (response) {
                            if (response.IsSuccess) {
                                vm.Centers(response.Data.Records);
                                vm.HasCenterInCurrentDistrict(response.Data.HasCenterInCurrentDistrict);
                            } else {
                                showMessage(context.Title, response.Message, 'error')
                                vm.Centers([]);
                                vm.HasCenterInCurrentDistrict(response.Data.HasCenterInCurrentDistrict);
                            }
                        })
                    } else {
                        vm.Centers([]);
                    }
                })

                vm.RenderComplete = function (elements, data) {
                    $('#form').validate({
                        rules: {
                            RegistrationNo: { required: true },
                            ContactNo: { required: true },
                            Email: { required: true },
                            CurrentDistrictId: { required: true },
                            DataCollectionCenterId: { required: true },
                        }
                    })
                    context.InitializeFileUpload()
                }

                vm.Submit = function () {
                    context.Save();
                }


                return vm;
            }
        };

        context.LoadStudentInfoByRegNo = function (registrationNo, successCallback) {
            ajaxRequest('/Registration/Default/GetStudentRegNo', 'POST', { data: { registrationNo: registrationNo } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.ApplicationViewModel);
                    if (successCallback) {
                        successCallback(response);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.Save = function () {
            if (!$('#form').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel);
            delete model.Districts;

            ajaxRequest('/Student/Tracing/Index', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {

                    showMessage(context.Title, response.Message, 'success', function () {
                        window.location = '/LandingPage'
                    });
                } else {

                    showMessage(context.Title, response.Message, 'error', function () {
                    });
                }
            });
        }

        context.Initialize = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel = ko.mapping.fromJS(model, context.Mapping);

                ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, context.Mapping, context.ViewModel);
            }
        }

        //
        context.InitializeFileUpload = function (selector = '.upload', maxSize = 1073741824, allowedFileTypes = '["image/png", "image/jpeg"]', oncomplete = null) {
            context.DynamicFileUploadAllowedTypes = JSON.parse(allowedFileTypes);
            $(selector).upload({
                maxSize: maxSize,
                beforeSend: context.onBeforeSend,
                action: '/FileUpload/Upload/',
                postKey: 'uploadFile',
                label: 'Select Document to upload',
                postData: {}
            }).on("start.upload", context.onStart)
                .on("complete.upload", context.onComplete)
                .on("filestart.upload", context.onFileStart)
                .on("fileprogress.upload", context.onFileProgress)
                .on("filecomplete.upload", function (e, file, response) {
                    if (oncomplete != null) {
                        oncomplete(e, file, response);
                    } else {
                        context.onFileComplete(e, file, response)
                    }
                })
                .on("fileerror.upload", context.onFileError)
                .on("chunkstart.upload", context.onChunkStart)
                .on("chunkprogress.upload", context.onChunkProgress)
                .on("chunkcomplete.upload", context.onChunkComplete)
                .on("chunkerror.upload", context.onChunkError)
                .on("queued.upload", context.onQueued);
        };

        context.onCancel = function (e) {
            console.log("Cancel");
            var index = $(this).parents("li").data("index");
            $(this).parents("form").find(".upload").upload("abort", parseInt(index, 10));
        };

        context.onCancelAll = function (e) {
            console.log("Cancel All");
            $(this).parents("form").find(".upload").upload("abort");
        };

        context.onBeforeSend = function (formData, file) {
            console.log("Before Send");
            formData.append("test_field", "test_value");
            var isValid = context.DynamicFileUploadAllowedTypes.indexOf(file.file.type) >= 0// === 'image/png' || file.file.type === 'image/jpeg';
            if (!isValid) {
                showMessage(context.Title, 'Invalid File Type. Only Png or JPEG is supported.', 'error');
                return false;
            }
            return formData; // cancel all jpgs
        };

        context.onQueued = function (e, files) {
            console.log("Queued");
            var html = '';
            for (var i = 0; i < files.length; i++) {
                html += '<li data-index="' + files[i].index + '"><span class="content"><span class="file">' + files[i].name + '</span><span class="cancel">Cancel</span><span class="progress">Queued</span></span><span class="bar"></span></li>';
            }

            $(this).parents("form").find(".filelist.queue")
                .append(html);
        }

        context.onStart = function (e, files) {
            console.log("Start");
            if (files && files[0]) {
                // context.displayImagePreview(files[0], 'photoId');
            }
            $(this).parents("form").find(".filelist.queue")
                .find("li")
                .find(".progress").text("Waiting");
        }

        context.onComplete = function (e) {
            console.log("Complete");
            // All done!

        }

        context.onFileStart = function (e, file) {
            console.log("File Start");
            $(this).parents("form").find(".filelist.queue")
                .find("li[data-index=" + file.index + "]")
                .find(".progress").text("0%");
        }

        context.onFileProgress = function (e, file, percent) {
            console.log("File Progress");
            var $file = $(this).parents("form").find(".filelist.queue").find("li[data-index=" + file.index + "]");

            $file.find(".progress").text(percent + "%")
            $file.find(".bar").css("width", percent + "%");
        }

        context.onFileComplete = function (e, file, response) {
            var responseObj = eval('(' + response + ')') || {};
            if (responseObj.IsSuccess && responseObj.Data) {

                var uploadContext = $(e.target).attr('data-context');
                switch (uploadContext) {
                    case 'Citizenship':
                        context.ViewModel.CitizenshipUserAttachmentId(responseObj.Data.Id);
                        $("#photoImagePreview_citizenship").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                        break;
                    case 'RecommendationLetter':
                        context.ViewModel.RecommendationLetterUserAttachmentId(responseObj.Data.Id);
                        $("#photoImagePreview_recommendationLetter").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                        break;
                    default:
                        context.DynamicFileUploadComplete(e, responseObj.Data)

                }
            }
        }

        context.onFileError = function (e, file, error) {
            console.log("File Error");
            $(this).parents("form").find(".filelist.queue")
                .find("li[data-index=" + file.index + "]").addClass("error")
                .find(".progress").text("Error: " + error);
        }

        context.onChunkStart = function (e, file) {
            console.log("Chunk Start");
        }

        context.onChunkProgress = function (e, file, percent) {
            console.log("Chunk Progress");
        }

        context.onChunkComplete = function (e, file, response) {
            console.log("Chunk Complete");
        }

        context.onChunkError = function (e, file, error) {
            console.log("Chunk Error");
        }



    })(emis.studentTracing);
});
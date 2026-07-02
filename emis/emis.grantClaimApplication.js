$(function () {
    emis.CreateNamespace('grantClaimApplication');

    (function (context) {

        context.Title = 'Grant Claim Application';
        context.CreateFormId = '#frm';
        context.ViewModel = {};

        context.GrantClaimApplicationStatus = {
            Pending: 0,
            Verified: 1,
            Rejected: 2
        };

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SaveProfile = function () {
                    context.SaveProfile();
                };
                vm.SaveFacultyStatus = function () {
                    context.SaveFacultyStatus();
                };

                vm.RenderComplete = function () {
                    context.ApplyValidation();
                };

                vm.tabRenderComplete = function () {
                    $('.nav-tabs a:first').tab('show')
                }

                vm.FacultyStatusRenderComplete = function () {
                    $('#facultyStatusForm').validate({
                        rules: {
                            NoOfFullTimeTeacher: { required: true, min: 1 },
                            NoOfPartTimeTeacher: { required: true, min: 0 },
                            NoOfStaff: { required: true, min: 1 },
                            NoOfProgram: { required: true, min: 1 },
                            OnlineClassMethod: { required: true },
                            EmailIdForFacultyStatus: { required: true },
                            EmailIdForStudentStatus: { required: true },
                            EmailIdForTeacherStatus: { required: true },
                            ICTSupport1: { required: true },
                        }
                    })
                }

                vm.ActivityStatusRenderComplete = function (elements, $data) {
                    context.InitializeFileUpload($(elements).find(".upload"));
                    $('#activityStatusForm').validate({
                        rules: {
                            NoOfFullTimeTeacher: { required: true, min: 1 },
                            NoOfPartTimeTeacher: { required: true, min: 0 },
                            NoOfStaff: { required: true, min: 1 },
                            NoOfProgram: { required: true, min: 1 },
                            OnlineClassMethod: { required: true },
                            EmailIdForFacultyStatus: { required: true },
                            EmailIdForStudentStatus: { required: true },
                            EmailIdForTeacherStatus: { required: true },
                            ICTSupport1: { required: true },
                        }
                    })
                }

                vm.profileRenderComplete = function (elements, $data) {
                    context.InitializeFileUpload($(elements).find(".upload"));
                }

                vm.TotalActivitiesWeightage = ko.computed(function () {
                    var total = 0;
                    for (var p = 0; p < vm.GrantActivities().length; ++p) {
                        if (vm.GrantActivities()[p].IsSelected()) {
                            total += Number(vm.GrantActivities()[p].Weightage());
                        }
                    }
                    return total;
                });

                vm.TotalAmount = ko.computed(function () {

                    return vm.TotalActivitiesWeightage() * vm.CollegeProfile.AllocatedAmount() / 100;
                });


                vm.SaveActivitiesStatus = function () {
                    context.SaveActivitiesStatus();
                }

                vm.VerifyApplication = function () {
                    context.VerfiyApplication();
                }

                vm.PrintSummary = function () {
                    context.PrintSummary();
                }

                return vm;
            }
        };

        context.Initialize = function (model) {
            context.ViewModel.ProfileViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel.ProfileViewModel, $('#mainContent')[0]);
        };

        context.ApplyValidation = function () {
            $('#profileForm').validate({
                rules: {
                    ProgramId: {
                        required: true
                    }
                }
            });
        }

        context.SaveProfile = function () {
            if (!$('#profileForm').valid()) {
                return false;
            }
            var viewModel = ko.mapping.toJS(context.ViewModel.ProfileViewModel);
            delete viewModel.Programs;

            ajaxRequest('/Grant/Claim/SaveProfile', 'POST', {
                data: { model: viewModel }
            }, function (response) {
                console.log(response);
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                    if (viewModel.HasAlreadySaved == false) {
                        window.location = window.location;
                    }
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        context.SaveFacultyStatus = function () {
            if (!$('#facultyStatusForm').valid()) {
                return false;
            }
            var viewModel = ko.mapping.toJS(context.ViewModel.ProfileViewModel);
            delete viewModel.Programs;

            ajaxRequest('/Grant/Claim/SaveFacultyStatus', 'POST', {
                data: { model: viewModel }
            }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        context.VerfiyApplication = function () {
            var viewModel = ko.mapping.toJS(context.ViewModel.ProfileViewModel);

            if (confirm("Are you sure you want to confirm the verify application for this college?")) {
                if (viewModel.CollegeProfile.Status !== context.GrantClaimApplicationStatus.Accepted) {
                    //can verify 
                    var collegeid = viewModel.CollegeId;
                    ajaxRequest('/Grant/Admin/Verify', 'POST', {
                        data: { id: collegeid }
                    }, function (response) {
                        if (response.IsSuccess) {
                            showMessage(context.Title, response.Message, 'success');
                            window.location = window.location;
                        }
                        else {
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                } else {
                    showMessage(context.Title, 'Current application is already verified.')
                }
            }


        }

        context.PrintSummary = function () {
            var viewModel = ko.mapping.toJS(context.ViewModel.ProfileViewModel);
            ajaxRequest('/Grant/Summary/Index', 'POST', {
                data: { id: viewModel.CollegeId }
            }, function (response) {
                if (response.IsSuccess) {
                    window.open('/Grant/Summary/Print');
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.SetUploadId = function (uploadedId, grantActivityId, name) {
            for (var p = 0; p < context.ViewModel.ProfileViewModel.GrantActivities().length; ++p) {
                if (context.ViewModel.ProfileViewModel.GrantActivities()[p].GrantActivityId() == grantActivityId) {
                    context.ViewModel.ProfileViewModel.GrantActivities()[p].DocumentId(uploadedId);
                    context.ViewModel.ProfileViewModel.GrantActivities()[p].DocumentName(name);
                }
            }
        }

        context.SetBlankChequeuUploadId = function (uploadedId, name) {
            context.ViewModel.ProfileViewModel.CollegeProfile.BlankChequeUserAttachmentId(uploadedId);
            context.ViewModel.ProfileViewModel.CollegeProfile.BlankChequeUserAttachmentName(name);
        }

        context.SetAuditReportUploadId = function (uploadedId, name) {
            context.ViewModel.ProfileViewModel.CollegeProfile.AuditReportUserAttachmentId(uploadedId);
            context.ViewModel.ProfileViewModel.CollegeProfile.AuditReportUserAttachmentName(name);
        }

        context.SaveActivitiesStatus = function () {
            if (!$('#activityStatusForm').valid()) {
                return false;
            }
            var viewModel = ko.mapping.toJS(context.ViewModel.ProfileViewModel);
            var total = context.ViewModel.ProfileViewModel.TotalActivitiesWeightage();
            if (total > 100) {
                showMessage(context.Title, 'Cannot save until total weightage is less than 100', 'error');
                return false;
            }

            ajaxRequest('/Grant/Claim/SaveGrantActivityStatus', 'POST', {
                data: { model: viewModel }
            }, function (response) {
                console.log(response);
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });

        }

        //file upload

        context.InitializeFileUpload = function (elements) {
            $(elements).upload({
                beforeSend: context.onBeforeSend,
                action: '/FileUpload/Upload/',
                postKey: 'uploadFile',
                label: 'Upload completed supporting document',
                //postData: { oldUserAttachmentId: context.ViewModel.AddNewModel.UserAttachmentId() }
            }).on("start.upload", context.onStart)
                .on("complete.upload", context.onComplete)
                .on("filestart.upload", context.onFileStart)
                .on("fileprogress.upload", context.onFileProgress)
                .on("filecomplete.upload", context.onFileComplete)
                .on("fileerror.upload", context.onFileError)
                .on("chunkstart.upload", context.onChunkStart)
                .on("chunkprogress.upload", context.onChunkProgress)
                .on("chunkcomplete.upload", context.onChunkComplete)
                .on("chunkerror.upload", context.onChunkError)
                .on("queued.upload", context.onQueued);
        }

        context.onCancel = function (e) {
            //console.log("Cancel");
            //var index = $(this).parents("li").data("index");
            //$(this).parents("form").find(".upload").upload("abort", parseInt(index, 10));
        }

        context.onCancelAll = function (e) {
            //console.log("Cancel All");
            //$(this).parents("form").find(".upload").upload("abort");
        }

        context.onBeforeSend = function (formData, file) {
            //console.log("Before Send");
            //formData.append("test_field", "test_value");
            //var targetElement = $(this);
            //var allowedFileTypes = eval($(targetElement).attr('data-allowed-file-types'));
            //if (allowedFileTypes == null || allowedFileTypes == undefined) {
            //    allowedFileTypes = ['image/png', 'image/jpeg'];
            //}
            //var currentFileType = file.file.type;
            //var filteredList = $(allowedFileTypes).filter(function (index, element) {
            //    return element == currentFileType;
            //})
            //var isValid = filteredList && filteredList.length > 0;
            //if (!isValid) {
            //    var validationMessage = $(targetElement).attr('data-validation-message');
            //    if (validationMessage == null) {
            //        validationMessage = "Invalid File Type. Only PNG or JPEG is supported.";
            //    }
            //    showMessage(context.Title, validationMessage, 'error');
            //    return false;
            //}
            if (file.size > 2024288) {//1 MB
                showMessage(context.Title, "Uploaded File Size cannot be greater than 2 MB", 'error');
                return false;
            }
            return formData; // cancel all jpgs
        }

        context.onQueued = function (e, files) {
            //console.log("Queued");
            //var html = '';
            //for (var i = 0; i < files.length; i++) {
            //    html += '<li data-index="' + files[i].index + '"><span class="content"><span class="file">' + files[i].name + '</span><span class="cancel">Cancel</span><span class="progress">Queued</span></span><span class="bar"></span></li>';
            //}

            //$(this).parents("form").find(".filelist.queue")
            //    .append(html);
        }

        context.onStart = function (e, files) {
            //console.log("Start");
            //if (files && files[0]) {
            //    // context.displayImagePreview(files[0], 'photoId');
            //}
            //$(this).parents("form").find(".filelist.queue")
            //    .find("li")
            //    .find(".progress").text("Waiting");
        }

        context.onComplete = function (e) {
            ////console.log("Complete");
            // All done!
        }

        context.onFileStart = function (e, file) {
            //console.log("File Start");

            //var targetElement = $(e.target);
            //var defaultTypes = ['image/png', 'image/jpeg'];
            //var allowedFileTypes = eval($(targetElement).attr('data-allowed-file-types'));
            //if (allowedFileTypes == null || allowedFileTypes == undefined) {
            //    allowedFileTypes = defaultTypes;
            //}
            //var currentFileType = file.file.type;
            //var filteredList = $(allowedFileTypes).filter(function (index, element) {
            //    return element == currentFileType;
            //});
            //var isValid = filteredList && filteredList.length > 0;
            //if (!isValid) {
            //    var validationMessage = $(targetElement).attr('data-validation-message');
            //    if (validationMessage == null) {
            //        validationMessage = "Invalid File Type. Only PNG or JPEG is supported.";
            //    }
            //    showMessage(context.Title, validationMessage, 'error');
            //    return false;
            //}
            //if (allowedFileTypes == defaultTypes) {
            //    var id = $(e.target).closest('.imageContainer').find('img').attr("id");
            //    displayImagePreview(file.file, id);
            //}
            //$(this).parents("form").find(".filelist.queue")
            //    .find("li[data-index=" + file.index + "]")
            //    .find(".progress").text("0%");
        }

        context.onFileProgress = function (e, file, percent) {
            //console.log("File Progress");
            var $file = $(this).parents("form").find(".filelist.queue").find("li[data-index=" + file.index + "]");

            $file.find(".progress").text(percent + "%")
            $file.find(".bar").css("width", percent + "%");
        }

        context.onFileComplete = function (e, file, response) {
            var responseObj = eval('(' + response + ')') || {};
            if (responseObj.IsSuccess && responseObj.Data) {
                var uploadContext = $(e.target).attr('data-context');
                switch (uploadContext) {
                    case 'GrantActivityUpload':
                        context.SetUploadId(responseObj.Data.Id, $(e.target).attr('data-context-id'), responseObj.Data.FileName);
                        break;
                    case 'BlankChequeu':
                        context.SetBlankChequeuUploadId(responseObj.Data.Id, responseObj.Data.FileName);
                        break;
                    case 'AuditReport':
                        context.SetAuditReportUploadId(responseObj.Data.Id, responseObj.Data.FileName)

                }
                //var targetElement = $(e.target);
                //var defaultTypes = ['image/png', 'image/jpeg'];
                //var isDefaultType = false;
                //var allowedFileTypes = eval($(targetElement).attr('data-allowed-file-types'));
                //if (allowedFileTypes == null || allowedFileTypes == undefined) {
                //    allowedFileTypes = defaultTypes;
                //    isDefaultType = true;
                //}
                //var currentFileType = file.file.type;
                //var filteredList = $(allowedFileTypes).filter(function (index, element) {
                //    return element == currentFileType;
                //});
                //var isValid = filteredList && filteredList.length > 0;
                //if (!isValid) {
                //    var validationMessage = $(targetElement).attr('data-validation-message');
                //    if (validationMessage == null) {
                //        validationMessage = "Invalid File Type. Only PNG or JPEG is supported.";
                //    }
                //    showMessage(context.Title, validationMessage, 'error');
                //    return false;
                //}
                //if (isDefaultType == true) {
                //    var id = $(e.target).closest('.imageContainer').find('img').attr("id");
                //    displayImagePreview(file.file, id);
                //}
                //else {
                //    $(e.target).closest('.imageContainer').find('span').text(responseObj.Data.FileName);
                //    console.log('show uploaded file link');
                //}
            }
            //console.log("File Complete");
        }

        context.onFileError = function (e, file, error) {
            //console.log("File Error");
            $(this).parents("form").find(".filelist.queue")
                .find("li[data-index=" + file.index + "]").addClass("error")
                .find(".progress").text("Error: " + error);
        }

        context.onChunkStart = function (e, file) {
            //console.log("Chunk Start");
        }

        context.onChunkProgress = function (e, file, percent) {
            //console.log("Chunk Progress");
        }

        context.onChunkComplete = function (e, file, response) {
            //console.log("Chunk Complete");
        }

        context.onChunkError = function (e, file, error) {
            //console.log("Chunk Error");
        }

    })(emis.grantClaimApplication);
});
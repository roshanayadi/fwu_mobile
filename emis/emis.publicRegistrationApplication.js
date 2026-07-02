$(function () {
    emis.CreateNamespace('publicRegistrationApplication');

    (function (context) {

        context.Title = 'Student Registration';
        context.CreateFormId = '#frm';
        context.EntryFormat = { OldFormat: 1, NewFormat: 2, Partial: 3 };

        context.ViewModel = {};

        context.IsEditMode = ko.observable(false);

        context.DefaultAddNewModel = ko.observable({});

        context.LoadRegInfoByRegNo = function (regNo, callback) {
            ajaxRequest('/Student/Registration/InitializeCreateByRegNo', 'GET', { data: { registrationNo: regNo } }, function (response) {
                //if (response.IsSuccess) {

                //    ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                //}
                if ($.isFunction(callback)) {
                    callback(regNo, response);
                }
            });
        }

        context.ConvertBsToAd = function (nepaliDate, callback) {
            ajaxRequest('/Lookup/ConvertBsToAd/', 'POST', { data: { date: nepaliDate } }, function (response) {
                if (response.IsSuccess) {
                    if (callback != null) {
                        callback(response.Data);
                    }

                } else {
                    if (callback != null) {
                        callback('');
                    }
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.GetDistrictsFromProvince = function (provinceId) {
            ajaxRequest('/Lookup/GetDistrictsByProvince/', 'GET', { data: { provinceId: provinceId } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.AddNewModel.Districts);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                    return false;
                }
            });
        };

        context.ConvertAdToBs = function (englishDate, callback) {
            ajaxRequest('/Lookup/ConvertAdToBs/', 'POST', { data: { date: englishDate } }, function (response) {
                if (response.IsSuccess) {
                    if (callback != null) {
                        callback(response.Data);
                    }
                } else {
                    if (callback != null) {
                        callback('');
                    }
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };
        //add/edit

        context.LoadImage = function () {
            var imageId = context.ViewModel.AddNewModel.UserAttachmentId();
            if (imageId != null) {
                ajaxRequest('/FileUpload/GetFile',
                    'GET',
                    { data: { id: imageId } },
                    function (response) {
                        if (response.IsSuccess) {
                            $("#photoId").attr("src", "data:image/;base64," + response.Data);
                        } else {
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
            }
        };

        //file upload context
        context.DynamicFileUploadAllowedTypes = ['image/png', 'image/jpeg'];
        context.InitializeFileUpload = function (oldid, oncomplete, selector = '.upload', maxSize = 1073741824, allowedFileTypes = '["image/png", "image/jpeg"]') {
            context.DynamicFileUploadAllowedTypes = JSON.parse(allowedFileTypes);
            $(selector).upload({
                maxSize: maxSize,
                beforeSend: context.onBeforeSend,
                action: '/FileUpload/Upload/',
                postKey: 'uploadFile',
                label: 'Select Photo to upload for this student',
                postData: {}
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
                    case 'Photo':
                        context.ViewModel.ApplicationViewModel.UserAttachmentId(responseObj.Data.Id);
                        $("#photoImagePreview").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
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

        context.displayImagePreview = function (file, targetId) {
            if (file) {
                var reader = new FileReader();

                reader.onload = function (e) {
                    document.getElementById(photoId).src = e.target.result;
                }

                reader.readAsDataURL(file);
            }
        }

        //region partial entry

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.UserAttachmentDocumentContent = ko.mapping.fromJS({
                    Base64Data: '',
                    ContentType: '',
                    FileName: ''
                });

                if (vm.Colleges().length == 1) {
                    vm.CollegeId(vm.Colleges()[0].Id())
                }

                if (vm.Ethnicities().length == 1) {
                    vm.EthnicityId(vm.Ethnicities()[0].Id())
                }

                vm.RenderComplete = function () {
                    context.ApplySavePartialValidation();
                    context.InitializeFileUpload();
                    var id = context.ViewModel.ApplicationViewModel.UserAttachmentId();
                    if (id > 0) {
                        context.LoadSavedImagesForPartial(id)
                    }
                    $(vm.Documents()).each(function (index, item) {
                        if (item.UserAttachmentId() > 0 && item.DisplayPreview() == true) {
                            ajaxRequest('/Registration/Default/GetDocumentBase64Content', 'POST', { data: { id: item.UserAttachmentId() } }, function (response) {
                                if (response.IsSuccess) {
                                    ko.mapping.fromJS(response.Data.Base64Data, {}, item.UserAttachmentBase64Data);
                                } else {
                                    showMessage(context.Title, response.Message, 'error')
                                }
                            })
                        }
                    })

                };

                vm.SaveRegistrationClick = function () {
                    context.SavePartialRegistration();
                };

                vm.SubjectSelectedChange = function ($data) {
                    var index = vm.PartialSubjectRegistration.SelectedSubjects.indexOf($data);
                    if (index != -1 && index + 1 == vm.PartialSubjectRegistration.SelectedSubjects().length) {
                        var instance = ko.toJS(vm.PartialSubjectRegistration.AddNewTemplateSubject);
                        vm.PartialSubjectRegistration.SelectedSubjects.push(instance);
                    }
                }

                vm.AddSubjectsClick = function () {
                    var instance = ko.mapping.fromJS(ko.toJS(vm.PartialSubjectRegistration.AddNewTemplateSubject));
                    vm.PartialSubjectRegistration.SelectedSubjects.push(instance);
                }

                vm.RemoveSubjectsClick = function ($data) {
                    vm.PartialSubjectRegistration.SelectedSubjects.remove($data);
                }

                vm.HasRegistrationNo = ko.observable(true);
                vm.IsRegistrationNoVerified = ko.observable(false || vm.ExamRegistrationId() > 0);

                vm.VerifyRegistrationNo = function () {

                }

                vm.YearPartId.subscribe(function () {
                    context.LoadSubjectRegistrationForPartialEntry();
                })

                vm.ProgramId.subscribe(function (newValue) {
                    context.LoadSubjectRegistrationForPartialEntry();
                    context.LoadYearPart(newValue);
                });

                vm.PartialSubjectRegistration.SubjectGroupId.subscribe(function (newValue) {
                    vm.PartialSubjectRegistration.SelectedSubjects.removeAll();
                    if (newValue && vm.PartialSubjectRegistration.SubjectGroups && vm.PartialSubjectRegistration.SubjectGroups().length > 0) {
                        var selectedSubjectGroup = $(vm.PartialSubjectRegistration.SubjectGroups()).filter(function (index, item) {
                            return item.SubjectGroupId == newValue;
                        })
                        selectedSubjectGroup = selectedSubjectGroup != null ? selectedSubjectGroup[0] : null;
                        if (selectedSubjectGroup !== null) {
                            $(selectedSubjectGroup.GroupSubjects).each(function (index, item) {
                                vm.PartialSubjectRegistration.SelectedSubjects.push(ko.mapping.fromJS(item))
                            })
                            //vm.PartialSubjectRegistration.SelectedSubjects = ko.observableArray(ko.mapping.fromJS(selectedSubjectGroup.GroupSubjects));
                        }
                    } else {
                        //do nothing for now
                    }
                })

                vm.LastName.subscribe(function (newValue) {
                    vm.FatherLastName(newValue);
                    vm.MotherLastName(newValue);
                });

                vm.PreviousYears = ko.observableArray([{ Id: 2070, Description: '2070' }, { Id: 2071, Description: '2071' }, { Id: 2072, Description: '2072' }, { Id: 2073, Description: '2073' }, { Id: 2074, Description: '2074' }, { Id: 2075, Description: '2075' }]);

                //vm.RegistrationNo.subscribe(function (newRegistrationNo) {
                //    //
                //    //calland check here
                //    if (newRegistrationNo && newRegistrationNo.length > 0) {
                //        context.LoadStudentInfoByRegNo(newRegistrationNo);
                //    }
                //})

                vm.SearchByRegistrationNo = function () {
                    vm.IsRegistrationNoVerified(false);
                    var regNo = vm.RegistrationNo();
                    var dob = vm.BirthDateBS();
                    $('#searchByRegNo').validate({
                        rules: {
                            RegistrationNo: { required: true },
                            BirthDateBS: { required: true }
                        }
                    });
                    if ($("#searchByRegNo").valid()) {
                        context.LoadStudentInfoByRegNo(regNo,dob, function () {
                            vm.IsRegistrationNoVerified(true);
                        });
                    }
                }

                vm.DateOfBirthBSChange = function (data) {
                    var newValue = data.BirthDateBS();
                    ajaxRequest('/Cascade/ConvertBsToAd/', 'POST', { data: { date: newValue } }, function (response) {
                        if (response.IsSuccess) {
                            vm.BirthDateAD(response.Data);
                        } else {
                            vm.BirthDateAD('');
                        }
                    });
                }
                vm.DateOfBirthADChange = function (data) {
                    var newValue = data.BirthDateAD();
                    var newDate = moment(newValue).isValid() ? moment(newValue).format('YYYY-MM-DD') : '';
                    ajaxRequest('/Cascade/ConvertAdToBs/', 'POST', { data: { date: newDate } }, function (response) {
                        if (response.IsSuccess) {
                            vm.BirthDateBS(response.Data);
                        }
                        else {
                            vm.BirthDateBS('');
                        }
                    });
                };

                vm.PartialSubjectRegistration.SelectedSubjects.subscribe(function (changes) {

                    changes.forEach(function (change) {
                        if (change.status === 'added') {
                            //
                        } else if (change.status === 'deleted') {
                            if (change.value.SubjectDetailID && change.value.SubjectDetailID._subscriptions) {
                                ko.utils.arrayForEach(change.value.SubjectDetailID._subscriptions, function (s) {
                                    if (s) s.dispose();
                                });
                            }
                        }
                    });

                }, null, "arrayChange");

                vm.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForPartialEntry();
                });

                vm.DocumentUploadRenderComplete = function (elements, data) {
                    context.InitializeFileUploadDynamic(elements, data);
                }

                vm.SubjectRenderComplete = function ($elements, $data) {
                    $data.SubjectDetailID.subscribe(function (newValue) {
                        if (newValue) {
                            var allSubjects = ko.mapping.toJS(vm.PartialSubjectRegistration.SelectedSubjects());
                            var index = $(allSubjects).map(function (index, item) { return item.SubjectDetailID }).toArray().indexOf(newValue);
                            if (index == vm.PartialSubjectRegistration.SelectedSubjects().length - 1) {
                                vm.AddSubjectsClick();
                            }
                        }
                    })
                }

                return vm;
            }
        };

        context.InitializeFileUploadDynamic = function (elements, data) {
            context.InitializeFileUpload('', function () { }, selector = $(elements).find('.upload'), maxSize = data.MaxFileSize(), allowedFileTypes = data.AllowedFileTypes())
            if (data.UserAttachmentId && data.UserAttachmentId() > 0) {
                ajaxRequest('/Registration/Default/GetDocumentBase64Content', 'POST', { data: { id: data.UserAttachmentId() } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data, {}, data.UserAttachmentBase64Data);
                    } else {
                        showMessage(context.Title, response.Message, 'error')
                    }
                })
            }
        }

        context.DynamicFileUploadComplete = function (e, response) {
            if ($(e.target).attr('data-upload-show-preview') == 'true') {
                //
                $(e.target).closest('.imageContainer').find('img').attr('src', "data:image/;base64," + response.FileContent)
            } else {
                $(e.target).closest('.imageContainer').find('span').text(response.FileName)
            }
            var id = $(e.target).attr('data-document-category-id');
            var model = $(context.ViewModel.ApplicationViewModel.Documents()).filter(function (index, item) { return item.DocumentUploadCategoryId() == id })[0]
            var data = response;
            model.UserAttachmentId(data.Id);
            model.UserAttachmentGuid(data.Guid);
        }

        context.VerifyRegistrationNo = function () {

        }

        context.LoadYearPart = function (newProgramId) {
            if (newProgramId) {
                var yearPartId = context.ViewModel.ApplicationViewModel.SelectedYearPartId();
                ajaxRequest('/Cascade/GetYearPartByProgram', 'POST', { data: { programId: newProgramId, yearPartId: yearPartId } }, function (response) {
                    var yearParts = [];
                    if (response.IsSuccess) {
                        yearParts = response.Data;
                    } else {
                        yearParts = [];
                    }
                    ko.mapping.fromJS(yearParts, {}, context.ViewModel.ApplicationViewModel.YearParts);
                    if (yearParts.length == 1) {
                        context.ViewModel.ApplicationViewModel.YearPartId(yearParts[0].Id)
                    }
                });
            }
            else {
                ko.mapping.fromJS([], {}, context.ViewModel.ApplicationViewModel.YearParts);

            }
        }

        context.LoadSavedImagesForPartial = function (id) {
            ajaxRequest('/Registration/Default/GetDocumentBase64Content', 'POST', { data: { id: id } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.ApplicationViewModel.UserAttachmentDocumentContent);
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.LoadStudentInfoByRegNo = function (registrationNo, dateOfBirth, successCallback) {
            ajaxRequest('/Registration/Default/GetStudentRegNo', 'POST', { data: { registrationNo: registrationNo, dateOfBirth: dateOfBirth } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.ApplicationViewModel);
                    if (successCallback) {
                        successCallback(response);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error', null, 'swal')
                }
            })
        }

        context.ApplySavePartialValidation = function () {
            $('#studentRegistrationForm').validate({
                rules: {
                    AcademicYearId: { required: true },
                    CollegeId: { required: true },
                    ProgramId: { required: true },
                    FirstName: { required: true },
                    LastName: { required: true },
                    RegistrationNo: { required: true },
                    BirthDateBS: { required: true },
                    BirthDateAD: { required: true },
                    GenderId: { required: true },
                    VoucherNo: { required: context.ViewModel.ApplicationViewModel.ModuleSettings.Compulsary_OnlinePaymentVoucher()=='true'},
                    ContactNo: { required: true, number: true, maxlength: 13 }
                }
            });
        };

        context.LoadProgramForPartialEntry = function () {
            var collegeId = context.ViewModel.ApplicationViewModel.CollegeId();
            var levelId = context.ViewModel.ApplicationViewModel.LevelId();
            var yearPartId = context.ViewModel.ApplicationViewModel.SelectedYearPartId();
            if (collegeId && collegeId > 0) {
                ajaxRequest('/Cascade/GetProgramByCollegeAndExamSchedule', 'POST', { data: { collegeId: collegeId, levelid: levelId, yearPartId: yearPartId } }, function (response) {
                    if (response.IsSuccess) {

                        context.ViewModel.ApplicationViewModel.Programs(response.Data);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
            else {

                context.ViewModel.ApplicationViewModel.Programs([]);
            }
        };

        context.Initialize = function (formId, model) {
            context.ViewModel.ApplicationViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel.ApplicationViewModel, $(formId)[0]);
        };

        context.SavePartialRegistration = function () {
            if (!$('#studentRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ApplicationViewModel);
            delete model.Colleges;
            delete model.AcademicYears;
            delete model.BloodGroups;
            delete model.Districts;
            delete model.Ethnicities;
            delete model.Faculties;
            delete model.IndexGroups;
            delete model.Levels;
            delete model.Provinces;
            delete model.PartialSubjectRegistration.AllSubjects;

            if (model.PartialSubjectRegistration.SelectedSubjects.length == 0) {
                showMessage(context.Title, 'At least on subject must be selected to save.', 'error')
                return;
            }
            model.BirthDateAD = moment(model.BirthDateAD).isValid() ? moment(model.BirthDateAD).format('YYYY-MM-DD') : '';

            ajaxRequest('/Registration/Default/Create', 'POST', {
                data: { model: model },
            }, function (response) {
                if (response.IsSuccess) {
                    if (response.IsSuccess) {
                        swal({
                            title: context.Title,
                            text: "Student Information registered successfully. Please consult with your college about the status of verification.",
                            type: "success",
                            //showCancelButton: true,
                            confirmButtonColor: "#DD6B55",
                            confirmButtonText: "Ok",
                            //cancelButtonText: "Cancel",
                            closeOnConfirm: true,
                            //closeOnCancel: false
                        },
                            function (isConfirm) {
                                window.location = '/LandingPage/';
                            });
                    } else {
                        swal(context.Title, response.Message, "error", null, 'swal');
                    }

                } else {
                    swal(context.Title, response.Message, 'error', null, 'swal')
                }
            });
        };

        context.LoadSubjectRegistrationForPartialEntry = function () {
            if (context.ViewModel.ApplicationViewModel.ProgramId && context.ViewModel.ApplicationViewModel.ProgramId() > 0) {
                var model = ko.mapping.toJS(context.ViewModel.ApplicationViewModel);
                var m = {
                    AcademicYearId: model.AcademicYearId,
                    CollegeId: model.CollegeId,
                    ProgramId: model.ProgramId,
                    YearpartId: model.YearPartId,
                    EntryFormat: context.ViewModel.ApplicationViewModel.EntryFormat
                };
                if (!(m.AcademicYearId > 0 && m.ProgramId > 0 && m.CollegeId > 0 && m.YearpartId > 0)) {
                    return false;
                }

                ajaxRequest('/Cascade/GetSubjectRegistrationFromProgramId', 'POST', { data: m }, function (response) {
                    if (response.IsSuccess) {
                        context.ViewModel.ApplicationViewModel.PartialSubjectRegistration.AllSubjects(response.Data.AllSubjects);
                        context.ViewModel.ApplicationViewModel.PartialSubjectRegistration.SubjectGroups(response.Data.SubjectGroups);
                        var currentRollNo = context.ViewModel.ApplicationViewModel.PartialSubjectRegistration.ExamRollNo();
                        if (currentRollNo && currentRollNo.length > 0) {
                            //not changing
                        }
                        else {
                            context.ViewModel.ApplicationViewModel.PartialSubjectRegistration.SuggestedExamRollNo(response.Data.SuggestedExamRollNo);
                        }
                        //ko.mapping.fromJS(response.Data.AllSubjects, {}, context.ViewModel.ApplicationViewModel.PartialSubjectRegistration.AllSubjects);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        };

    })(emis.publicRegistrationApplication);
});
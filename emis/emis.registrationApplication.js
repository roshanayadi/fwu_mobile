$(function () {
    emis.CreateNamespace('registrationApplication');

    (function (context) {

        context.Title = 'Student Registration';
        context.CreateFormId = '#frm';
        context.EntryFormat = { OldFormat: 1, NewFormat: 2, Partial: 3 };

        context.ViewModel = {};

        context.IsEditMode = ko.observable(false);

        context.DefaultAddNewModel = ko.observable({});


        context.PerformPaging = function () {
            console.log(context.ViewModel.SearchModel.PageSize());
            console.log(context.ViewModel.SearchModel.PageIndex());
        };



        context.CreateMapping = {
            create: function (options) {

                var vm = ko.mapping.fromJS(options.data);

                vm.qualificationTemplateRenderComplete = function () {
                    jQuery.validator.addClassRules({
                        board: {
                            required: true
                        },
                        institute: {
                            required: true
                        },
                        year: {
                            required: true
                        }
                    });
                };
                vm.AddNewModel.CollegeId.subscribe(function (newValue) {
                    context.ObtainNewRegNo();
                    context.LoadProgram();
                });
                vm.AddNewModel.ProgramId.subscribe(function (newValue) {
                    context.ObtainNewRegNo();
                    context.LoadQualification();
                    context.LoadSubjectRegistration();
                });

                vm.AddNewModel.LastName.subscribe(function (newValue) {
                    vm.AddNewModel.FatherLastName(newValue);
                    vm.AddNewModel.MotherLastName(newValue);
                })

                //vm.AddNewModel.RegistrationNo.subscribe(function (newValue) {
                //    if (newValue && newValue.length > 0) {
                //        context.LoadRegInfoByRegNo(newValue, function (newValue, response) {
                //            if (response.IsSuccess) {

                //                ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                //            }
                //        });
                //    }
                //});
                vm.DateOfBirthBSChange = function (data) {
                    var newValue = data.BirthDateBS();
                    ajaxRequest('/Lookup/ConvertBsToAd/', 'POST', { data: { date: newValue } }, function (response) {
                        if (response.IsSuccess) {
                            vm.AddNewModel.BirthDateAD(response.Data);
                        } else {
                            vm.AddNewModel.BirthDateAD('');
                        }
                    });
                }
                vm.DateOfBirthADChange = function (data) {
                    var newValue = data.BirthDateAD();
                    var newDate = moment(newValue).isValid() ? moment(newValue).format('YYYY-MM-DD') : '';
                    ajaxRequest('/Lookup/ConvertAdToBs/', 'POST', { data: { date: newDate } }, function (response) {
                        if (response.IsSuccess) {
                            vm.AddNewModel.BirthDateBS(response.Data);
                        }
                        else {
                            vm.AddNewModel.BirthDateBS('');
                        }
                    });
                };


                //vm.AddNewModel.BirthDateAD.subscribe(function (newValue) {
                //    if (newValue) {
                //        context.ConvertAdToBs(moment(newValue).format('YYYY-MM-DD'), function (result) {
                //            var model = {
                //                BirthDateBS: result
                //            }
                //            ko.mapping.fromJS(model, {}, vm.AddNewModel);
                //        });
                //    }
                //    else {
                //        vm.AddNewModel.BirthDateBS('');
                //    }
                //});
                //vm.AddNewModel.BirthDateBS.subscribe(function (newValue) {
                //    if (newValue) {
                //        context.ConvertBsToAd(newValue, function (result) {
                //            var model = {
                //                BirthDateAD: result
                //            }
                //            ko.mapping.fromJS(model, {}, vm.AddNewModel);
                //        });
                //    }
                //    else {
                //        vm.AddNewModel.BirthDateAD(null);
                //    }
                //});
                vm.AddNewModel.BirthDateBS.extend({ rateLimit: 50 });
                vm.AddNewModel.BirthDateAD.extend({ rateLimit: 50 });

                vm.AddNewModel.StudentRegistrationIndex.subscribe(function (newValue) {

                });

                vm.AddNewModel.PreferredDoBType.subscribe(function (newValue) {
                    if (newValue) {
                        $('#BirthDateBS').inputmask('9999-99-99');
                    }
                });

                //vm.AddNewModel.Experiences.subscribe(function (changes) {

                //    changes.forEach(function (change) {
                //        if (change.status === 'added') {
                //            change.value.FromDate.subscribe(function (newValue) {
                //                vm.ExperienceArrayChangeEvent();
                //            });
                //            change.value.ToDate.subscribe(function (newValue) {
                //                vm.ExperienceArrayChangeEvent();
                //            });
                //        } else if (change.status === 'deleted') {
                //            if (change.value.FromDate && change.value.FromDate._subscriptions) {
                //                ko.utils.arrayForEach(change.value.FromDate._subscriptions, function (s) {
                //                    if (s) s.dispose();
                //                });
                //            }
                //            if (change.value.ToDate && change.value.ToDate._subscriptions) {
                //                ko.utils.arrayForEach(change.value.ToDate._subscriptions, function (s) {
                //                    if (s) s.dispose();
                //                });
                //            }
                //            vm.ExperienceArrayChangeEvent();
                //        }
                //    });

                //}, null, "arrayChange");



                vm.SaveRegistration = function () {
                    context.SaveRegistration();
                };

                return vm;
            }
        };

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

        context.LoadQualification = function () {
            if (context.ViewModel.AddNewModel.EntryFormat() == context.EntryFormat.NewFormat && context.ViewModel.AddNewModel.ProgramId && context.ViewModel.AddNewModel.ProgramId() > 0) {
                ajaxRequest('/Student/Registration/GetQualificationInfoForProgram', 'POST', { data: { programId: context.ViewModel.AddNewModel.ProgramId() } }, function (response) {
                    if (response.IsSuccess) {

                        context.ViewModel.AddNewModel.Qualifications(response.Data);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        };

        context.LoadSubjectRegistration = function () {
            if (context.ViewModel.AddNewModel.EntryFormat() == context.EntryFormat.OldFormat && context.ViewModel.AddNewModel.ProgramId && context.ViewModel.AddNewModel.ProgramId() > 0) {
                var model = ko.mapping.toJS(context.ViewModel.AddNewModel);
                var m = {
                    AcademicYearId: model.AcademicYearId,
                    CollegeId: model.CollegeId,
                    ProgramId: model.ProgramId,
                };
                if (!(m.AcademicYearId > 0 && m.ProgramId > 0 && m.CollegeId > 0)) {
                    return false;
                }

                ajaxRequest('/Student/Registration/GetSubjectRegistrationFromProgramId', 'POST', { data: m }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.AddNewModel.SubjectRegistrationViewModel);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        };
        context.ObtainNewExamRollNo = function () {
            if (context.ViewModel.AddNewModel.EntryFormat() == context.EntryFormat.OldFormat && context.ViewModel.AddNewModel.ProgramId()) {
                var model = ko.mapping.toJS(context.ViewModel.AddNewModel);
                var m = {
                    AcademicYearId: model.AcademicYearId,
                    CollegeId: model.CollegeId,
                    ProgramId: model.ProgramId,
                    EntryFormat: context.ViewModel.AddNewModel.EntryFormat()
                };
                if (!(m.AcademicYearId > 0 && m.ProgramId > 0 && m.CollegeId > 0)) {
                    return false;
                }

                ajaxRequest('/Student/Registration/GenerateNewExamRollNo', 'POST', { data: m }, function (response) {
                    if (response.IsSuccess) {
                        context.ViewModel.AddNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo(response.Data);
                        context.ViewModel.AddNewModel.SubjectRegistrationViewModel.ExamRollNo('');
                        //ko.mapping.fromJS(response.Data, {}, context.ViewModel.AddNewModel.SubjectRegistrationViewModel.ExamRollNo);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        };
        context.LoadProgram = function () {
            var collegeId = context.ViewModel.AddNewModel.CollegeId();
            if (collegeId && collegeId > 0) {


                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: context.ViewModel.AddNewModel.CollegeId(), levelid: context.ViewModel.AddNewModel.LevelId() } }, function (response) {
                    if (response.IsSuccess) {

                        context.ViewModel.AddNewModel.Programs(response.Data);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
            else {

                context.ViewModel.AddNewModel.Programs([]);
            }
        };


        context.Search = function () {
            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.SearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Student/Registration/Index', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data.Records, {}, context.ViewModel.SearchModel.Records);
                        ko.mapping.fromJS(response.Data.TotalRecords, {}, context.ViewModel.SearchModel.TotalRecords);
                        ko.mapping.fromJS(response.Data.AllowPaging, {}, context.ViewModel.SearchModel.AllowPaging);
                        ko.mapping.fromJS(response.Data.PageSize, {}, context.ViewModel.SearchModel.PageSize);
                        ko.mapping.fromJS(response.Data.PageIndex, {}, context.ViewModel.SearchModel.PageIndex);
                        ko.mapping.fromJS(response.Data.TotalPage, {}, context.ViewModel.SearchModel.TotalPage);
                        ko.mapping.fromJS(response.Data.Pages, {}, context.ViewModel.SearchModel.Pages);
                        ko.mapping.fromJS(response.Data.CurrentPageStartIndex, {}, context.ViewModel.SearchModel.CurrentPageStartIndex);
                        //context.ViewModel.SearchModel.TotalRecords(response.Data.TotalRecords);
                        //context.ViewModel.SearchModel.Pages(response.Data.Pages);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        };

        context.Export = function () {
            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.SearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Student/Registration/InitializeExport', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        window.open('/Student/Registration/Export')
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        };

        //add/edit

        context.InitializeOldFormatSearch = function (formId) {
            var viewModel = {
                SearchRegNo: ko.observable('')
            };
            var mapping = {
                create: function (options) {
                    var vm = ko.mapping.fromJS(options.data);

                    vm.SearchRegNo.subscribe(function (newValue) {
                        context.ViewModel.AddNewModel.StudentRegistrationID(0);
                        if (newValue && newValue.length > 0) {
                            context.LoadRegInfoByRegNo(newValue, function (newValue, response) {
                                if (response.IsSuccess) {
                                    ko.cleanNode($(context.CreateFormId)[0]);
                                    context.ViewModel = {};
                                    context.LoadCreateModel(response.Data.StudentRegistrationID);
                                }
                                else {
                                    showMessage(context.Title, response.Message, 'error');

                                }
                            });
                        }
                    });

                    return vm;
                }
            };
            context.ViewModel.OldFormatSearchViewModel = ko.mapping.fromJS(viewModel, mapping);
            ko.applyBindings(context.ViewModel.OldFormatSearchViewModel, $('#' + formId)[0]);
        };

        context.InitializeCreate = function (formId, studentRegistrationId) {
            context.CreateFormId = '#' + formId;
            context.LoadCreateModel(studentRegistrationId);
        };

        context.LoadCreateModel = function (studentRegistrationId, callback) {
            var id = studentRegistrationId;
            ajaxRequest('/Student/Registration/InitializeCreate', 'GET', { data: { id: id } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($(context.CreateFormId)[0])) {
                        //new
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.CreateMapping);

                        ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.DefaultAddNewModel);

                        ko.applyBindings(context.ViewModel, $(context.CreateFormId)[0]);

                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                    }
                    //emis.fileinputhelper.InitializeFileUpload('#kv-explorer');
                    //emis.fileinputhelper.UploadCompleteCallback = function (response) {
                    //    context.ViewModel.AddNewModel.UserAttachmentId(response.Data.Id);
                    //}
                    if (context.ViewModel.AddNewModel.EntryFormat === context.EntryFormat.NewFormat || context.ViewModel.AddNewModel.EntryFormat === context.EntryFormat.Partial) {
                        if (id > 0) {
                            context.LoadImage();
                        }
                        context.InitializeFileUpload(null, function (e, file, response) {
                            var responseObj = eval('(' + response + ')') || {};
                            if (responseObj.IsSuccess && responseObj.Data) {
                                context.ViewModel.AddNewModel.UserAttachmentId(responseObj.Data.Id);
                                $("#photoId").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                            }
                            console.log("File Complete");
                        });
                    }
                    context.ApplySaveValidation();
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
                if ($.isFunction(callback)) {
                    callback(studentRegistrationId, response);
                }
            });
        };

        context.ApplySaveValidation = function () {
            $(context.CreateFormId).validate({
                rules: {

                }
            });
            $('[name^=InstituteName_]').each(function (index, item) {
                $(item).rules('add',
                    {
                        required: true,
                        messages: {
                            required: 'Required'
                        }
                    });
            });

        };

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

        context.ObtainNewRegNo = function (callback) {
            if (!context.IsEditMode()) {

                var model = ko.mapping.toJS(context.ViewModel.AddNewModel);
                if (!(model.AcademicYearId > 0 && model.ProgramId > 0 && (model.StudentRegistrationId == undefined || model.StudentRegistrationId <= 0))) {
                    return false;
                }
                delete model.Colleges;
                delete model.AcademicYears;
                delete model.BloodGroups;
                delete model.Districts;
                delete model.Ethnicities;
                delete model.Faculties;
                delete model.IndexGroups;
                delete model.Levels;
                delete model.Provinces;
                ajaxRequest('/Student/Registration/GenerateNewRegistrationNo/',
                    'POST',
                    { data: { model: model } },
                    function (response) {
                        if (response.IsSuccess) {
                            context.ViewModel.AddNewModel.StudentRegistrationIndex(response.Data.StudentRegistrationIndex);
                            context.ViewModel.AddNewModel.RegistrationNo(response.Data.RegistrationNo);
                        } else if (response.Data !== true) {
                            showMessage(context.Title, response.Message, 'error');
                        }
                        if ($.isFunction(callback)) {
                            callback(response);
                        }
                    });
            }
        };
        context.SaveRegistration = function () {
            if (!$(context.CreateFormId).valid()) {
                return false;
            }

            var mainModel = ko.mapping.toJS(context.ViewModel);
            var model = mainModel.AddNewModel;
            delete model.Colleges;
            delete model.AcademicYears;
            delete model.BloodGroups;
            delete model.Districts;
            delete model.Ethnicities;
            delete model.Faculties;
            delete model.IndexGroups;
            delete model.Levels;
            delete model.Provinces;

            ajaxRequest('/Student/Registration/Create', 'POST', {
                data: { model: model },
            }, function (response) {
                if (response.IsSuccess) {
                    swal({
                        title: context.Title,
                        text: "Student Information registered successfully.",
                        type: "success",
                        //showCancelButton: true,
                        confirmButtonColor: "#DD6B55",
                        confirmButtonText: "Ok",
                        //cancelButtonText: "Cancel",
                        closeOnConfirm: true,
                        //closeOnCancel: false
                    },
                        function (isConfirm) {
                            if (isConfirm) {

                                if (response.Data != null && response.Data.IsRedirect) {
                                    window.location = '/Student/Registration/SubjectRegistration/' + response.Data.StudentAdmissionId;
                                }
                                else if (response.Data != null) {
                                    var saveModel = model;
                                    if (response.Data.StudentRegistrationID != null) {
                                        ko.cleanNode($(context.CreateFormId)[0])
                                        context.ViewModel = {};
                                        context.LoadCreateModel(response.Data.StudentRegistrationID, function (studentRegistrationId, response) {
                                            if (response.IsSuccess) {
                                                //if student information found check for exam roll is set or not
                                                if (context.ViewModel.AddNewModel.SubjectRegistrationViewModel.ExamRollNo && context.ViewModel.AddNewModel.SubjectRegistrationViewModel.ExamRollNo() && context.ViewModel.AddNewModel.SubjectRegistrationViewModel.ExamRollNo().length > 0) {
                                                    //not needed
                                                }
                                                else {
                                                    var newRollNo = context.SetNewRollNo(saveModel.SubjectRegistrationViewModel.SuggestedExamRollNo);
                                                    context.ViewModel.AddNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo(newRollNo);
                                                }
                                            }
                                            else {
                                                //do nothing
                                                //showMessage(context.Title, response.Mess)
                                            }
                                        });
                                    }
                                    else {
                                        if (response.Data.IsCreateMode != true) {
                                            // showMessage(context.Title, 'Student info could not be found for ' + response.Data.ContinueRegNo.FullRegNo + ', Falling back to new Application', 'info')
                                        }
                                        var addNewModel = context.ViewModel.AddNewModel;

                                        //addNewModel.StudentRegistrationIndex(response.Data.NewRegNo.RegNoIndex);
                                        //addNewModel.RegistrationNo(response.Data.NewRegNo.FullRegNo);

                                        addNewModel.RegistrationNo(response.Data.ContinueRegNo.FullRegNo);
                                        addNewModel.FirstName('');
                                        addNewModel.MiddleName('');
                                        addNewModel.LastName('');
                                        addNewModel.NepaliName('');
                                        setTimeout(function () { addNewModel.BirthDateAD(null); }, 0);
                                        addNewModel.BirthDateBS('');
                                        addNewModel.GenderId(null);
                                        addNewModel.BloodGroup(null);
                                        addNewModel.IndexGroupId(null);
                                        addNewModel.Nationality('');
                                        addNewModel.Religion('');
                                        addNewModel.Email('');
                                        addNewModel.Phone('');
                                        addNewModel.FatherName('');
                                        addNewModel.FatherOccupation('');
                                        addNewModel.FatherPhone('');
                                        addNewModel.MotherName('');
                                        addNewModel.MotherOccupation('');
                                        addNewModel.MotherPhone('');
                                        addNewModel.MunVDC('');
                                        addNewModel.SubjectRegistrationViewModel.ExamRollNo('');
                                        addNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo('');
                                        addNewModel.UserAttachmentId(null);
                                        addNewModel.StudentRegistrationID(null);

                                        //$('#photoId').attr('src', '');
                                        goToByScroll('FirstName');
                                        $("#FirstName").focus();
                                        context.LoadQualification();

                                        var newRollNo = context.SetNewRollNo(saveModel.SubjectRegistrationViewModel.SuggestedExamRollNo);
                                        //no student information found for provided reg no
                                        //set new roll no
                                        context.ViewModel.AddNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo(newRollNo);
                                    }

                                } else {
                                    window.location = '/Student/Registration/Index';
                                }

                            } else {
                                swal(context.Title, "A", "error");
                            }
                        });
                    //showMessage(context.Title, 'Student Information registered successfully.', 'success', function () {

                    //});
                } else {
                    swal(context.Title, response.Message, "error");
                    //showMessage(context.Title, response.Message, 'error', function () {

                    //});
                }
            });
        }

        context.SetNewRollNo = function (currentRollNo) {
            if (currentRollNo && currentRollNo.length > 0) {
                var prefix = currentRollNo.substring(0, 3);
                var newRollNoIndex = parseInt(currentRollNo.substring(3)) + 1;

                return prefix + context.padLeft(newRollNoIndex, 4);
            }
            return "";
        };

        context.padLeft = function (str, max) {
            str = str.toString();
            return str.length < max ? context.padLeft("0" + str, max) : str;
        };
        //verify 
        context.VerifyMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentVerifyItem = ko.observable({});

                vm.SearchClick = function () {
                    context.SearchVerify();
                };

                vm.CollegeId.subscribe(function (newCollegeId) {
                    ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                        if (response.IsSuccess) {

                            vm.Programs(response.Data);
                        } else {
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                });

                vm.VerifyClick = function (item) {
                    vm.CurrentVerifyItem = item;
                    context.Verify(item);
                };

                vm.VerifyContentRenderComplete = function () {
                    context.ApplyVerifyValidation();
                };

                return vm;
            }
        };

        context.Verify = function (item) {

            if (!$('#verifyPostForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.VerifySearchModel);

            delete model.__ko_mapping__;
            delete model.AcademicYears;
            delete model.Programs;
            delete model.Colleges;
            delete model.SearchClick;
            delete model.VerifyClick;
            delete model.Records;

            ajaxRequest('/Student/Registration/Verify',
                'POST',
                { data: { id: item.StudentRegistrationID(), searchModel: model } },
                function (response) {
                    if (response.IsSuccess) {
                        context.ViewModel.VerifySearchModel.CurrentVerifyItem.RegistrationNo(response.Data.FullRegNo);
                        context.ViewModel.VerifySearchModel.CurrentVerifyItem.VerifiedBy(response.Data.VerifiedBy);
                        context.ViewModel.VerifySearchModel.CurrentVerifyItem.StudentRegistrationIndex(response.Data.RegNoIndex);

                    } else {
                        showMessage(response.Message);
                    }
                });
            console.log(ko.toJS(item));
        };

        context.SearchVerify = function () {
            if (!$('#verifyForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.VerifySearchModel);

            delete model.__ko_mapping__;
            delete model.AcademicYears;
            delete model.Programs;
            delete model.SearchClick;
            delete model.VerifyClick;
            delete model.Records;

            ajaxRequest('/Student/Registration/SearchVerify', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data.Records, {}, context.ViewModel.VerifySearchModel.Records);
                    context.ViewModel.VerifySearchModel.StartingRegNoIndex(response.Data.StartIndex);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        context.ApplySearchVerifyMapping = function () {
            $('#verifyForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    }, CollegeId: {
                        required: true
                    }, ProgramId: {
                        required: true
                    }
                },
                messages: {
                    AcademicYearId: {
                        required: 'Academic Year must be selected.'
                    }, CollegeId: {
                        required: 'College Must be selected'
                    }, ProgramId: {
                        required: 'Program must be selected'
                    }
                }
            });
        };

        context.ApplyVerifyValidation = function () {
            $('#verifyPostForm').validate({
                rules: {
                    StartingRegNoIndex: {
                        required: true,
                        number: true
                    }
                },
                message: {
                    required: 'Start Registration No is required',
                    number: 'Start Registration No must be a valid number.'
                }
            });
        };

        context.InitializeVerify = function () {
            ajaxRequest('/Student/Registration/InitializeVerify', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.VerifySearchModel = ko.mapping.fromJS(response.Data, context.VerifyMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.VerifySearchModel);
                    }
                    context.ApplySearchVerifyMapping();
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
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


        ///region old format

        //endregion old format

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
                    //$(vm.Documents()).each(function (index, item) {
                    //    if (item.UserAttachmentId() > 0 && item.DisplayPreview() == true) {
                    //        ajaxRequest('/Student/Registration/GetDocumentBase64Content', 'POST', { data: { id: item.UserAttachmentId() } }, function (response) {
                    //            if (response.IsSuccess) {
                    //                ko.mapping.fromJS(response.Data.Base64Data, {}, item.UserAttachmentBase64Data);
                    //            } else {
                    //                showMessage(context.Title, response.Message, 'error')
                    //            }
                    //        })
                    //    }
                    //})

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
                    if (regNo.length > 0) {
                        context.LoadStudentInfoByRegNo(regNo, function () {
                            vm.IsRegistrationNoVerified(true);
                        });
                    } else {
                        //do something
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
                            //change.value.SubjectDetailID.subscribe(function (newValue) {
                                //console.log('at subject change')
                                ////
                                //if (newValue) {
                                //    var allSubjects = ko.mapping.toJS(vm.PartialSubjectRegistration.SelectedSubjects());
                                //    var index = $(allSubjects).map(function (index, item) { return item.SubjectDetailID }).toArray().indexOf(newValue);
                                //    if (index == vm.PartialSubjectRegistration.SelectedSubjects().length - 1) {
                                //        vm.AddSubjectsClick();
                                //    }
                                //}
                            //});
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
                ajaxRequest('/Student/Registration/GetDocumentBase64Content', 'POST', { data: { id: data.UserAttachmentId() } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data.Base64Data, {}, data.UserAttachmentBase64Data);
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
            ajaxRequest('/Student/Registration/GetDocumentBase64Content', 'POST', { data: { id: id } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.ApplicationViewModel.UserAttachmentDocumentContent);
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.LoadStudentInfoByRegNo = function (registrationNo, successCallback) {
            ajaxRequest('/Registration/Default/GetStudentRegNo', 'POST', { data: { registrationNo: registrationNo } }, function (response) {
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
                    Contact: { required: true, number: true, maxlength: 13 }
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

            if (model.PartialSubjectRegistration.AllSubjects.filter(x=>x.IsTheorySelected || x.IsPracticalSelected).length == 0) {
                showMessage(context.Title, 'At least on subject must be selected to save.', 'error')
                return;
            }

            if (model.Documents && model.Documents.length > 0) {
                $(model.Documents).each(function (index, item) { delete item.UserAttachmentBase64Data })
            }
            model.BirthDateAD = moment(model.BirthDateAD).isValid() ? moment(model.BirthDateAD).format('YYYY-MM-DD') : '';

            ajaxRequest('/Registration/Application/Create', 'POST', {
                data: { model: model },
            }, function (response) {
                if (response.IsSuccess) {
                    if (response.IsSuccess) {
                        swal({
                            title: context.Title,
                            text: "Student Information registered successfully.",
                            type: "success",
                            //showCancelButton: true,
                            confirmButtonColor: "#DD6B55",
                            confirmButtonText: "Ok",
                            //cancelButtonText: "Cancel",
                            closeOnConfirm: true,
                            //closeOnCancel: false
                        },
                            function (isConfirm) {
                                if (isConfirm) {

                                    if (response.Data != null && response.Data.IsRedirect) {
                                        window.location = response.Data.RedirectUrl;// '/Student/Registration/SubjectRegistration/' + response.Data.StudentAdmissionId;
                                    }
                                    else if (response.Data != null) {
                                        var saveModel = model;

                                        var addNewModel = context.ViewModel.ApplicationViewModel;
                                        addNewModel.RegistrationNo('');
                                        addNewModel.FirstName('');
                                        addNewModel.MiddleName('');
                                        addNewModel.LastName('');
                                        addNewModel.NepaliName('');
                                        setTimeout(function () { addNewModel.BirthDateAD(null); }, 0);
                                        addNewModel.BirthDateBS('');
                                        addNewModel.GenderId(null);
                                        addNewModel.BloodGroup(null);
                                        addNewModel.IndexGroupId(null);
                                        addNewModel.Nationality('');
                                        addNewModel.Religion('');
                                        addNewModel.Email('');
                                        addNewModel.Phone('');
                                        addNewModel.FatherName('');
                                        addNewModel.FatherOccupation('');
                                        addNewModel.FatherPhone('');
                                        addNewModel.MotherName('');
                                        addNewModel.MotherOccupation('');
                                        addNewModel.MotherPhone('');
                                        addNewModel.MunVDC('');
                                        addNewModel.PreviousYear('');
                                        addNewModel.PreviousSymbolNo('');
                                        addNewModel.PartialSubjectRegistration.ExamRollNo('');
                                        addNewModel.PartialSubjectRegistration.SuggestedExamRollNo('');
                                        addNewModel.UserAttachmentId(null);

                                        addNewModel.StudentRegistrationID(null);

                                        context.LoadSubjectRegistrationForPartialEntry();
                                        //context.LoadE
                                        //$('#photoId').attr('src', '');

                                        //var newRollNo = context.SetNewRollNo(saveModel.SubjectRegistrationViewModel.SuggestedExamRollNo);
                                        ////no student information found for provided reg no
                                        ////set new roll no
                                        //context.ViewModel.AddNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo(newRollNo);


                                        if (response.Data.StudentRegistrationID != null) {
                                            //ko.cleanNode($(context.CreateFormId)[0])
                                            //context.ViewModel = {};
                                            //context.LoadCreateModel(response.Data.StudentRegistrationID, function (studentRegistrationId, response) {
                                            //    if (response.IsSuccess) {
                                            //        //if student information found check for exam roll is set or not
                                            //        if (context.ViewModel.AddNewModel.SubjectRegistrationViewModel.ExamRollNo && context.ViewModel.AddNewModel.SubjectRegistrationViewModel.ExamRollNo() && context.ViewModel.AddNewModel.SubjectRegistrationViewModel.ExamRollNo().length > 0) {
                                            //            //not needed
                                            //        }
                                            //        else {
                                            //            var newRollNo = context.SetNewRollNo(saveModel.SubjectRegistrationViewModel.SuggestedExamRollNo);
                                            //            context.ViewModel.AddNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo(newRollNo);
                                            //        }
                                            //    }
                                            //    else {
                                            //        //do nothing
                                            //        //showMessage(context.Title, response.Mess)
                                            //    }
                                            //});
                                        }
                                        else {
                                            //showMessage(context.Title, 'Student info could not be found for ' + response.Data.ContinueRegNo.FullRegNo + ', Falling back to new Application', 'info')
                                            //var addNewModel = context.ViewModel.AddNewModel;

                                            ////addNewModel.StudentRegistrationIndex(response.Data.NewRegNo.RegNoIndex);
                                            ////addNewModel.RegistrationNo(response.Data.NewRegNo.FullRegNo);

                                            //addNewModel.RegistrationNo(response.Data.ContinueRegNo.FullRegNo);
                                            //addNewModel.FirstName('');
                                            //addNewModel.MiddleName('');
                                            //addNewModel.LastName('');
                                            //addNewModel.NepaliName('');
                                            //setTimeout(function () { addNewModel.BirthDateAD(null); }, 0);
                                            //addNewModel.BirthDateBS('');
                                            //addNewModel.GenderId(null);
                                            //addNewModel.BloodGroup(null);
                                            //addNewModel.IndexGroupId(null);
                                            //addNewModel.Nationality('');
                                            //addNewModel.Religion('');
                                            //addNewModel.Email('');
                                            //addNewModel.Phone('');
                                            //addNewModel.FatherName('');
                                            //addNewModel.FatherOccupation('');
                                            //addNewModel.FatherPhone('');
                                            //addNewModel.MotherName('');
                                            //addNewModel.MotherOccupation('');
                                            //addNewModel.MotherPhone('');
                                            //addNewModel.MunVDC('');
                                            //addNewModel.SubjectRegistrationViewModel.ExamRollNo('');
                                            //addNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo('');
                                            //addNewModel.UserAttachmentId(null);
                                            //addNewModel.StudentRegistrationID(null);

                                            ////$('#photoId').attr('src', '');
                                            //goToByScroll('RegistrationNo');
                                            //$("#RegistrationNo").focus();
                                            //context.LoadQualification();

                                            //var newRollNo = context.SetNewRollNo(saveModel.SubjectRegistrationViewModel.SuggestedExamRollNo);
                                            ////no student information found for provided reg no
                                            ////set new roll no
                                            //context.ViewModel.AddNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo(newRollNo);
                                        }

                                    } else {
                                        window.location = window.location;
                                    }

                                } else {
                                    swal(context.Title, "A", "error");
                                }
                            });
                        //showMessage(context.Title, 'Student Information registered successfully.', 'success', function () {

                        //});
                    } else {
                        swal(context.Title, response.Message, "error", null, 'swal');
                        //showMessage(context.Title, response.Message, 'error', function () {

                        //});
                    }

                    //showMessage(context.Title, 'Student Information registered successfully.', 'success', function () {

                    //});
                } else {
                    swal(context.Title, response.Message, 'error', null, 'swal')
                    //showMessage(context.Title, response.Message, 'error', function () {

                    //});
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
        //endregion partial entry

    })(emis.registrationApplication);
});
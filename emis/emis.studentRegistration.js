$(function () {
    emis.CreateNamespace('studentRegistration');

    (function (context) {

        context.Title = 'Student Registration';
        context.CreateFormId = '#frm';
        context.EntryFormat = { OldFormat: 1, NewFormat: 2, Partial: 3 };

        context.ViewModel = {};

        context.IsEditMode = ko.observable(false);

        context.DefaultAddNewModel = ko.observable({});

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);



                vm.SearchClick = function () {
                    context.Search();
                }

                vm.ExportClick = function () {
                    context.Export();
                }



                vm.EditClick = function (item) {
                    window.location = '/Student/Registration/Edit/' + item.StudentRegistrationID();
                }

                vm.DeleteClick = function ($data) {
                    if (confirm('Are you sure you want to delete the student !!')) {
                        ajaxRequest('/Student/Registration/Delete', 'POST', { data: { id: $data.StudentRegistrationID() } }, function (response) {
                            if (response.IsSuccess) {
                                showMessage(context.Title, response.Message, 'success');
                                context.Search();
                            }
                            else {
                                showMessage(context.Title, response.Message, 'error');
                            }
                        });
                    }
                }

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            CollegeId: {
                                required: true
                            }
                        },
                        messages: {
                            CollegeId: {
                                required: 'College must be selected'
                            }
                        }
                    });
                }

                return vm;
            }
        };

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
                    //context.LoadSubjectRegistration();
                    context.GetYearParts(newValue);
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

                vm.AddNewModel.ProvinceId.subscribe(function (newValue) {
                    if (newValue) {
                        ajaxRequest('/Lookup/GetDistrictsByProvinceId/', 'POST', { data: { id: newValue } }, function (response) {
                            if (response.IsSuccess) {
                                vm.AddNewModel.Districts(response.Data);
                            } else {
                                vm.AddNewModel.Districts([]);
                            }
                        });
                    }
                    else {

                    }
                });

                vm.AddNewModel.DistrictId.subscribe(function (newValue) {
                    if (newValue) {
                        ajaxRequest('/Lookup/getlocallevelsbydistrictid/', 'POST', { data: { id: newValue } }, function (response) {
                            if (response.IsSuccess) {
                                vm.AddNewModel.LocalLevels(response.Data);
                            } else {
                                vm.AddNewModel.LocalLevels([]);
                            }
                        });
                    }
                    else {

                    }
                });



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

        context.GetYearParts = function (newValue) {
            if (newValue) {
                ajaxRequest('/Lookup/GetYearPartByProgram/', 'POST', { data: { ProgramId: newValue } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.AddNewModel.YearParts);

                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.AddNewModel.YearParts);
                    }
                });
            }
            else {
                ko.mapping.fromJS([], {}, context.ViewModel.AddNewModel.YearParts);
            }
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


        context.Initialize = function () {
            ajaxRequest('/Student/Registration/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.SearchModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        context.ViewModel.SearchModel.PageSize.subscribe(function (newValue) {
                            context.PerformPaging();
                        });
                        context.ViewModel.SearchModel.PageIndex.subscribe(function (newValue) {
                            context.PerformPaging();
                        });

                        context.ViewModel.SearchModel.LevelId.subscribe(function (newLevelId) {
                            ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: context.ViewModel.SearchModel.CollegeId(), levelId: newLevelId } }, function (response) {
                                if (response.IsSuccess) {

                                    context.ViewModel.SearchModel.Programs(response.Data);
                                } else {
                                    showMessage(context.Title, response.Message, 'error');
                                }
                            });
                        });


                        context.ViewModel.SearchModel.CollegeId.subscribe(function (newCollegeId) {
                            ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: context.ViewModel.SearchModel.LevelId() } }, function (response) {
                                if (response.IsSuccess) {

                                    context.ViewModel.SearchModel.Programs(response.Data);
                                } else {
                                    showMessage(context.Title, response.Message, 'error');
                                }
                            });
                        });
                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel.SearchModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
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
                    showMessage(context.Title, 'Student Information registered successfully.', 'success', function () {
                        if (response.Data != null && response.Data.IsRedirect) {
                            window.location.reload();
                            //window.location = '/Student/Registration/SubjectRegistration/' + response.Data.StudentAdmissionId;
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
                            // window.location = '/Student/Registration/Index';
                            window.reload();
                        }
                    });
                } else {
                    showMessage(context.Title, response.Message, 'error', function () {

                    });
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

                vm.CurrentRecord = ko.observable({});

                vm.SearchClick = function () {
                    context.SearchVerify()

                };

                vm.documentTemplateRenderComplete = function (elements, data) {
                    context.LoadDocument(elements, data);
                    $('.documents').magnificPopup({
                        delegate: 'a.popup-link', // child items selector, by clicking on it popup will open
                        type: 'image',
                        gallery: { enabled: true },
                        image: {
                            titleSrc: 'data-caption'
                        }
                        // other options
                    });
                }

                vm.IsCurrentRecordShown = ko.observable(false);

                vm.LevelId.subscribe(function (newLevelId) {
                    context.LoadProgramForVerify(vm.CollegeId(), newLevelId);
                });

                vm.CollegeId.subscribe(function (newCollegeId) {
                    context.LoadProgramForVerify(newCollegeId, vm.LevelId());
                    //ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                    //    if (response.IsSuccess) {

                    //        vm.Programs(response.Data);
                    //    } else {
                    //        showMessage(context.Title, response.Message, 'error');
                    //    }
                    //});
                });

                vm.ProgramId.subscribe(function (newProgramId) {
                    if (newProgramId) {
                        ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                            if (response.IsSuccess) {

                                vm.YearParts(response.Data);
                            } else {
                                showMessage(context.Title, response.Message, 'error');
                            }
                        });
                    } else {
                        vm.YearParts([]);
                    }

                });

                vm.VerifyClick = function (item) {
                    vm.CurrentVerifyItem = item;
                    context.Verify(item);
                };

                vm.Approve = function (item) {
                    context.Approve(item);
                };

                vm.VerifyContentRenderComplete = function () {
                    context.ApplyVerifyValidation();
                };

                vm.ViewDetail = function (item) {
                    context.ViewDetail(item);
                }

                vm.ViewDetailRenderComplete = function (elements, data) {

                }

                return vm;
            }
        };

        context.LoadProgramForVerify = function (newCollegeId, newLevelId) {
            if (newCollegeId > 0 && newLevelId > 0) {
                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: newLevelId } }, function (response) {
                    if (response.IsSuccess) {

                        context.ViewModel.VerifySearchModel.Programs(response.Data);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            } else {
                context.ViewModel.VerifySearchModel.Programs([]);
            }
        }

        context.LoadDocument = function (elements, data) {
            if (data.DisplayPreview()) {
                if (data.UserAttachmentId() > 0) {
                    ajaxRequest('/Student/Registration/GetDocumentBase64Content', 'POST', { data: { id: data.UserAttachmentId() } }, function (response) {
                        if (response.IsSuccess) {
                            data.UserAttachmentBase64Data(response.Data.Base64Data)
                            //ko.mapping.fromJS(response.Data, {}, currentRecord.PhotoAttachmentViewModel);
                        } else {
                            showMessage(context.Title, response.Message, 'error')
                        }
                    })
                } else {
                    data.UserAttachmentBase64Data('')
                }
            }
        }

        context.LoadSavedImagesForVerify = function (id) {
            if (id <= 0) {
                var currentRecord = context.ViewModel.VerifySearchModel.CurrentRecord()
                currentRecord.PhotoAttachmentViewModel.Base64Data('')
                return false;
            }
            ajaxRequest('/Student/Registration/GetDocumentBase64Content', 'POST', { data: { id: id } }, function (response) {
                if (response.IsSuccess) {
                    var currentRecord = context.ViewModel.VerifySearchModel.CurrentRecord()

                    ko.mapping.fromJS(response.Data, {}, currentRecord.PhotoAttachmentViewModel);
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.Verify = function (item) {

            if (!$('#verifyPostForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.VerifySearchModel);

            delete model.__ko_mapping__;
            delete model.AcademicYears;
            delete model.Programs;
            delete model.SearchClick;
            delete model.VerifyClick;
            delete model.Colleges;
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
        };

        context.Approve = function (item) {

            var model = ko.mapping.toJS(context.ViewModel.VerifySearchModel);

            delete model.AcademicYears;
            delete model.Programs;
            delete model.SearchClick;
            delete model.VerifyClick;
            delete model.Colleges;
            delete model.Records;

            ajaxRequest('/Student/Registration/Verify',
                'POST',
                { data: { id: item.StudentRegistrationID(), searchModel: model } },
                function (response) {
                    if (response.IsSuccess) {
                        //context.ViewModel.VerifySearchModel.CurrentVerifyItem.RegistrationNo(response.Data.FullRegNo);
                        //context.ViewModel.VerifySearchModel.CurrentVerifyItem.VerifiedBy(response.Data.VerifiedBy);
                        showMessage(context.Title, 'Student Approved successfully', 'success');
                        //context.ViewModel.VerifySearchModel.CurrentVerifyItem.StudentRegistrationIndex(response.Data.RegNoIndex);
                        context.SearchVerify();
                        //context.ViewDetail()
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        };

        context.ViewDetail = function (item) {
            ajaxRequest('/Student/Registration/Detail',
                'POST',
                { data: { id: item.ExamRegistrationID() } },
                function (response) {
                    if (response.IsSuccess) {
                        context.ViewModel.VerifySearchModel.IsCurrentRecordShown(true)
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.VerifySearchModel.CurrentRecord);
                        if (!ko.dataFor($('#viewDetailContent')[0])) {
                            ko.applyBindings(context.ViewModel.VerifySearchModel, $('#viewDetailContent')[0]);
                        }

                        context.LoadSavedImagesForVerify(context.ViewModel.VerifySearchModel.CurrentRecord().UserAttachmentId());
                    } else {
                        showMessage(response.Message);
                    }
                });
        }

        context.SearchVerify = function () {
            if (!$('#verifyForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.VerifySearchModel);

            delete model.AcademicYears;
            delete model.Programs;
            delete model.SearchClick;
            delete model.VerifyClick;
            delete model.Records;

            ajaxRequest('/Student/Registration/SearchVerify', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data.Records, {}, context.ViewModel.VerifySearchModel.Records);
                    context.ViewModel.VerifySearchModel.StartingRegNoIndex(response.Data.StartIndex);

                    if (ko.dataFor($('#viewDetailContent')[0])) {

                    }
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

        //view reg card
        context.ViewRegCardMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchClick = function () {
                    context.SearchViewRegCard();
                };

                vm.RenderComplete = function () {
                    context.ApplyViewRegCardSearchValidation();
                };

                vm.SelectAll = ko.observable(false);

                vm.SelectAll.subscribe(function (newValue) {
                    context.SelectAll(newValue);
                });

                vm.CollegeId.subscribe(function (newCollegeId) {
                    ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                        if (response.IsSuccess) {

                            vm.Programs(response.Data);
                        } else {
                            vm.Programs([]);
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                });

                vm.ViewRegistrationCardClick = function () {
                    context.ViewRegistrationCard();
                };

                vm.PrintClick = function () {
                    context.PrintRegistrationCard();
                };

                return vm;
            }
        };

        context.SelectAll = function (newValue) {
            $(context.ViewModel.RegsitrationCardViewSearchModel.Records()).each(function (index, item) {
                item.IsSelected(newValue);
            });
        };

        context.ViewRegistrationCard = function () {
            var model = ko.toJS(context.ViewModel.RegsitrationCardViewSearchModel);
            var selectedIds = [];

            $(model.Records).each(function (index, item) {
                if (item.IsSelected) {
                    selectedIds.push(item.StudentInfo.StudentRegistrationID);
                }
            });

            if (selectedIds.length < 1) {
                showMessage(context.Title, 'At least one student has to be selected for obtaining admit card.', 'error');
                return false;
            }

            delete model.__ko_mapping__;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.Programs;
            delete model.Records;
            delete model.SearchClick;
            delete model.RenderComplete;
            delete model.ViewRegistrationCardClick;
            delete model.PrintClick;
            delete model.PrintRecords;

            ajaxRequest('/Student/Registration/RegistrationCard', 'POST', { data: { model: model, selectedIds: selectedIds } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#printContent')[0])) {
                        context.ViewModel.RegsitrationCardViewSearchModel.PrintRecords = ko.mapping.fromJS(response.Data);

                        ko.applyBindings(context.ViewModel.RegsitrationCardViewSearchModel, $('#printContent')[0]);

                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.RegsitrationCardViewSearchModel.PrintRecords);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.PrintRegistrationCard = function () {
            var model = ko.toJS(context.ViewModel.RegsitrationCardViewSearchModel);
            var selectedIds = [];

            $(model.Records).each(function (index, item) {
                if (item.IsSelected) {
                    selectedIds.push(item.StudentInfo.StudentRegistrationID);
                }
            });

            if (selectedIds.length < 1) {
                showMessage(context.Title, 'At least one student has to be selected for obtaining admit card.', 'error');
                return false;
            }

            delete model.__ko_mapping__;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.Programs;
            delete model.Records;
            delete model.SearchClick;
            delete model.RenderComplete;
            delete model.ViewRegistrationCardClick;
            delete model.PrintClick;
            delete model.PrintRecords;

            ajaxRequest('/Student/Registration/PrintRegistrationCard', 'POST', { data: { model: model, selectedIds: selectedIds } }, function (response) {
                if (response.IsSuccess) {
                    window.open('/Student/Registration/Download');
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };
        context.SearchViewRegCard = function () {
            if (!$('#cardViewForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.RegsitrationCardViewSearchModel);
            delete model.__ko_mapping__;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.Programs;
            delete model.Records;
            delete model.SearchClick;
            delete model.RenderComplete;
            delete model.ViewRegistrationCardClick;
            delete model.PrintClick;

            ajaxRequest('/Student/Registration/SearchRegistrationCardView', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data.Records, {}, context.ViewModel.RegsitrationCardViewSearchModel.Records);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
            //SearchRegistrationCardView
        };

        context.InitializeRegsitrationCardView = function () {
            ajaxRequest('/Student/Registration/InitializeRegsitrationCardView', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.RegsitrationCardViewSearchModel = ko.mapping.fromJS(response.Data, context.ViewRegCardMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.RegsitrationCardViewSearchModel);
                    }
                    context.ApplySearchVerifyMapping();
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        context.ApplyViewRegCardSearchValidation = function () {
            $('#cardViewForm').validate({
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

        //file upload context
        context.InitializeFileUpload = function (oldid, oncomplete) {
            $(".upload").upload({
                maxSize: 1073741824,
                beforeSend: context.onBeforeSend,
                action: '/FileUpload/Upload/',
                postKey: 'uploadFile',
                label: 'Select Photo to upload for this student',
                postData: {}
            }).on("start.upload", context.onStart)
                .on("complete.upload", context.onComplete)
                .on("filestart.upload", context.onFileStart)
                .on("fileprogress.upload", context.onFileProgress)
                .on("filecomplete.upload", oncomplete)
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
            var isValid = file.file.type === 'image/png' || file.file.type === 'image/jpeg';
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
            //var responseObj = eval('(' + response + ')') || {};
            //if (responseObj.IsSuccess && responseObj.Data) {
            //    context.ViewModel.AddNewModel.UserAttachmentId(responseObj.Data.Id);
            //    $("#photoId").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
            //}
            console.log("File Complete");
            //if (response.trim() === "" || response.toLowerCase().indexOf("error") > -1) {
            //    $(this).parents("form").find(".filelist.queue")
            //        .find("li[data-index=" + file.index + "]").addClass("error")
            //        .find(".progress").text(response.trim());
            //} else {
            //    var $target = $(this).parents("form").find(".filelist.queue").find("li[data-index=" + file.index + "]");
            //    $target.find(".file").text(file.name);
            //    $target.find(".progress").remove();
            //    $target.find(".cancel").remove();
            //    $target.appendTo($(this).parents("form").find(".filelist.complete"));
            //}
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
        //context.InitializeOldFormatCreate = function (formId) {
        //    context.CreateFormId = '#' + formId;
        //    context.LoadCreateModel();
        //};

        //context.LoadOldFomatCreateModel = function () {
        //    var id = $('#StudentRegistrationID').val();
        //    ajaxRequest('/Student/Registration/InitializeCreate', 'GET', { data: { id: id } }, function (response) {
        //        if (response.IsSuccess) {
        //            if (!ko.dataFor($(context.CreateFormId))) {
        //                //new
        //                context.ViewModel = ko.mapping.fromJS(response.Data, context.CreateMapping);

        //                ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.DefaultAddNewModel);

        //                ko.applyBindings(context.ViewModel, $(context.CreateFormId)[0]);

        //            } else {
        //                ko.mapping.fromJS(response.Data, {}, context.ViewModel);
        //            }
        //            context.ApplySaveValidation();
        //        } else {
        //            showMessage(context.Title, response.Message, 'error');
        //        }
        //    });
        //};

        //context.ApplySaveValidation = function () {
        //    $(context.CreateFormId).validate({
        //        rules: {

        //        }
        //    });


        //};

        //endregion old format

        //region partial entry

        context.PartialMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.UserAttachmentDocumentContent = ko.mapping.fromJS({
                    Base64Data: '',
                    ContentType: '',
                    FileName: ''
                });
                vm.RenderComplete = function () {
                    context.ApplySavePartialValidation();
                    context.InitializeFileUpload(null, function (e, file, response) {
                        var responseObj = eval('(' + response + ')') || {};
                        if (responseObj.IsSuccess && responseObj.Data) {
                            context.ViewModel.PartialEntryVM.UserAttachmentId(responseObj.Data.Id);
                            $("#photoImagePreview").attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                        }
                    });
                    var id = context.ViewModel.PartialEntryVM.StudentRegistrationID();
                    if (id > 0) {
                        context.LoadSavedImagesForPartial(context.ViewModel.PartialEntryVM.UserAttachmentId())
                    }

                };

                vm.SaveRegistrationClick = function () {
                    context.SavePartialRegistration();
                };

                vm.AddSubjectsClick = function () {
                    var instance = ko.toJS(vm.PartialSubjectRegistration.AddNewTemplateSubject);
                    vm.PartialSubjectRegistration.SelectedSubjects.push(instance);
                }

                vm.ProgramId.subscribe(function (newValue) {
                    context.LoadSubjectRegistrationForPartialEntry();
                    context.LoadYearPart(newValue);
                });

                vm.LastName.subscribe(function (newValue) {
                    vm.FatherLastName(newValue);
                    vm.MotherLastName(newValue);
                });

                vm.PreviousYears = ko.observableArray([{ Id: 2070, Description: '2070' }, { Id: 2071, Description: '2071' }, { Id: 2072, Description: '2072' }, { Id: 2073, Description: '2073' }, { Id: 2074, Description: '2074' }, { Id: 2075, Description: '2075' }]);

                vm.RegistrationNo.subscribe(function (newRegistrationNo) {
                    //
                    //calland check here
                    if (newRegistrationNo && newRegistrationNo.length > 0) {
                        context.LoadStudentInfoByRegNo(newRegistrationNo);
                    }
                })

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


                vm.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForPartialEntry();
                });

                return vm;
            }
        };


        context.LoadYearPart = function (newProgramId) {
            if (newProgramId) {
                ajaxRequest('/Cascade/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                    var yearParts = [];
                    if (response.IsSuccess) {
                        yearParts = response.Data;
                    } else {
                        yearParts = [];
                    }
                    ko.mapping.fromJS(yearParts, {}, context.ViewModel.PartialEntryVM.YearParts);
                });
            }
            else {
                ko.mapping.fromJS([], {}, context.ViewModel.PartialEntryVM.YearParts);

            }
        }

        context.LoadSavedImagesForPartial = function (id) {
            ajaxRequest('/Student/Registration/GetDocumentBase64Content', 'POST', { data: { id: id } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.PartialEntryVM.UserAttachmentDocumentContent);
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.LoadStudentInfoByRegNo = function (registrationNo) {
            ajaxRequest('/Student/Registration/GetStudentRegNo', 'POST', { data: { registrationNo: registrationNo } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.PartialEntryVM);
                } else {
                    showMessage(context.Title, response.Message, 'error')
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
                },
                messages: {
                    AcademicYearId: { required: "Please select an academic year" },
                    CollegeId: { required: "Please select a college" },
                    ProgramId: { required: "Please select a program" },
                    FirstName: { required: "First name is required" },
                    LastName: { required: "Last name is required" },
                    RegistrationNo: { required: "Registration number is required" },
                    BirthDateBS: { required: "Birth date (BS) is required" },
                    BirthDateAD: { required: "Birth date (AD) is required" },
                    GenderId: { required: "Please select a gender" }
                },
                invalidHandler: function (event, validator) {
                    var errors = validator.numberOfInvalids();

                    if (errors) {
                        var errorFields = [];
                        for (var i = 0; i < validator.errorList.length; i++) {
                            var fieldName = validator.errorList[i].element.name;
                            var readableFieldName = fieldName
                                .replace(/([A-Z])/g, ' $1')
                                .replace(/^./, function (str) { return str.toUpperCase(); })
                                .replace('Id', '');
                            errorFields.push(readableFieldName);
                        }

                        showMessage(context.Title, "Please fill in the following required fields: \n• " + errorFields.join("\n• "), 'error');
                    }
                }
            });
        };

        context.LoadProgramForPartialEntry = function () {
            var collegeId = context.ViewModel.PartialEntryVM.CollegeId();
            if (collegeId && collegeId > 0) {
                ajaxRequest('/Cascade/GetProgramByCollege', 'POST', { data: { collegeId: collegeId, levelid: context.ViewModel.PartialEntryVM.LevelId() } }, function (response) {
                    if (response.IsSuccess) {

                        context.ViewModel.PartialEntryVM.Programs(response.Data);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
            else {

                context.ViewModel.PartialEntryVM.Programs([]);
            }
        };

        context.InitializePartial = function (formId, model) {
            context.ViewModel.PartialEntryVM = ko.mapping.fromJS(model, context.PartialMapping);
            ko.applyBindings(context.ViewModel.PartialEntryVM, $(formId)[0]);
        };

        context.SavePartialRegistration = function () {
            if (!$('#studentRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.PartialEntryVM);
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

            model.BirthDateAD = moment(model.BirthDateAD).isValid() ? moment(model.BirthDateAD).format('YYYY-MM-DD') : '';

            ajaxRequest('/Registration/Application/Create', 'POST', {
                data: { model: model },
            }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, 'Student Information registered successfully.', 'success', function () {
                        if (true) {//response.Data != null && response.Data.IsRedirect) {
                            //    window.location = '/Student/Registration/SubjectRegistration/' + response.Data.StudentAdmissionId;
                            window.location.reload();
                        }
                        else if (response.Data != null) {
                            var saveModel = model;

                            var addNewModel = context.ViewModel.PartialEntryVM;
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
                            goToByScroll('RegistrationNo');
                            $("#RegistrationNo").focus();

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
                                context.LoadQualification();

                                //var newRollNo = context.SetNewRollNo(saveModel.SubjectRegistrationViewModel.SuggestedExamRollNo);
                                ////no student information found for provided reg no
                                ////set new roll no
                                //context.ViewModel.AddNewModel.SubjectRegistrationViewModel.SuggestedExamRollNo(newRollNo);
                            }

                        } else {
                            window.location = '/Student/Registration/Index';
                        }
                    });
                } else {
                    showMessage(context.Title, response.Message, 'error', function () {

                    });
                }
            });
        };

        context.LoadSubjectRegistrationForPartialEntry = function () {
            if (context.ViewModel.PartialEntryVM.ProgramId && context.ViewModel.PartialEntryVM.ProgramId() > 0) {
                var model = ko.mapping.toJS(context.ViewModel.PartialEntryVM);
                var m = {
                    AcademicYearId: model.AcademicYearId,
                    CollegeId: model.CollegeId,
                    ProgramId: model.ProgramId,
                    EntryFormat: context.ViewModel.PartialEntryVM.EntryFormat
                };
                if (!(m.AcademicYearId > 0 && m.ProgramId > 0 && m.CollegeId > 0)) {
                    return false;
                }

                ajaxRequest('/Cascade/GetSubjectRegistrationFromProgramId', 'POST', { data: m }, function (response) {
                    if (response.IsSuccess) {
                        context.ViewModel.PartialEntryVM.PartialSubjectRegistration.AllSubjects(response.Data.AllSubjects);
                        var currentRollNo = context.ViewModel.PartialEntryVM.PartialSubjectRegistration.ExamRollNo();
                        if (currentRollNo && currentRollNo.length > 0) {
                            //not changing
                        }
                        else {
                            context.ViewModel.PartialEntryVM.PartialSubjectRegistration.SuggestedExamRollNo(response.Data.SuggestedExamRollNo);
                        }
                        //ko.mapping.fromJS(response.Data.AllSubjects, {}, context.ViewModel.PartialEntryVM.PartialSubjectRegistration.AllSubjects);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        };
        //endregion partial entry

    })(emis.studentRegistration);
});
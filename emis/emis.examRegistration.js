$(function () {
    emis.CreateNamespace('examRegistration');

    (function (context) {

        context.Title = 'Exam Registration';
        context.CreateFormId = '#frm';
        context.CreateSearchFormId = '#searchForm';

        context.ViewModel = {
            ExamRegistrationCreateVM: {
                Search: function () {
                    context.Search();
                },
                Save: function () {
                    context.SaveExamRegistration();
                },
                RegsiterClick: function (item) {
                    context.RegisterInidividual(item);
                }
            },
            ExamRegistrationIndexVM: {
                SearchClick: function () {
                    context.SearchRecords();
                },
                ExportUnSubmittedRegularClick: function () {
                    context.InitialzeUnSubmittedStudentsExport();
                },
                SearchListClick: function () {
                    context.SearchRecordsForList();
                },
                EditClick: function (item) {
                    context.Edit(item.ExamRegistrationID());
                },
                EditPartialClick: function (item) {
                    context.EditPartial(item.ExamRegistrationID());
                },
                EditPartialClickNewTab: function (item) {
                    context.EditPartialNewTab(item.ExamRegistrationID());
                },
                DeleteClick: function (item) {
                    context.Delete(item.ExamRegistrationID());
                },
                ExportClick: function () {
                    context.Export(true);
                },
                ExportSeparateClick: function () {
                    context.ExportSeparate(true);
                },
                PrintClick: function () {
                    context.Export(false);
                },
                ExportSubjectSummaryClick: function () {
                    context.ExportSubjectSummary();
                },
                ExportSubjectSummaryPivotClick: function () {
                    context.ExportSubjectSummaryPivot();
                },
                ExportProgramSummaryClick: function () {
                    context.ExportProgramSummary();
                },
                ExportSubjectTriplicateClick: function () {
                    context.ExportSubjectTriplicate();
                },
                ExportSubjectTriplicateWithCodeClick: function () {
                    context.ExportSubjectTriplicateWithCode();
                },
                ExportPaymentTriplicate: function () {
                    context.InitializePaymentExport();
                },
                ResetExamRollNoClick: function () {
                    //context.ResetExamRollNo();
                },
                ViewDetailClick: function (item) {
                    if (!$('#listRegistrationForm').valid()) {
                        return false;
                    }
                    var id = item.ExamRegistrationID();
                    var index = $.map(context.ViewModel.ExamRegistrationIndexVM.Records(), function (obj, index) {
                        if (obj.ExamRegistrationID() === id) {
                            return index;
                        }
                    })[0];

                    context.ViewModel.ExamRegistrationIndexVM.SearchModel.CurrentRecordIndex(index);

                    context.ViewDetail(id);
                }
            },
            ExamRegistrationEditVM: {
                UpdateClick: function () {
                    context.Update();
                }
            },
            ExamRegistrationCreateWizardVM: {
                Search: function () {
                    var vm = context.ViewModel.ExamRegistrationCreateWizardVM;
                    vm.SearchModel.Step(1);
                    context.SearchWizard();
                },
                Next: function () {
                    context.NextWizard();
                },
                Save: function () {
                    context.SaveWizardExamRegistration();
                }
            }
        };

        //create related
        context.SaveExamRegistration = function () {
            var searchModel = ko.toJS(context.ViewModel.ExamRegistrationCreateVM.SearchModel);
            var saveContent = ko.toJS(context.ViewModel.ExamRegistrationCreateVM.CreateContent);

            delete searchModel.__ko_mapping__;
            delete saveContent.__ko_mapping__;
            ajaxRequest('/Exam/Registration/Create', 'POST', { data: { filterModel: searchModel, contentModel: saveContent } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function () {
                        window.location = '/Exam/Registration/Index';
                    });
                } else {
                    showMessage(context.Title, response.Message, 'error', function () { }, true);
                }
            });
        }

        context.ExamRegistrationCreateMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.DistrictId.subscribe(function (newValue) {
                    context.LoadCollege(newValue);
                });

                vm.CollegeID.subscribe(function (newValue) {
                    context.LoadProgram(newValue, vm.LevelId());
                });

                vm.LevelId.subscribe(function (newValue) {
                    context.LoadProgram(vm.CollegeID(), newValue);
                })

                vm.ProgramId.subscribe(function (newValue) {
                    context.LoadYearPart(newValue);
                });

                return vm;
            }
        }
        context.LoadCollege = function (newDistrictId) {
            ajaxRequest('/Lookup/GetCollegeByDistrict', 'POST', { data: { districtId: newDistrictId } }, function (response) {
                var colleges = [];
                if (response.IsSuccess) {
                    colleges = response.Data;
                } else {
                    colleges = [];
                }
                ko.mapping.fromJS(colleges, {}, context.ViewModel.ExamRegistrationCreateVM.SearchModel.Colleges);
            });
        };

        context.LoadProgram = function (newCollegeId, levelId) {
            if (newCollegeId > 0 && levelId > 0) {
                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: levelId } }, function (response) {
                    var programs = [];
                    if (response.IsSuccess) {
                        programs = response.Data;
                    } else {
                        programs = [];
                    }
                    ko.mapping.fromJS(programs, {}, context.ViewModel.ExamRegistrationCreateVM.SearchModel.Programs);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamRegistrationCreateVM.SearchModel.Programs);

            }
        };

        context.LoadYearPart = function (newProgramId) {
            ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                var yearParts = [];
                if (response.IsSuccess) {
                    yearParts = response.Data;
                } else {
                    yearParts = [];
                }
                ko.mapping.fromJS(yearParts, {}, context.ViewModel.ExamRegistrationCreateVM.SearchModel.YearParts);
            });
        }
        context.Search = function () {
            if (!$(context.CreateSearchFormId).valid()) {
                return false;
            }
            var searchModel = ko.mapping.toJS(context.ViewModel.ExamRegistrationCreateVM.SearchModel);
            delete searchModel.__ko_mapping__;

            ajaxRequest('/Exam/Registration/SearchCreate', 'POST', { data: { searchModel: searchModel } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#examRegistrationCreateContent')[0])) {
                        context.ViewModel.ExamRegistrationCreateVM.CreateContent = ko.mapping.fromJS(response.Data);
                        context.ViewModel.ExamRegistrationCreateVM.CreateContent.RegisterClick = function (item) {
                            context.RegisterIndividual(item);
                        }
                        ko.applyBindings(context.ViewModel.ExamRegistrationCreateVM, $('#examRegistrationCreateContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationCreateVM.CreateContent);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.InitializeCreate = function () {
            ajaxRequest('/Exam/Registration/InitializeCreate', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($(context.CreateSearchFormId)[0])) {
                        context.ViewModel.ExamRegistrationCreateVM.SearchModel = ko.mapping.fromJS(response.Data, context.ExamRegistrationCreateMapping);

                        ko.applyBindings(context.ViewModel.ExamRegistrationCreateVM, $(context.CreateSearchFormId)[0]);
                    } else {
                        //context.ViewModel.ExamRegistrationCreateVM = ko.mapping.fromJS(response.Data, context.ExamRegistrationCreateMapping);
                        ko.mapping.fromJS(response.Data, context.ExamRegistrationCreateMapping, context.ViewModel.ExamRegistrationCreateVM.SearchModel);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.RegisterIndividual = function (item, element) {
            var aItem = ko.toJS(item);

            var searchModel = ko.toJS(context.ViewModel.ExamRegistrationCreateVM.SearchModel);
            delete searchModel.__ko_mapping__;
            var subjects = ko.toJS(context.ViewModel.ExamRegistrationCreateVM.CreateContent).Subjects;
            var selectedSubjects = $(subjects).filter(function (index, item) {
                return item.IsSelected === true;
            }).toArray();
            var selectedSubjectIds = $(selectedSubjects).map(function (index, item) {
                return item.SubjectDetailId;
            }).toArray();
            if (selectedSubjects.length <= 0) {
                showMessage(context.Title, ' Please select at least one subject to save.', 'error');
            } else {
                var studentId = aItem.StudentProgramYearPartID;
                ajaxRequest('/Exam/Registration/RegisterIndividual',
                    'POST',
                    {
                        data: { studentId: studentId, subjects: selectedSubjectIds, academicYearId: searchModel.AcademicYearId, collegeId: searchModel.CollegeID },
                        enableLadda: true,
                        targetLaddaElement: '[data-button-type=register]'
                    },
                    function (response) {
                        if (response.IsSuccess) {
                            context.Search();
                            showMessage(context.Title, response.Message, 'success');
                        } else {
                            showMessage(context.Title, response.Message, 'error', function () { }, true);

                        }
                    });
            }
        }

        //wizard  created

        context.SaveWizardExamRegistration = function () {
            var searchModel = ko.mapping.toJS(context.ViewModel.ExamRegistrationCreateWizardVM.SearchModel);
            var saveContent = ko.mapping.toJS(context.ViewModel.ExamRegistrationCreateWizardVM.CreateContent.SubjectRegistrations);
            delete searchModel.Colleges;
            delete searchModel.Districts;
            delete searchModel.AcademicYears;
            delete searchModel.Programs;

            ajaxRequest('/Exam/Registration/Wizard', 'POST', { data: { filterModel: searchModel, contentModel: saveContent } }, function (response) {
                if (response.IsSuccess) {
                    context.NextWizard();
                    showMessage(context.Title, response.Message, 'success', function () {
                    });
                } else {
                    showMessage(context.Title, response.Message, 'error', function () { }, true);
                }
            });
        }

        context.ExamRegistrationCreateWizardMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.DistrictId.subscribe(function (newValue) {
                    var colleges = [];
                    if (newValue) {
                        ajaxRequest('/Lookup/GetCollegeByDistrict', 'POST', { data: { districtId: newValue } }, function (response) {
                            var colleges = [];
                            if (response.IsSuccess) {
                                colleges = response.Data;
                            } else {
                                colleges = [];
                            }
                            ko.mapping.fromJS(colleges, {}, vm.Colleges);
                        });
                    }
                    else {
                        ko.mapping.fromJS(colleges, {}, vm.Colleges);

                    }
                });

                vm.CollegeID.subscribe(function (newValue) {
                    var programs = [];
                    if (newValue) {
                        ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newValue } }, function (response) {
                            var programs = [];
                            if (response.IsSuccess) {
                                programs = response.Data;
                            } else {
                                programs = [];
                            }
                            ko.mapping.fromJS(programs, {}, vm.Programs);
                        });
                    }
                    else {
                        ko.mapping.fromJS(programs, {}, vm.Programs);

                    }
                });

                vm.ProgramId.subscribe(function (newValue) {
                    var yearParts = [];
                    if (newValue) {
                        ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newValue } }, function (response) {
                            var yearParts = [];
                            if (response.IsSuccess) {
                                yearParts = response.Data;
                            } else {
                                yearParts = [];
                            }
                            ko.mapping.fromJS(yearParts, {}, vm.YearParts);
                        });
                    }
                    else {
                        ko.mapping.fromJS(yearParts, {}, vm.YearParts);
                    }
                });

                vm.RenderComplete = function () {
                    $('#searchForm').validate({
                        rules: {
                            AcademicYearId: { required: true },
                            DistrictId: { required: true },
                            CollegeID: { required: true },
                            ProgramId: { required: true },
                            YearPartId: { required: true },
                        }
                    });
                };

                return vm;
            }
        };

        context.NextWizard = function () {
            var vm = context.ViewModel.ExamRegistrationCreateWizardVM;
            vm.SearchModel.Step(vm.SearchModel.Step() + 1);
            context.SearchWizard();
        };

        context.SearchWizard = function () {
            if (!$(context.CreateSearchFormId).valid()) {
                return false;
            }
            var searchModel = ko.mapping.toJS(context.ViewModel.ExamRegistrationCreateWizardVM.SearchModel);
            delete searchModel.Colleges;
            delete searchModel.Districts;
            delete searchModel.AcademicYears;
            delete searchModel.Programs;

            ajaxRequest('/Exam/Registration/SearchWizard', 'POST', { data: { searchModel: searchModel } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#examRegistrationCreateContent')[0])) {
                        context.ViewModel.ExamRegistrationCreateWizardVM.CreateContent = ko.mapping.fromJS(response.Data);
                        //context.ViewModel.ExamRegistrationCreateVM.CreateContent.RegisterClick = function (item) {
                        //    context.RegisterIndividual(item);
                        //}
                        ko.applyBindings(context.ViewModel.ExamRegistrationCreateWizardVM, $('#examRegistrationCreateContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationCreateWizardVM.CreateContent);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.InitializeWizard = function () {
            ajaxRequest('/Exam/Registration/InitializeWizard', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#searchContent')[0])) {
                        context.ViewModel.ExamRegistrationCreateWizardVM.SearchModel = ko.mapping.fromJS(response.Data, context.ExamRegistrationCreateWizardMapping);

                        ko.applyBindings(context.ViewModel.ExamRegistrationCreateWizardVM, $('#searchContent')[0]);
                    } else {
                        //context.ViewModel.ExamRegistrationCreateVM = ko.mapping.fromJS(response.Data, context.ExamRegistrationCreateMapping);
                        ko.mapping.fromJS(response.Data, context.ExamRegistrationCreateMapping, context.ViewModel.ExamRegistrationCreateWizardVM.SearchModel);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        //Index Page Related
        context.IndexMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                //vm.DistrictId.subscribe(function (newValue) {
                //    context.LoadCollegeForIndex(newValue);
                //});
                if (options.data.AcademicYears.length == 1) {
                    vm.AcademicYearId(options.data.AcademicYears[0].Id);
                }

                if (options.data.Colleges.length == 1) {
                    vm.CollegeId(options.data.Colleges[0].Id);
                }


                vm.LevelId.subscribe(function (newValue) {
                    context.LoadProgramForIndex(vm.CollegeId(), newValue);
                });

                vm.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForIndex(newValue, vm.LevelId());
                });
                vm.ProgramId.subscribe(function (newValue) {
                    context.LoadYearPartForIndex(newValue);
                });
                vm.TotalRecordCount = ko.observable(0);
                vm.CurrentRecordIndex = ko.observable(0);

                vm.SearchForVerifyByToken = function () {
                    context.SearchForVerifyByToken();
                }

                return vm;
            }
        };

        context.ConfirmNotify = function () {
            var id = context.ViewModel.ExamRegistrationIndexVM.DetailVM.ExamRegistrationId();
            var message = $("#MessageContent").val() || '';
            if (id > 0 && message != '') {
                ajaxRequest('/Exam/Registration/SendSMS', 'POST', { data: { id: id, content: message } }, function (response) {
                    if (response.IsSuccess) {
                        swal("Exam Registration", "Message sent successfully", "success");
                        $('#modal-form').modal('hide');
                        $("#MessageContent").val('');
                    } else {
                        swal(context.Title, response.Message || "Soemthing went wrong", "error")
                    }
                });
            }
            else {
                swal(context.Title, 'Please make sure that you have selected the student properly and message is not empty.', "error")
            }
        }

        context.SendEmailNotification = function () {
            var id = context.ViewModel.ExamRegistrationIndexVM.DetailVM.ExamRegistrationId();
            var message = $("#MessageContent").val() || '';
            if (id > 0 && message != '') {
                ajaxRequest('/Exam/Registration/SendEmailNotification', 'POST', { data: { id: id, content: message } }, function (response) {
                    if (response.IsSuccess) {
                        swal("Exam Registration", "Message sent successfully", "success");
                        $("#MessageContent").val('');
                        $('#modal-form').modal('hide');
                    } else {
                        swal(context.Title, response.Message || "Soemthing went wrong", "error")
                    }
                });
            }
            else {
                swal(context.Title, 'Please make sure that you have selected the student properly and message is not empty.', "error")
            }
        }

        context.Notify = function () {
            var id = context.ViewModel.ExamRegistrationIndexVM.DetailVM.ExamRegistrationId();
            if (id > 0) {
                $('#modal-form').modal('show');

            } else {
                swal("Error", "Please make sure application is selected properly.", "error");
            }
        }


        context.LoadProgramForIndex = function (newCollegeId, newlevelId) {
            if (newCollegeId > 0 && newlevelId) {
                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: newlevelId } }, function (response) {
                    var programs = [];
                    if (response.IsSuccess) {
                        programs = response.Data;
                    } else {
                        programs = [];
                    }
                    ko.mapping.fromJS(programs, {}, context.ViewModel.ExamRegistrationIndexVM.SearchModel.Programs);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamRegistrationIndexVM.SearchModel.Programs);
            }

        };

        context.LoadYearPartForIndex = function (newProgramId) {
            if (newProgramId) {
                ajaxRequest('/Cascade/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                    var yearParts = [];
                    if (response.IsSuccess) {
                        yearParts = response.Data;
                    } else {
                        yearParts = [];
                    }
                    ko.mapping.fromJS(yearParts, {}, context.ViewModel.ExamRegistrationIndexVM.SearchModel.YearParts);
                });
            }
            else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamRegistrationIndexVM.SearchModel.YearParts);

            }

        };
        context.LoadCollegeForIndex = function (newDistrictId) {
            if (newDistrictId > 0) {

                ajaxRequest('/Lookup/GetCollegeByDistrict', 'POST', { data: { districtId: newDistrictId } }, function (response) {
                    var colleges = [];
                    if (response.IsSuccess) {
                        colleges = response.Data;
                    } else {
                        colleges = [];
                    }
                    ko.mapping.fromJS(colleges, {}, context.ViewModel.ExamRegistrationIndexVM.SearchModel.Colleges);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamRegistrationIndexVM.SearchModel.Colleges);
            }
        };

        context.Initialize = function () {
            ajaxRequest('/Exam/Registration/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.ExamRegistrationIndexVM.SearchModel = ko.mapping.fromJS(response.Data, context.IndexMapping);

                        ko.applyBindings(context.ViewModel.ExamRegistrationIndexVM, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationIndexVM.SearchModelSearchModel);
                    }
                    context.ListSearchValidation();
                    $("#reg-form").dxDataGrid({
                        showRowLines: true,
                        columnAutoWidth: true,
                        allowColumnReordering: true,
                        allowColumnResizing: true,
                        showBorders: true,
                        showRowLines: true,
                        columns: [
                            {
                                dataField: "ExamRegistrationID",
                                caption: "Token No"
                            }, {
                                dataField: "RegistrationNo",
                                caption: "Reg No"
                            },
                            {
                                dataField: "FullName",
                                caption: "Name",
                            },
                            {
                                dataField: "ShortName",
                                caption: "Program"
                            },
                            {
                                dataField: "ExamRollNo",
                                caption: "Roll No"
                            },
                            { dataField: "Year" },
                            { dataField: "Part" },
                            {
                                dataField: "SubjectRegisteredCount",
                                caption: "Subject(s)"
                            },
                            {
                                allowExporting: false,
                                cellTemplate: function (c, o) {
                                    $("<a />")
                                        .attr("href", "javascript:void(0)")
                                        .addClass("btn btn-xs btn-warning")
                                        .html(`<i class="fa fa-pencil"></i> &nbsp; Edit in New Tab`)
                                        .on("click", function (e) {
                                            emis.examRegistration.EditPartialNewTab(o.data.ExamRegistrationID);
                                        }).appendTo(c);

                                    $("<a />")
                                        .attr("href", "javascript:void(0)")
                                        .addClass("btn btn-xs btn-warning m-l-sm")
                                        .html(`<i class="fa fa-eye"></i> &nbsp; View Detail`)
                                        .on("click", function (e) {
                                            emis.examRegistration.ViewDetail(o.data.ExamRegistrationID);
                                        }).appendTo(c);
                                    if (!o.data.VerifiedDate) {
                                        $("<a />")
                                            .attr("href", "javascript:void(0)")
                                            .addClass("btn btn-xs btn-danger m-l-sm")
                                            .html(`<i class="fa fa-trash"></i> &nbsp; Delete`)
                                            .on("click", function (e) {
                                                emis.examRegistration.Delete(o.data.ExamRegistrationID);
                                            }).appendTo(c);
                                    }
                                }
                            }
                        ],
                        onRowPrepared: function (e) {
                            if (e.rowType == "data") {
                                if (e.data.VerifiedBy && e.data.RoleID == 1) {
                                    e.rowElement.addClass("bg-primary");
                                }
                                else if (e.data.VerifiedBy) {
                                    e.rowElement.addClass("bg-success");
                                }
                            }

                        },

                        searchPanel: { visible: true },
                        pager: {
                            allowedPageSizes: "auto",
                            displayMode: "adaptive",
                            infoText: "Page {0} of {1} ({2} items)",
                            showInfo: true,
                            showNavigationButtons: true,
                            showPageSizeSelector: true,
                            allowedPageSizes: [50, 100, 200, 500, 'all'],
                            visible: "auto"
                        },
                        paging: {
                            enabled: true,
                            pageIndex: 0,
                            pageSize: 10
                        },
                        export: {
                            enabled: true,
                            fileName: "Registration List"
                        }
                    })

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.InitializeAdminApprove = function () {
            ajaxRequest('/Exam/Registration/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.ExamRegistrationIndexVM.SearchModel = ko.mapping.fromJS(response.Data, context.IndexMapping);

                        ko.applyBindings(context.ViewModel.ExamRegistrationIndexVM, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationIndexVM.SearchModelSearchModel);
                    }
                    context.ListSearchValidation();
                    $("#reg-form").dxDataGrid({
                        selection: {
                            allowSelectAll: true,
                            deferred: false,
                            mode: "multiple",
                            selectAllMode: "allPages",
                            showCheckBoxesMode: "always"
                        },
                        keyExpr: "ExamRegistrationID",
                        showRowLines: true,
                        columnAutoWidth: true,
                        allowColumnReordering: true,
                        allowColumnResizing: true,
                        showBorders: true,
                        showRowLines: true,
                        toolbar: {
                            items: [{
                                widget: "dxButton",
                                options: {
                                    text: "Approve",
                                    type: "contained",
                                    disabled: true,
                                    elementAttr: { id: "ApproveBtn" },
                                    onClick: function (e) {
                                        var data = $("#reg-form").dxDataGrid("instance").option("selectedRowKeys")
                                        if (data && data.length > 0) {
                                            ajaxRequest('/Exam/Registration/ApproveByAdmin', 'POST', { data: { id: data } }, function (response) {
                                                if (response.IsSuccess) {
                                                    showMessage(context.Title, 'Approved sucessfully', 'success');
                                                } else {
                                                    showMessage(context.Title, response.Message, 'error');
                                                }
                                            });
                                        }
                                    }
                                }
                            },
                            {
                                widget: "dxButton",
                                options: {
                                    text: "UnApprove",
                                    type: "contained",
                                    disabled: true,
                                    elementAttr: { id: "UnApproveBtn" },
                                    onClick: function (e) {
                                        var data = $("#reg-form").dxDataGrid("instance").option("selectedRowKeys")
                                        if (data && data.length > 0) {
                                            ajaxRequest('/Exam/Registration/UnApproveByAdmin', 'POST', { data: { id: data } }, function (response) {
                                                if (response.IsSuccess) {
                                                    showMessage(context.Title, 'UnApproved sucessfully', 'success');
                                                } else {
                                                    showMessage(context.Title, response.Message, 'error');
                                                }
                                            });
                                        }
                                    }
                                }
                            }]
                        },
                        columns: [
                            {
                                dataField: "ExamRegistrationID",
                                caption: "Token No"
                            }, {
                                dataField: "RegistrationNo",
                                caption: "Reg No"
                            },
                            {
                                dataField: "FullName",
                                caption: "Name",
                            },
                            {
                                dataField: "ShortName",
                                caption: "Program"
                            },
                            {
                                dataField: "ExamRollNo",
                                caption: "Roll No"
                            },
                            { dataField: "Year" },
                            { dataField: "Part" },
                            {
                                dataField: "SubjectRegisteredCount",
                                caption: "Subject(s)"
                            },
                            {
                                allowExporting: false,
                                cellTemplate: function (c, o) {
                                    $("<a />")
                                        .attr("href", "javascript:void(0)")
                                        .addClass("btn btn-xs btn-warning m-l-sm")
                                        .html(`<i class="fa fa-eye"></i> &nbsp; View Detail`)
                                        .on("click", function (e) {
                                            emis.examRegistration.ViewDetail(o.data.ExamRegistrationID);
                                        }).appendTo(c);
                                }
                            }
                        ],

                        onRowPrepared: function (e) {
                            if (e.rowType == "data") {
                                if (e.data.AdminVerifiedBy) {
                                    e.rowElement.addClass("bg-primary");
                                }
                            }
                        },
                        onSelectionChanged: function (e) {
                            var data = e.selectedRowsData;
                            var approved = (data.filter(x => x.AdminVerifiedBy) || []);
                            var pending = (data.filter(x => !x.AdminVerifiedBy) || []);
                            if (data.length > 0) {
                                if (pending.length > 0) {
                                    $("#ApproveBtn").dxButton("instance").option("text", "Approve (" + pending.length + ")");
                                    $("#ApproveBtn").dxButton("instance").option("disabled", false);
                                }
                                else {
                                    $("#ApproveBtn").dxButton("instance").option("text", "Approve");
                                    $("#ApproveBtn").dxButton("instance").option("disabled", true);
                                }

                                if (approved.length > 0) {
                                    $("#UnApproveBtn").dxButton("instance").option("text", "UnApprove (" + approved.length + ")");
                                    $("#UnApproveBtn").dxButton("instance").option("disabled", false);
                                }
                                else {
                                    $("#UnApproveBtn").dxButton("instance").option("text", "UnApprove");
                                    $("#UnApproveBtn").dxButton("instance").option("disabled", true);
                                }
                            }
                            else {
                                $("#ApproveBtn").dxButton("instance").option("text", "Approve");
                                $("#ApproveBtn").dxButton("instance").option("disabled", true);
                                $("#UnApproveBtn").dxButton("instance").option("text", "UnApprove");
                                $("#UnApproveBtn").dxButton("instance").option("disabled", true);
                            }
                        },
                        searchPanel: { visible: true },
                        pager: {
                            allowedPageSizes: "auto",
                            displayMode: "adaptive",
                            infoText: "Page {0} of {1} ({2} items)",
                            showInfo: true,
                            showNavigationButtons: true,
                            showPageSizeSelector: true,
                            allowedPageSizes: [50, 100, 200, 500, 'all'],
                            visible: "auto"
                        },
                        paging: {
                            enabled: true,
                            pageIndex: 0,
                            pageSize: 10
                        },
                        export: {
                            enabled: true,
                            fileName: "Registration List"
                        }
                    })

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.VerifyByTokenMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.TotalRecordCount = ko.observable(0);
                if (options.data.Colleges.length == 1) {
                    vm.CollegeId(options.data.Colleges[0].Id);
                }

                vm.SearchForVerifyByToken = function () {
                    context.SearchForVerifyByToken();
                }

                vm.ApproveByToken = function () {
                    context.ApproveByToken();
                }


                return vm;
            }
        };

        context.InitializeVerifyByToken = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.ExamRegistrationIndexVM.SearchModel = ko.mapping.fromJS(model, context.VerifyByTokenMapping);
                context.ViewModel.ExamRegistrationIndexVM.FeeEnclosed = ko.observable(0);

                ko.applyBindings(context.ViewModel.ExamRegistrationIndexVM, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationIndexVM.SearchModelSearchModel);
            }

        }

        context.SearchForVerifyByToken = function () {
            var vm = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.SearchModel);
            ajaxRequest('/Exam/Registration/VerifyByToken', 'POST', {
                data: { model: vm }
            }, function (response) {
                if (response.IsSuccess) {
                    //
                    context.ViewDetail(response.Data.Id, function () {
                        context.ViewModel.ExamRegistrationIndexVM.FeeEnclosed(response.Data.FeeEnclosed);
                        if (!ko.dataFor($('#verifyContent')[0])) {
                            ko.applyBindings(context.ViewModel.ExamRegistrationIndexVM, $('#verifyContent')[0]);
                        }
                    });
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
            })
        };

        context.SearchRecords = function () {
            if ($('#listRegistrationForm').valid()) {


                var searchModel = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.SearchModel);
                searchModel.IsForAdminList = $("#IsForAdminList").val();
                ajaxRequest('/Exam/Registration/Index', 'POST', { data: { model: searchModel } }, function (response) {
                    if (response.IsSuccess) {
                        $("#reg-form").dxDataGrid("instance").option("dataSource", response.Data);
                        context.ViewModel.ExamRegistrationIndexVM.SearchModel.TotalRecordCount(response.Data.length);
                        //if (!ko.dataFor($('#recordContent')[0])) {
                        //    context.ViewModel.ExamRegistrationIndexVM.Records = ko.mapping.fromJS(response.Data);

                        //    ko.applyBindings(context.ViewModel.ExamRegistrationIndexVM, $('#recordContent')[0]);
                        //} else {
                        //    ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationIndexVM.Records);
                        //}
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        }

        context.InitialzeUnSubmittedStudentsExport = function () {
            if ($('#listRegistrationForm').valid()) {
                var searchModel = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.SearchModel);
                ajaxRequest('/Exam/Registration/InitializeExportUnSubmittedRegularStudentList', 'POST', { data: { model: searchModel } }, function (response) {
                    if (response.IsSuccess) {
                        window.open('/Exam/Registration/ExportUnSubmittedRegularStudentList');
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        }



        context.ApproveByToken = function () {
            var id = context.ViewModel.ExamRegistrationIndexVM.DetailVM.ExamRegistrationId();
            var amount = context.ViewModel.ExamRegistrationIndexVM.FeeEnclosed();
            swal({
                title: "Approve Student",
                text: "Are you sure you want to approve this student?",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                confirmButtonText: "Yes, Approve Student Application",
                cancelButtonText: "Cancel",
                closeOnConfirm: true,
                closeOnCancel: false
            },
                function (isConfirm) {
                    if (isConfirm) {

                        ajaxRequest('/Exam/Registration/ApproveAndUpdateFee', 'POST', { data: { id: id, feeEnclosed: amount } }, function (response) {
                            if (response.IsSuccess) {
                                showMessage(context.Title, response.Message, 'success', null, 'swal')
                                //context.ViewModel.ExamRegistrationIndexVM.SearchClick();
                                context.ViewModel.ExamRegistrationIndexVM.SearchModel.SearchForVerifyByToken();
                                //
                            } else {
                                showMessage(context.Title, response.Message, 'error', null, 'swal')
                                //
                            }
                        })
                    } else {
                        swal("Cancelled", "Approve Student has ben cancelled.", "error");
                    }
                });
        }

        context.UnApprove = function () {
            var id = context.ViewModel.ExamRegistrationIndexVM.DetailVM.ExamRegistrationId();
            swal({
                title: "UnApprove Student",
                text: "Are you sure you want to unapprove this student? Enclosed fee will be reset to 0.",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                confirmButtonText: "Yes, UnApprove Student Application",
                cancelButtonText: "Cancel",
                closeOnConfirm: true,
                closeOnCancel: false
            },
                function (isConfirm) {
                    if (isConfirm) {

                        ajaxRequest('/Exam/Registration/UnapproveAndResetFee', 'POST', { data: { id: id } }, function (response) {
                            if (response.IsSuccess) {
                                showMessage(context.Title, response.Message, 'success', null, 'swal')
                                context.ViewModel.ExamRegistrationIndexVM.SearchModel.SearchForVerifyByToken();
                            } else {
                                showMessage(context.Title, response.Message, 'error', null, 'swal')
                            }
                        })
                    } else {
                        swal("Cancelled", "Student could not be unapproved", "error");
                    }
                });
        }


        context.ListSearchValidation = function () {
            $('#listRegistrationForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    }, CollegeId: {
                        required: true
                    }, ProgramId: {
                        required: true
                    },
                },
                messages: {
                    AcademicYearId: {
                        required: 'Academic Year must be selected.'
                    }, CollegeId: {
                        required: 'College Must be selected'
                    }, ProgramId: {
                        required: 'Program must be selected'
                    },
                }
            });
        }

        context.Export = function (isExport) {
            if (!$('#listRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Exam/Registration/InitializeExport', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        if (isExport) {
                            window.open('/Exam/Registration/Export')
                        } else {
                            window.open('/Exam/Registration/PrintSubjectTriplicate')
                        }
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.ExportSeparate = function (isExport) {
            if (!$('#listRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Exam/Registration/InitializeSeparateExport', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        window.open('/Exam/Registration/ExportSeparate')
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.InitializePaymentExport = function () {
            if (!$('#listRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Exam/Registration/InitializePaymentExport', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        window.open('/Exam/Registration/exportpaymenttriplicate')
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.ExportSubjectSummary = function () {
            if (!$('#listRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Exam/Registration/InitializeExportSubjectSummary', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        window.open('/Exam/Registration/ExportSubjectSummary')
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.ExportSubjectSummaryPivot = function () {
            if (!$('#listRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;



            ajaxRequest('/Exam/Registration/InitializeExportSubjectSummaryPivot', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        let columns = [];
                        let summary = [];
                        if (response.Data.Data.length > 0) {
                            keys = Object.keys(response.Data.Data[0]);
                            keys.forEach(x => {
                                let obj = {
                                    dataField: x
                                }
                                if (x == 'CollegeName') {
                                    obj.width = "auto";
                                }
                                else {
                                    obj.minWidth = 150;
                                }
                                columns.push(obj);
                            });

                            // for summary

                            columns.forEach(x => {
                                if (x.dataField == "CollegeName") {
                                    summary.push({
                                        column: "CollegeName",
                                        summaryType: "count",
                                        displayFormat: "Total Items: {0}"

                                    });
                                }
                                else {
                                    summary.push({
                                        column: x.dataField,
                                        summaryType: "sum",
                                        displayFormat: "{0}"
                                    })
                                }

                            });
                        }
                        $("#datatable").show();
                        $("#recordContent").hide();
                        $("#datatable").dxDataGrid({
                            dataSource: response.Data.Data,
                            columns: columns,
                            showRowLines: true,
                            showColumnLines: true,
                            searchPanel: { visible: true },
                            allowColumnResizing: true,
                            columnAutoWidth: false,
                            onExporting: function (e) {
                                let _export = e.component.option('export');
                                let headerData = [];
                                let startRow = 2;

                                if (global.clientParentName) {
                                    startRow += 1;
                                    headerData.push(global.clientParentName)
                                }

                                if (global.clientName) {
                                    startRow += 1;
                                    headerData.push(global.clientName)
                                }
                                headerData.push("Exam Schedule: " + response.Data.ParentExam + "(" + response.Data.AcademicYear + ")");
                                headerData.push(response.Data.CollegeName);
                                headerData.push(response.Data.Program + " (" + response.Data.Level + " " + response.Data.Yearpart + ")");
                                headerData.push("Exam Type: " + response.Data.Examtype);
                                headerData.push(_export.fileName);
                                startRow += 4;
                                var cols = e.component.getVisibleColumns();
                                var workbook = new ExcelJS.Workbook();
                                workbook.creator = 'REMIS';
                                workbook.title = _export.fileName;

                                var worksheet = workbook.addWorksheet('Sheet1', {
                                    pageSetup: { paperSize: 9 }
                                });

                                DevExpress.excelExporter.exportDataGrid({
                                    component: e.component,
                                    worksheet: worksheet,
                                    topLeftCell: { row: startRow, column: 1 }
                                }).then(function (dataGridRange) {
                                    var generalStyles = {
                                        font: { bold: true },
                                        fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'D3D3D3' }, bgColor: { argb: 'D3D3D3' } },
                                        alignment: { horizontal: 'center' }
                                    };
                                    for (var rowIndex = 1; rowIndex < startRow; rowIndex++) {
                                        worksheet.mergeCells(rowIndex, 1, rowIndex, cols.length + 1);
                                        Object.assign(worksheet.getRow(rowIndex).getCell(1), generalStyles);
                                    }
                                    for (let i = 1; i <= cols.length + 1; i++) {
                                        Object.assign(worksheet.getRow(startRow).getCell(i), { font: { bold: true } });
                                        Object.assign(worksheet.getRow(startRow).getCell(i).border = { bottom: { style: 'thin' } });
                                    }
                                    worksheet.getColumn(1).values = headerData;
                                    worksheet.getRow(7).font = { bold: true, size: 14 };
                                    worksheet.views = [
                                        { state: 'unfrozen' }
                                    ];
                                    var currentRowIndex = dataGridRange.to.row + 2;
                                    var generalStyles = {
                                        font: { bold: true, italic: true },
                                        alignment: { horizontal: 'right' }
                                    };
                                    for (var rowIndex = 0; rowIndex < 2; rowIndex++) {
                                        Object.assign(worksheet.getRow(currentRowIndex + rowIndex).getCell(1), generalStyles);
                                        Object.assign(worksheet.getRow(currentRowIndex + rowIndex).getCell(3), generalStyles);
                                    }

                                    worksheet.getRow(currentRowIndex).getCell(3).value = "Printed on:";
                                    worksheet.getRow(currentRowIndex).getCell(4).value = moment().format("YYYY-MM-DD") + ' ' + moment().format('h:mm ss A');
                                    workbook.xlsx.writeBuffer().then(function (buffer) {
                                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), _export.fileName + '.xlsx');
                                    });
                                });
                                e.cancel = true;
                            },
                            export: {
                                enabled: true,
                                fileName: "Subject Summary"
                            },
                            summary: {
                                totalItems: summary
                            }
                        });
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.ExportProgramSummary = function () {
            if (!$('#listRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Exam/Registration/InitializeExportProgramSummary', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        window.open('/Exam/Registration/ExportProgramSummary')
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }
        context.ExportSubjectTriplicate = function () {
            if (!$('#listRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Exam/Registration/InitializeExportSubjectTriplicate', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        window.open('/Exam/Registration/ExportSubjectTriplicate')
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }
        context.ExportSubjectTriplicateWithCode = function () {
            if (!$('#listRegistrationForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
            delete model.Records;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.EditClick;
            delete model.SearchClick;

            ajaxRequest('/Exam/Registration/InitializeExportSubjectTriplicateWithCode', 'POST',
                { data: { model: model } }, function (response) {
                    if (response.IsSuccess) {
                        window.open('/Exam/Registration/ExportSubjectTriplicateWithCode')
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.DetailMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.ViewDetailRenderComplete = function (elements, data) {
                    //context.LoadSavedImagesForVerify(data.UserAttachmentId());
                }

                vm.PhotoContentTemplateRenderComplete = function (elements, data) {
                    //context.LoadSavedImagesForVerify(data.UserAttachmentId());
                }

                vm.documentTemplateRenderComplete = function (elements, data) {
                    context.LoadDocument(elements, data);
                }

                vm.Approve = function () {
                    context.Approve();
                }

                vm.Notify = function () {
                    context.Notify();
                }
                vm.MessageContent = ko.observable('')

                vm.ConfirmNotify = function () {
                    context.ConfirmNotify();
                }

                vm.ApproveByToken = function () {
                    context.ApproveByToken();
                }

                vm.UnApprove = function () {
                    context.UnApprove();
                }

                vm.UpdateFeeEnclosed = function () {
                    context.UpdateFeeEnclosed();
                }

                vm.ViewDetailNext = function () {
                    context.ViewDetailNext();
                }

                vm.ViewDetailPrevious = function () {
                    context.ViewDetailPrevious();

                }
                return vm;
            }
        };


        context.ViewDetailNext = function () {
            var vm = context.ViewModel.ExamRegistrationIndexVM;
            if (vm.Records && vm.Records() && vm.Records().length > 0) {
                var index = vm.SearchModel.CurrentRecordIndex();
                if (index < vm.Records().length - 1) {
                    var newIndex = index + 1;
                    vm.SearchModel.CurrentRecordIndex(newIndex);
                    var data = ko.toJS(vm.Records()[newIndex]);
                    var id = data.ExamRegistrationID;
                    context.ViewDetail(id);
                } else {
                    showMessage(context.Title, 'You are already at last student', 'info');
                }
            }
            else {
                showMessage(context.Title, 'You are already at last student', 'info');
            }
        };

        context.ViewDetailPrevious = function () {
            var vm = context.ViewModel.ExamRegistrationIndexVM;
            if (vm.Records && vm.Records() && vm.Records().length > 0) {
                var index = vm.SearchModel.CurrentRecordIndex();
                if (index > 0) {
                    var newIndex = index - 1;
                    vm.SearchModel.CurrentRecordIndex(newIndex);
                    var data = ko.toJS(vm.Records()[newIndex]);
                    var id = data.ExamRegistrationID;
                    context.ViewDetail(id);
                }
                else {
                    showMessage(context.Title, 'You are already at first student', 'info');
                }
            }
            else {
                showMessage(context.Title, 'You are already at first student', 'info');
            }
        };


        context.LoadDocument = function (elements, data) {
            if (data.DisplayPreview()) {
                if (data.UserAttachmentId() > 0) {
                    ajaxRequest('/Student/Registration/GetDocumentBase64Content', 'POST', { data: { id: data.UserAttachmentId() } }, function (response) {
                        if (response.IsSuccess) {
                            data.UserAttachmentBase64Data(response.Data.Base64Data)
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
                var currentRecord = context.ViewModel.ExamRegistrationIndexVM.DetailVM
                currentRecord.PhotoAttachmentViewModel.Base64Data('')
                return false;
            }
            ajaxRequest('/Student/Registration/GetDocumentBase64Content', 'POST', { data: { id: id } }, function (response) {
                if (response.IsSuccess) {
                    var currentRecord = context.ViewModel.ExamRegistrationIndexVM.DetailVM

                    ko.mapping.fromJS(response.Data, {}, currentRecord.PhotoAttachmentViewModel);
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.Approve = function () {
            var id = context.ViewModel.ExamRegistrationIndexVM.DetailVM.ExamRegistrationId();
            swal({
                title: "Approve Student",
                text: "Are you sure you want to approve this student? You will not be reject once you approve. ",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                confirmButtonText: "Yes, Approve Student Application",
                cancelButtonText: "Cancel",
                closeOnConfirm: true,
                closeOnCancel: false
            },
                function (isConfirm) {
                    if (isConfirm) {

                        ajaxRequest('/Exam/Registration/Approve', 'POST', { data: { id: id } }, function (response) {
                            if (response.IsSuccess) {
                                showMessage(context.Title, response.Message, 'success', null, 'swal')
                                context.ViewModel.ExamRegistrationIndexVM.SearchClick();
                                //
                            } else {
                                showMessage(context.Title, response.Message, 'error', null, 'swal')
                                //
                            }
                        })
                    } else {
                        swal("Cancelled", "Approve Student has ben cancelled.", "error");
                    }
                });

        }

        context.UpdateFeeEnclosed = function () {
            var id = context.ViewModel.ExamRegistrationIndexVM.DetailVM.ExamRegistrationId();
            swal({
                title: 'Enter Fee enclosed amount',
                type: 'input',
                inputAttributes: {
                    autocapitalize: 'off'
                },
                showCancelButton: true,
                confirmButtonText: 'Save',
                showLoaderOnConfirm: true,
                allowOutsideClick: () => !Swal.isLoading()
            }, function (inputValue) {
                if (inputValue === null) return false;

                if (inputValue === "") {
                    swal.showInputError("Fee enclosed amount is required.");
                    return false
                }
                ajaxRequest('/Exam/Registration/UpdateFeeAmount', 'POST', { data: { id: id, feeEnclosed: inputValue } }, function (response) {
                    if (response.IsSuccess) {
                        showMessage(context.Title, response.Message, 'success', null, 'swal')
                        //
                    } else {
                        showMessage(context.Title, response.Message, 'error', null, 'swal')
                        //
                    }
                })
            });

        }

        context.ViewDetail = function (id, callback) {
            ajaxRequest('/Exam/Registration/Detail', 'POST',
                { data: { id: id } }, function (response) {
                    if (response.IsSuccess) {
                        if (!ko.dataFor($('#detailContent')[0])) {
                            context.ViewModel.ExamRegistrationIndexVM.DetailVM = ko.mapping.fromJS(response.Data, context.DetailMapping);

                            ko.applyBindings(context.ViewModel.ExamRegistrationIndexVM, $('#detailContent')[0]);
                        } else {
                            ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationIndexVM.DetailVM);
                        }
                        context.LoadSavedImagesForVerify(response.Data.UserAttachmentId);
                        if (callback) {
                            callback();
                        }
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        //List Page Related
        context.ListMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CollegeId.subscribe(function (newValue) {
                    //context.LoadProgramForList(newValue, vm.LevelId());
                });

                vm.LevelId.subscribe(function (newValue) {
                    //context.LoadProgramForList(vm.CollegeId(), newValue);
                });

                vm.ProgramId.subscribe(function (newValue) {
                    context.LoadYearPartForList(newValue);
                })

                return vm;
            }
        };


        context.LoadYearPartForList = function (newProgramId) {
            if (newProgramId) {
                ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                    var yearParts = [];
                    if (response.IsSuccess) {
                        yearParts = response.Data;
                    } else {
                        yearParts = [];
                    }
                    ko.mapping.fromJS(yearParts, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.YearParts);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.YearParts);

            }
        }

        context.LoadProgramForList = function (newCollegeId, newLevelId) {
            if (newCollegeId && newLevelId && newCollegeId > 0 && newLevelId > 0) {
                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: newLevelId } }, function (response) {
                    var programs = [];
                    if (response.IsSuccess) {
                        programs = response.Data;
                    } else {
                        programs = [];
                    }
                    ko.mapping.fromJS(programs, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.Programs);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.Programs);

            }
        };
        context.LoadCollegeForList = function (newDistrictId) {
            ajaxRequest('/Lookup/GetCollegeByDistrict', 'POST', { data: { districtId: newDistrictId } }, function (response) {
                var colleges = [];
                if (response.IsSuccess) {
                    colleges = response.Data;
                } else {
                    colleges = [];
                }
                ko.mapping.fromJS(colleges, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.Colleges);
            });
        };
        context.InitializeList = function () {
            ajaxRequest('/Exam/Registration/InitializeList', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.ExamRegistrationIndexVM.ListSearchModel = ko.mapping.fromJS(response.Data, context.ListMapping);

                        ko.applyBindings(context.ViewModel.ExamRegistrationIndexVM, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
                    }
                    context.ListSearchValidation();
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.SearchRecordsForList = function () {
            $("#datatable").hide();
            $("#recordContent").show();
            if ($('#listRegistrationForm').valid()) {


                var searchModel = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
                delete searchModel.AcademicYears;
                delete searchModel.Colleges;
                delete searchModel.Programs;

                ajaxRequest('/Exam/Registration/List', 'POST', { data: { model: searchModel } }, function (response) {
                    if (response.IsSuccess) {

                        //ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
                        context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.TotalRecords(response.Data.TotalRecords);
                        context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.Pages(response.Data.Pages)
                        if (!ko.dataFor($('#recordContent')[0])) {
                            context.ViewModel.ExamRegistrationIndexVM.Records = ko.mapping.fromJS(response.Data.Records);

                            ko.applyBindings(context.ViewModel.ExamRegistrationIndexVM, $('#recordContent')[0]);
                        } else {
                            ko.mapping.fromJS(response.Data.Records, {}, context.ViewModel.ExamRegistrationIndexVM.Records);
                            //ko.mapping.fromJS(response.Data.AllowPaging, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.AllowPaging);
                            //ko.mapping.fromJS(response.Data.PageSize, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.PageSize);
                            //ko.mapping.fromJS(response.Data.PageIndex, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.PageIndex);
                            //ko.mapping.fromJS(response.Data.TotalPage, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.TotalPage);
                            //ko.mapping.fromJS(response.Data.CurrentPageStartIndex, {}, context.ViewModel.ExamRegistrationIndexVM.ListSearchModel.CurrentPageStartIndex);
                        }
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        }

        context.ListSearchValidation = function () {
            $('#listRegistrationForm').validate({
                rules: {
                    ParentExamScheduleId: {
                        required: true,
                        min: 0
                    },
                    AcademicYearId: {
                        required: true,
                        min: 0
                    }
                },
                messages: {
                    AcademicYearId: {
                        required: 'Academic Year must be selected.'
                    }
                }
            });
        }

        context.ResetExamRollNo = function () {
            if ($('#listRegistrationForm').valid()) {


                var searchModel = ko.mapping.toJS(context.ViewModel.ExamRegistrationIndexVM.ListSearchModel);
                if (!(searchModel.ExamRollNoFrom && parseInt(searchModel.ExamRollNoFrom) > 0 && searchModel.ExamRollNoTo && parseInt(searchModel.ExamRollNoTo) > 0)) {
                    showMessage(context.Title, 'Both Exam Roll No from and Roll No to has to be provided for resetting roll no', 'error');
                    return false;
                }
                if (confirm('Are you sure you want to reset roll no for given roll no range?')) {
                    ajaxRequest('/Exam/Registration/ResetRollNoRange', 'POST', { data: { model: searchModel } }, function (response) {
                        if (response.IsSuccess) {
                            context.SearchRecordsForList();
                            showMessage(context.Title, 'Selected Roll No range reset performed successfully.', 'success');

                        } else {
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                }
            }
        };

        //Edit Related
        context.Edit = function (id) {
            window.location = '/Exam/Registration/Edit/' + id
        }
        context.EditPartial = function (id) {
            window.location = '/Exam/Registration/InitializePartialEdit/' + id
        }
        context.EditPartialNewTab = function (id) {
            window.open('/Exam/Registration/InitializePartialEdit/' + id)
        }


        context.Delete = function (id) {
            if (confirm('Are you sure you want to delete this?')) {
                ajaxRequest('/Exam/Registration/Delete', 'POST', { data: { id: id } }, function (response) {
                    if (response.IsSuccess) {
                        showMessage(context.Title, response.Message, 'success')
                        context.SearchRecords();
                    } else {
                        showMessage(context.Title, response.Message, 'error')

                    }
                })
            }
        }

        context.InitializeEdit = function () {
            ajaxRequest('/Exam/Registration/InitializeEdit', 'POST', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#editTemplate')[0])) {
                        context.ViewModel.ExamRegistrationEditVM.Model = ko.mapping.fromJS(response.Data);

                        ko.applyBindings(context.ViewModel.ExamRegistrationEditVM, $('#editContent')[0]);
                    }
                    else {

                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamRegistrationEditVM.Model);
                    }
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
            })
        }

        context.Update = function () {
            var model = ko.toJS(context.ViewModel.ExamRegistrationEditVM.Model);
            delete model.__ko_mapping__;

            ajaxRequest('/Exam/Registration/Edit', 'POST', {
                data: { model: model },
                //enableLadda: true,
                //targetLaddaElement: '[data-role=save]',
            }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function () {
                        window.location = '/Exam/Registration/Index'
                    });
                }
                else {
                    showMessage(context.Title, response.Message, 'error', function () {
                    });
                }
            });
        }

        //admit card
        context.ViewRegCardMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchClick = function () {
                    context.SearchViewAdmitCard();
                }

                vm.RenderComplete = function () {
                    context.ApplyViewAdmitCardValidation();
                }

                vm.SelectAll = ko.observable(false);

                vm.SelectAll.subscribe(function (newValue) {
                    context.SelectAll(newValue);
                });


                if (options.data.AcademicYears.length == 1) {
                    vm.AcademicYearId(options.data.AcademicYears[0].Id);
                }

                //if (options.data.Colleges.length == 1) {
                //    vm.CollegeId(options.data.Colleges[0].Id);
                //}

                vm.AcademicYearId.subscribe(function (newAcademicYearId) {
                    //GetExamScheduleByAcademicYear
                    if (newAcademicYearId && newAcademicYearId > 0) {
                        ajaxRequest('/Lookup/GetExamScheduleWithParentByAcademicYear', 'POST', { data: { academicYearId: newAcademicYearId } }, function (response) {
                            if (response.IsSuccess) {
                                vm.ExamSchedules(response.Data);
                            } else {
                                vm.ExamSchedules([]);
                                showMessage(context.Title, response.Message, 'error');
                            }
                        });
                    } else {
                        vm.ExamSchedules([]);
                    }
                })

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

                vm.ProgramId.subscribe(function (newValue) {
                    ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newValue } }, function (response) {
                        if (response.IsSuccess) {

                            vm.YearParts(response.Data);
                        } else {
                            vm.YearParts([]);
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                });

                vm.ViewAdmitCardClick = function () {
                    context.ViewAdmitCard();
                }

                vm.PrintClick = function () {
                    context.PrintAdmitCard();
                }

                return vm;
            }
        }

        context.SelectAll = function (newValue) {
            $(context.ViewModel.AdmitCardViewModel.Records()).each(function (index, item) {
                item.IsSelected(newValue);
            });
            //AdmitCardViewModel.Records
        }

        context.ViewAdmitCard = function () {
            var model = ko.mapping.toJS(context.ViewModel.AdmitCardViewModel);
            delete model.PrintRecords;
            delete model.YearParts;

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
            delete model.ViewAdmitCardClick;
            delete model.PrintClick;

            ajaxRequest('/Exam/Registration/AdmitCard', 'POST', { data: { model: model, selectedIds: selectedIds } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#printContent')[0])) {
                        context.ViewModel.AdmitCardViewModel.PrintRecords = ko.mapping.fromJS(response.Data);

                        ko.applyBindings(context.ViewModel.AdmitCardViewModel, $('#printContent')[0]);

                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.AdmitCardViewModel.PrintRecords);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.SearchViewAdmitCard = function () {
            context.ApplyViewAdmitCardValidation();
            if (!$('#cardViewForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.AdmitCardViewModel);

            delete model.__ko_mapping__;
            delete model.AcademicYears;
            delete model.Programs;
            delete model.SearchClick;
            delete model.RenderComplete;
            delete model.Records;
            delete model.ViewAdmitCardClick;
            delete model.PrintClick;

            ajaxRequest('/Exam/Registration/SearchAdmitCard', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.AdmitCardViewModel.Records);

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }
        context.ApplyViewAdmitCardValidation = function () {
            $('#cardViewForm').data('validator', null);
            $('#cardViewForm').unbind('validate');
            $('#cardViewForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    }, CollegeId: {
                        required: true
                    }, ProgramId: {
                        required: true
                    },
                    ExamScheduleId: {
                        required: true
                    },
                    YearPartId: {
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
                    },
                    ExamScheduleId: {
                        required: 'Exam Schedule must be selected'
                    },
                    YearPartId: {
                        required: 'YearPart must be selected'
                    }
                }
            });
        }

        context.InitializeAdmitCard = function () {
            ajaxRequest('/Exam/Registration/InitializeAdmitCard', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.AdmitCardViewModel = ko.mapping.fromJS(response.Data, context.ViewRegCardMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.AdmitCardViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


        context.PrintAdmitCard = function () {
            if (!$('#cardViewForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.AdmitCardViewModel);

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
            delete model.Programs;
            delete model.SearchClick;
            delete model.RenderComplete;
            delete model.Records;
            delete model.ViewAdmitCardClick;
            delete model.PrintClick;
            delete model.PrintRecords;
            delete model.Colleges;

            model.StudentIds = selectedIds;

            ajaxRequest('/Exam/Registration/PrintAdmitCard', 'POST', { data: { model: model, selectedIds: selectedIds } }, function (response) {
                if (response.IsSuccess) {
                    window.open('/Exam/Registration/Download');
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        //is exam registered

        context.IsExamRegisteredMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForRegisteredMapping(newValue);
                });

                vm.DistrictId.subscribe(function (newValue) {
                    context.LoadCollegeForRegisteredMapping(newValue);
                });

                vm.RenderComplete = function () {
                    $('#listRegistrationForm').validate({
                        rules: {
                            AcademicYearId: {
                                required: true
                            },
                            DistrictId: {
                                required: true
                            },
                            CollegeId: {
                                required: true,
                            },
                            ProgramId: {
                                required: true
                            }
                        }
                    });
                }

                vm.IsSelectAll = ko.observable(false);

                vm.IsSelectAll.subscribe(function (newValue) {
                    if (vm.Records && vm.Records() && vm.Records().length > 0) {

                        $(vm.Records()).each(function (index, item) {
                            item.IsExamRegistered(newValue);
                        })
                    }
                    else {
                    }
                })

                vm.SearchClick = function () {
                    context.SearchIsExamRegistered();
                }

                vm.SaveChanges = function () {
                    context.IsExamRegisteredSaveChanges();
                }

                return vm;
            }
        };

        context.IsExamRegisteredSaveChanges = function () {
            var records = context.ViewModel.IsExamRegisteredViewModel.Records().map(function (item, index) {
                return {
                    ExamRegistrationId: item.ExamRegistrationID(),
                    IsExamRegistered: item.IsExamRegistered()
                }
            });

            ajaxRequest('/Exam/Registration/IsExamRegistered', 'POST', { data: { records: records } }, function (response) {
                var programs = [];
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function () {
                    })
                } else {
                    showMessage(context.Title, response.Message, 'error', function () {

                    })

                }
            });
        }

        context.SearchIsExamRegistered = function () {
            if ($('#listRegistrationForm').valid()) {

                var searchModel = ko.mapping.toJS(context.ViewModel.IsExamRegisteredViewModel);

                delete searchModel.Programs;
                delete searchModel.Colleges;
                delete searchModel.Districts;

                ajaxRequest('/Exam/Registration/SearchForIsExamRegistered', 'POST', { data: { model: searchModel } }, function (response) {
                    if (response.IsSuccess) {
                        if (!ko.dataFor($('#recordContent')[0])) {
                            context.ViewModel.IsExamRegisteredViewModel.Records = ko.mapping.fromJS(response.Data);

                            ko.applyBindings(context.ViewModel.IsExamRegisteredViewModel, $('#recordContent')[0]);
                        } else {
                            ko.mapping.fromJS(response.Data, {}, context.ViewModel.IsExamRegisteredViewModel.Records);
                        }
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }

        }


        context.LoadProgramForRegisteredMapping = function (newCollegeId) {
            ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                var programs = [];
                if (response.IsSuccess) {
                    programs = response.Data;
                } else {
                    programs = [];
                }
                ko.mapping.fromJS(programs, {}, context.ViewModel.IsExamRegisteredViewModel.Programs);
            });
        };

        context.LoadCollegeForRegisteredMapping = function (newDistrictId) {
            ajaxRequest('/Lookup/GetCollegeByDistrict', 'POST', { data: { districtId: newDistrictId } }, function (response) {
                var colleges = [];
                if (response.IsSuccess) {
                    colleges = response.Data;
                } else {
                    colleges = [];
                }
                ko.mapping.fromJS(colleges, {}, context.ViewModel.IsExamRegisteredViewModel.Colleges);
            });
        };


        context.InitializeIsExamRegistered = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.IsExamRegisteredViewModel = ko.mapping.fromJS(model, context.IsExamRegisteredMapping);

                ko.applyBindings(context.ViewModel.IsExamRegisteredViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(response.Data, {}, context.ViewModel.IsExamRegisteredViewModel);
            }
        }
    })(emis.examRegistration);
});
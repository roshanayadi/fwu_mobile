
$(function () {
    emis.CreateNamespace('examRegistrationReport');

    (function (context) {

        context.Title = 'Registration Report';
        context.ViewModel = {};

        context.AttendnaceSheetMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.Records = ko.observableArray([]);

                vm.SearchClick = function () {
                    context.Search();
                    //context.SearchViewRegCard();
                }

                vm.RenderComplete = function () {
                    console.log('validate');
                    context.ApplyValidation();
                    //context.ApplyViewRegCardSearchValidation();
                }

                vm.SearchViewModel.AcademicYearId.subscribe(function (newValue) {
                    if (newValue) {
                        context.LoadExamSchedule(newValue);
                    } else {
                        vm.SearchViewModel.ExamSchedules([]);
                    }
                })

                vm.SearchViewModel.ExamScheduleId.subscribe(function (newValue) {
                    if (newValue) {
                        context.LoadExamCenter(newValue);
                    } else {
                        vm.SearchViewModel.ExamCenters([]);
                    }
                })

                vm.SearchViewModel.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForList(newValue);
                });

                vm.SearchViewModel.ProgramId.subscribe(function (newProgramId) {
                    context.LoadYearPartsForList(newProgramId);
                });


                vm.SearchViewModel.YearPartId.subscribe(function () {
                    context.LoadSubjectsForList();
                });

                vm.SearchViewModel.Search = function () {
                    context.SearchAttendanceSheet();
                }

                vm.SearchViewModel.Export = function () {
                    context.ExportAttendanceSheet($(event.target).attr('data-format'));
                }

                vm.ExportExamCenterTriplicate = function (item, event) {
                    context.ExportExamCenterTriplicate($(event.target).attr('data-format'));
                }

                vm.ExportExamCenterSubjectSummary = function (item, event) {
                    context.ExportExamCenterSubjectSummary($(event.target).attr('data-format'), $(event.target).attr('data-programGroupParent'));
                }

                return vm;
            }
        }

        context.ApplyValidation = function () {
            $('#registrationTriplicateForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    },
                    CollegeId: {
                        required: true
                    }
                },
                messages: {
                    AcademicYearId: {
                        required: 'Academic Year must be selected'
                    },
                    CollegeId: {
                        required: 'College must be selected.'
                    }
                }
            });
        }

        context.LoadExamCenter = function (examScheduleId) {
            ajaxRequest('/Lookup/GetExamCenterByExamSchedule', 'GET', { data: { examScheduleId: examScheduleId } }, function (response) {
                if (response.IsSuccess) {
                    context.ViewModel.ExamAttendanceVM.SearchViewModel.ExamCenters(response.Data);
                } else {
                    context.ViewModel.ExamAttendanceVM.SearchViewModel.ExamCenters([]);
                }
            })
        }

        context.LoadExamSchedule = function (academicYearId) {
            ajaxRequest('/Lookup/GetExamScheduleByAcademicYear', 'GET', { data: { academicYearId: academicYearId } }, function (response) {
                if (response.IsSuccess) {
                    context.ViewModel.ExamAttendanceVM.SearchViewModel.ExamSchedules(response.Data);
                } else {
                    context.ViewModel.ExamAttendanceVM.SearchViewModel.ExamSchedules([]);
                }
            })
        }

        context.InitializeAttendanceSheet = function () {
            ajaxRequest('/Report/ExamRegistration/InitializeAttendanceSheet', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.ExamAttendanceVM = ko.mapping.fromJS(response.Data, context.AttendnaceSheetMapping);

                        ko.applyBindings(context.ViewModel.ExamAttendanceVM, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel.ExamAttendanceVM);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.LoadProgramForList = function (newCollegeId) {
            ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                var programs = [];
                if (response.IsSuccess) {
                    programs = response.Data;
                } else {
                    programs = [];
                }
                ko.mapping.fromJS(programs, {}, context.ViewModel.ExamAttendanceVM.SearchViewModel.Programs);
            });
        }

        context.LoadYearPartsForList = function (newProgramId) {
            ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                var yearParts = [];
                if (response.IsSuccess) {
                    yearParts = response.Data;
                } else {
                    yearParts = [];
                }
                ko.mapping.fromJS(yearParts, {}, context.ViewModel.ExamAttendanceVM.SearchViewModel.YearParts);
            });
        }

        context.LoadSubjectsForList = function () {
            var programId = context.ViewModel.ExamAttendanceVM.SearchViewModel.ProgramId();
            var yearPartId = context.ViewModel.ExamAttendanceVM.SearchViewModel.YearPartId();
            ajaxRequest('/Lookup/GetSubjectsByProgramYearPart', 'GET', { data: { programId: programId, yearPartId: yearPartId } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamAttendanceVM.SearchViewModel.Subjects);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


        context.SearchAttendanceSheet = function () {

            if (!$('#attendanceSheetSearchForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamAttendanceVM.SearchViewModel);
            delete model.AcademicYears;
            delete model.ExamCenters;
            delete model.Colleges;
            delete model.Programs;
            delete model.Subjects;
            delete model.Search;
            delete model.Export;
            delete model.ExportExamCenterTriplicate;
            delete model.YearParts;

            ajaxRequest('/Report/ExamRegistration/AttendanceSheet', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.ExamAttendanceVM.Records);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.ExportAttendanceSheet = function (format) {

            if (!$('#attendanceSheetSearchForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamAttendanceVM.SearchViewModel);
            delete model.AcademicYears;
            delete model.ExamCenters;
            delete model.Colleges;
            delete model.Programs;
            delete model.Subjects;
            delete model.Search;
            delete model.Export;
            delete model.ExportExamCenterTriplicate;
            delete model.YearParts;

            ajaxRequest('/Report/ExamRegistration/InitializeAttendanceSheetExport', 'POST', { data: { model: model, format: format } }, function (response) {
                if (response.IsSuccess) {
                    window.location = '/Report/ExamRegistration/ExportAttendanceSheet'
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


        context.ExportExamCenterTriplicate = function (extension) {

            if (!$('#attendanceSheetSearchForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamAttendanceVM.SearchViewModel);
            delete model.AcademicYears;
            delete model.ExamCenters;
            delete model.Colleges;
            delete model.Programs;
            delete model.Subjects;
            delete model.Search;
            delete model.Export;
            delete model.ExportExamCenterTriplicate;
            delete model.YearParts;

            ajaxRequest('/Report/ExamRegistration/InitializeExamCenterTriplicateExport', 'POST', { data: { model: model, extension: extension } }, function (response) {
                if (response.IsSuccess) {
                    window.location = '/Report/ExamRegistration/ExamCenterTriplicate'
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.ExportExamCenterSubjectSummary = function (format, programGroupParent) {

            if (!$('#attendanceSheetSearchForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.ExamAttendanceVM.SearchViewModel);
            delete model.AcademicYears;
            delete model.ExamCenters;
            delete model.Colleges;
            delete model.Programs;
            delete model.Subjects;
            delete model.Search;
            delete model.Export;
            delete model.YearParts;

            model.ProgramGroupByParent = programGroupParent;
            ajaxRequest('/Report/ExamRegistration/ExamCenterSubjectSummary', 'POST', { data: { model: model, format: format } }, function (response) {
                if (response.IsSuccess) {
                    window.location = '/Report/ExamRegistration/ExportExamCenterSubjectSummary'
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }




        //Marks Foil
        context.MarksFoilMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.Records = ko.observableArray([]);

                vm.SearchClick = function () {
                    context.SearchMarksFoil();
                    //context.SearchViewRegCard();
                }

                vm.RenderComplete = function () {
                    //context.ApplyValidation();
                    //context.ApplyViewRegCardSearchValidation();
                }

                vm.SearchViewModel.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForMF(newValue);
                });

                vm.SearchViewModel.ProgramId.subscribe(function (newProgramId) {
                    context.LoadYearPartsForMF(newProgramId);
                });


                vm.SearchViewModel.YearPartId.subscribe(function () {
                    context.LoadSubjectsForMF();
                });

                vm.SearchViewModel.Search = function () {
                    context.SearchMarksFoil();
                }

                vm.SearchViewModel.Print = function () {
                    context.PrintMarksFoil();
                }

                vm.SearchViewModel.PrintByLocalStorage = function () {
                    context.PrintByLocalStorage();
                }

                vm.SearchViewModel.ExportSubjectSummary = function () {
                    context.ExportSubjectSummary();
                }

                return vm;
            }
        }

        context.InitializeMarksFoil = function () {
            ajaxRequest('/Report/ExamRegistration/InitializeMarksFoil', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.MarksFoilVM = ko.mapping.fromJS(response.Data, context.MarksFoilMapping);

                        ko.applyBindings(context.ViewModel.MarksFoilVM, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel.MarksFoilVM);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.LoadProgramForMF = function (newCollegeId) {
            ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                var programs = [];
                if (response.IsSuccess) {
                    programs = response.Data;
                } else {
                    programs = [];
                }
                ko.mapping.fromJS(programs, {}, context.ViewModel.MarksFoilVM.SearchViewModel.Programs);
            });
        }

        context.LoadYearPartsForMF = function (newProgramId) {
            ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                var yearParts = [];
                if (response.IsSuccess) {
                    yearParts = response.Data;
                } else {
                    yearParts = [];
                }
                ko.mapping.fromJS(yearParts, {}, context.ViewModel.MarksFoilVM.SearchViewModel.YearParts);
            });
        }

        context.LoadSubjectsForMF = function () {
            var programId = context.ViewModel.MarksFoilVM.SearchViewModel.ProgramId();
            var yearPartId = context.ViewModel.MarksFoilVM.SearchViewModel.YearPartId();
            ajaxRequest('/Lookup/GetSubjectsByProgramYearPart', 'GET', { data: { programId: programId, yearPartId: yearPartId } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.MarksFoilVM.SearchViewModel.Subjects);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


        context.SearchMarksFoil = function () {

            if (!$('#attendanceSheetSearchForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.MarksFoilVM.SearchViewModel);
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.Programs;
            delete model.Subjects;
            delete model.Search;
            delete model.YearParts;
            delete model.Print;
            delete model.PrintByLocalStorage;
            delete model.ExportSubjectSummary;

            ajaxRequest('/Report/ExamRegistration/MarksFoil', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.MarksFoilVM.Records);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.ExportSubjectSummary = function () {

            if (!$('#attendanceSheetSearchForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.MarksFoilVM.SearchViewModel);
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.Programs;
            delete model.Subjects;
            delete model.Search;
            delete model.YearParts;
            delete model.Print;
            delete model.PrintByLocalStorage;
            delete model.ExportSubjectSummary;

            ajaxRequest('/Report/ExamRegistration/InitializeCollegeSubjectSummary', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    window.open = '/Report/ExamRegistration/DownloadCollegeSubjectSummary';
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.PrintMarksFoil = function () {

            $('[data-role="marksFoilContent"]').tableExport({ type: 'csv', fileName: 'Marks Foil' });

            //if (!$('#attendanceSheetSearchForm').valid()) {
            //    return false;
            //}
            //var model = ko.toJS(context.ViewModel.MarksFoilVM.SearchViewModel);
            //delete model.AcademicYears;
            //delete model.Colleges;
            //delete model.Programs;
            //delete model.Subjects;
            //delete model.Search;
            //delete model.YearParts;

            //ajaxRequest('/Report/ExamRegistration/MarksFoil', 'POST', { data: { model: model } }, function (response) {
            //    if (response.IsSuccess) {
            //        ko.mapping.fromJS(response.Data, {}, context.ViewModel.MarksFoilVM.Records);
            //    } else {
            //        showMessage(context.Title, response.Message, 'error');
            //    }
            //});
        }

        context.PrintByLocalStorage = function () {
            window.open('/Print/ByLocalStorage')
        }

    })(emis.examRegistrationReport);
});
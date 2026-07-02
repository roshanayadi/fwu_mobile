
$(function () {
    emis.CreateNamespace('tabulationTriplicate');

    (function (context) {

        context.Title = 'TabulationTriplicate';
        context.FormId = '#searchForm';



        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.RenderComplete = function () {
                    $(context.FormId).validate({
                        rules: {
                            CollegeId: { required: true },
                            ExamTypeId: { required: true },
                        },
                        message: {
                            CollegeId: { required: 'College must be selected.' },
                            ExamTypeId: { required: 'Exam Type must be selected' },
                        }
                    });
                }

                return vm;
            }
        };

        context.LoadProgramForList = function (newCollegeId, newLevelId) {
            if (newCollegeId && newLevelId && newCollegeId > 0 && newLevelId > 0) {
                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: newLevelId } }, function (response) {
                    var programs = [];
                    if (response.IsSuccess) {
                        programs = response.Data;
                    } else {
                        programs = [];
                    }
                    ko.mapping.fromJS(programs, {}, context.ViewModel.Programs);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.Programs);

            }
        };

        context.LoadYearPartForList = function (newProgramId, examScheduleId) {
            if (newProgramId && examScheduleId) {
                ajaxRequest('/Lookup/GetYearPartByProgramAndExamSchedule', 'POST', { data: { programId: newProgramId, examScheduleId: examScheduleId } }, function (response) {
                    var yearParts = [];
                    if (response.IsSuccess) {
                        yearParts = response.Data;
                    } else {
                        yearParts = [];
                    }
                    ko.mapping.fromJS(yearParts, {}, context.ViewModel.YearParts);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.YearParts);

            }
        }

        context.LoadExamSchedules = function (newAcademicYearID) {
            if (newAcademicYearID) {
                ajaxRequest('/Lookup/GetExamScheduleWithParentByAcademicYear', 'POST', { data: { academicYearId: newAcademicYearID } }, function (response) {
                    var examSchedules = [];
                    if (response.IsSuccess) {
                        examSchedules = response.Data; 
                    } else {
                        examSchedules = [];
                    }
                    ko.mapping.fromJS(examSchedules, {}, context.ViewModel.ExamSchedules);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamSchedules);

            }
        }

        context.printTable = function () {
            $("#sub-table").printThis();
        }

        context.exportTable = function () {
            var elt = document.getElementById('sub-table');
            var wb = XLSX.utils.table_to_book(elt, { sheet: "TabulationTriplicate" });
            return XLSX.writeFile(wb, 'TabulationTriplicate.xlsx');
        }

        context.LoadLevel = function (examScheduleId) {
            if (examScheduleId) {
                ajaxRequest('/Lookup/GetLevelByExamSchedule', 'POST', { data: { examScheduleId: examScheduleId } }, function (response) {
                    var levels = [];
                    if (response.IsSuccess) {
                        levels = response.Data;
                    } else {
                        levels = [];
                    }
                    ko.mapping.fromJS(levels, {}, context.ViewModel.Levels);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamSchedules);

            }
        }

        context.ListMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForList(newValue, vm.LevelId());
                });

                vm.AcademicYearId.subscribe(function (newValue) {
                    context.LoadExamSchedules(newValue);
                })

                vm.ExamScheduleId.subscribe(function (newValue) {
                    context.LoadLevel(newValue);
                    context.LoadYearPartForList(newValue, vm.ExamScheduleId());
                })

                vm.LevelId.subscribe(function (newValue) {
                    context.LoadProgramForList(vm.CollegeId(), newValue);
                });

                vm.ProgramId.subscribe(function (newValue) {
                    context.LoadYearPartForList(newValue, vm.ExamScheduleId());
                })

                return vm;
            }
        };

        context.GetReport = function () {
            context.ApplyValidation();
            if (!$('#subject-triplicate-form').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel);
            delete model.AcademicYears;
            delete model.Areas;
            delete model.Colleges;
            delete model.__ko_mapping__;
            $("#recordContent").empty();
            ajaxRequest('/Report/SubjectTriplicate/GetTabulationTriplicate', 'POST', { data: model }, function (response) {
                $("#recordContent").html(response);
            });
        }
        context.ApplyValidation = function () {

            $('#subject-triplicate-form').data('validator', null);
            $('#subject-triplicate-form').unbind('validate');
            $('#subject-triplicate-form').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    },
                    ExamScheduleId: {
                        required: true
                    },
                    CollegeId: {
                        required: true
                    },
                    LevelId: {
                        required: true
                    },
                    ProgramId: {
                        required: true
                    },

                },
                messages: {
                    AcademicYearId: {
                        required: "Academic year is required."
                    },
                    ExamScheduleId: {
                        required: "ExamSchedule is required."
                    },
                    CollegeId: {
                        required: "College is required."
                    },
                    LevelId: {
                        required: "Level is required."
                    },
                    ProgramId: {
                        required: "Program is required."
                    },
                    YearPartId: {
                        required: "Year part is required."
                    },
                }
            });
        }


        context.InitializeList = function () {
            ajaxRequest('/Report/SubjectTriplicate/InitializeTabulationTriplicate', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.ListMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }

                $(".btn-search").on("click", function (e) {
                    context.GetReport();
                })

                $(document).on("click", ".btn-print-table", function () {
                    context.printTable();
                })

                $(document).on("click", ".btn-export-table", function () {
                    context.exportTable();
                })

            });

        }

        //Index Page Related
        context.Initialize = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.SearchViewModel = ko.mapping.fromJS(model, context.Mapping);

                ko.applyBindings(context.ViewModel.SearchViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, {}, context.ViewModel.SearchViewModel);
            }
        }
    })(emis.tabulationTriplicate);
});
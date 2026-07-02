
$(function () {
    emis.CreateNamespace('examCenterTriplicate');

    (function (context) {

        context.Title = 'Download Exam Triplicate';
        context.FormId = '#searchForm';

       

        context.LoadProgramForList = function (newLevelId) {
            if (newLevelId && newLevelId > 0) {
                ajaxRequest('/Lookup/GetProgramByLevel', 'POST', { data: { levelId: newLevelId } }, function (response) {
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

        context.LoadExamSchedules = function (newAcademicYearID) {
            if (newAcademicYearID) {
                ajaxRequest('/Lookup/GetExamScheduleByAcademicYear', 'POST', { data: { academicYearId: newAcademicYearID } }, function (response) {
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
            $("#recordContent").printThis();
        }

        context.exportTable = function () {
            var elt = document.getElementById('sub-table');
            var wb = XLSX.utils.table_to_book(elt, { sheet: "SubjectTriplicate" });
            return XLSX.writeFile(wb, 'SubjectTriplicate.xlsx');
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

        context.LoadExamCenters = function (examScheduleId) {
            if (examScheduleId) {
                ajaxRequest('/Lookup/GetExamCenterByExamSchedule', 'POST', { data: { examScheduleId: examScheduleId } }, function (response) {
                    var ExamCenters = [];
                    if (response.IsSuccess) {
                        ExamCenters = response.Data;
                    } else {
                        ExamCenters = [];
                    }
                    ko.mapping.fromJS(ExamCenters, {}, context.ViewModel.ExamCenters);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamCenters);

            }
        }

        context.LoadColleges = function (examScheduleId,examCenterId) {
            if (examScheduleId) {
                ajaxRequest('/Lookup/GetCollegesByExamCenter', 'POST', { data: { examScheduleId: examScheduleId, examCenterId: examCenterId } }, function (response) {
                    var colleges = [];
                    if (response.IsSuccess) {
                        colleges = response.Data;
                    } else {
                        colleges = [];
                    }
                    ko.mapping.fromJS(colleges, {}, context.ViewModel.Colleges);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.Colleges);

            }
        }

        context.ListMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForList(vm.LevelId(), newValue);
                });

                vm.AcademicYearId.subscribe(function (newValue) {
                    context.LoadExamSchedules(newValue);
                })

                vm.ExamScheduleId.subscribe(function (newValue) {
                    context.LoadLevel(newValue);
                    context.LoadExamCenters(newValue);
                })

                vm.ExamCenterId.subscribe(function (newValue) {
                    context.LoadColleges(vm.ExamScheduleId(),newValue);
                })

                vm.LevelId.subscribe(function (newValue) {
                    context.LoadProgramForList(newValue);
                });

                return vm;
            }
        };

        context.SearchExamTriplicate = function () {
            context.ApplyValidation();
            if (!$('#exam-triplicate-form').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel);
            delete model.AcademicYears;
            delete model.Areas;
            delete model.Colleges;
            delete model.__ko_mapping__;
            $("#recordContent").empty();
            ajaxRequest('/Exam/Registration/GetExamCenterTriplicate', 'POST', { data: model }, function (response) {
                console.log(response);
                $("#recordContent").html(response);
            });
        }
        context.ApplyValidation = function () {

            $('#exam-triplicate-form').data('validator', null);
            $('#exam-triplicate-form').unbind('validate');
            $('#exam-triplicate-form').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    },
                    ExamScheduleId: {
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
                    
                }
            });
        }


        context.Initialize = function () {
            ajaxRequest('/Exam/Registration/InitializeExamCenterTriplicate', 'GET', {}, function (response) {
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
                    context.SearchExamTriplicate();
                })

                $(document).on("click", ".btn-print-table", function () {
                    context.printTable();
                })

                $(document).on("click", ".btn-export-table", function () {
                    context.exportTable();
                })

            });

        }
    })(emis.examCenterTriplicate);
});
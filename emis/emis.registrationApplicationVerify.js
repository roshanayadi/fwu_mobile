
$(function () {
    emis.CreateNamespace('registrationApplicationVerify');

    (function (context) {

        context.Title = 'Registration Verify';
        context.CreateFormId = '#frm';
        context.CreateSearchFormId = '#searchForm';

        context.ViewModel = {
            RollNoGenerationVM: {

            }
        };

        context.LoadProgram = function (newCollegeId) {
            ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                var programs = [];
                if (response.IsSuccess) {
                    programs = response.Data;
                } else {
                    programs = [];
                }
                ko.mapping.fromJS(programs, {}, context.ViewModel.RollNoGenerationVM.SearchViewModel.Programs);
            });
        }
        context.LoadYearPart = function (newProgramId) {
            ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                var yearParts = [];
                if (response.IsSuccess) {
                    yearParts = response.Data;
                } else {
                    yearParts = [];
                }
                ko.mapping.fromJS(yearParts, {}, context.ViewModel.RollNoGenerationVM.SearchViewModel.YearParts);
            });
        }

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            ExamScheduleId: {required: true},
                            CollegeId: { required: true },
                            ProgramId: { required: true },
                            RegistratioNo: { required: true },
                            RollNo: { required: true }
                        },
                        messages: {
                            ExamScheduleId: { required: 'Exam Schedule must be selected' },
                            CollegeId: { required: 'College must be selected' },
                            ProgramId: { required: 'Program must be selected' },
                            RegistratioNo: { required: 'Registration No must be provided' },
                            RollNo: { required: 'Roll No must be provided' }
                        }
                    })
                }

                vm.Verify = function () {
                    context.Verify();
                }

                return vm;
            }
        };

        context.Initialize = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel = ko.mapping.fromJS(model, context.Mapping);

                ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, {}, context.ViewModel);
            }
        }

        context.Verify = function () {
            if ($('#frm').valid()) {

                var searchModel = ko.mapping.toJS(context.ViewModel);

                ajaxRequest('/Registration/Default/Verify', 'POST', { data: { model: searchModel } }, function (response) {
                    if (response.IsSuccess) {
                        window.location = '/Registration/Default/Detail';
                    } else {
                        showMessage(context.Title, response.Message, 'error', null, 'swal');
                    }
                });
            }
        }


        //Center Change 
        context.InitializeExamCenterChange = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.ECChangeVM = ko.mapping.fromJS(model, context.ECChangeMapping);

                ko.applyBindings(context.ViewModel.ECChangeVM, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, {}, context.ViewModel.ECChangeVM);
            }
        }
        context.ECChangeMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            ProposedExamCenterId: { required: true },
                        },
                        messages: {
                            ProposedExamCenterId: { required: 'Proposed Exam Center must be selected' },
                        }
                    })
                }

                vm.Submit = function () {
                    context.SubmitECChange();
                }

                return vm;
            }
        };

        context.SubmitECChange = function () {
            if (!$('#frm').valid()) {
                return false;
            }
            var vm = ko.mapping.toJS(context.ViewModel.ECChangeVM);
            ajaxRequest('/Registration/Default/ExamCenterChangeRequest', 'POST', { data: { model: vm } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function () {
                        window.location = window.location
                    })
                } else {
                    showMessage(context.Title, response.Message, 'error', function () {
                    }, 'swal')
                }

            })

        }

    })(emis.registrationApplicationVerify);
});
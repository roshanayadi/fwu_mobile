$(function () {
    emis.CreateNamespace('rollNoGeneration');

    (function (context) {

        context.Title = 'Roll No Generation';
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

                vm.SearchViewModel.CollegeId.subscribe(function (newValue) {
                    context.LoadProgram(newValue);
                });

                vm.SearchViewModel.ProgramId.subscribe(function (newProgramId) {
                    context.LoadYearPart(newProgramId);
                });

                vm.Records = ko.observable({
                    NotRegisteredStudentList: ko.observableArray([]),
                    RegisteredStudentList: ko.observableArray([]),
                });

                vm.SearchClick = function () {
                    context.SearchRecords();
                }

                vm.GenerateClick = function () {
                    context.Generate();
                }

                return vm;
            }
        };


        context.Generate = function () {
            var searchModel = ko.toJS(context.ViewModel.RollNoGenerationVM.SearchViewModel);
            ajaxRequest('/Exam/RollNoGeneration/Create', 'POST', { data: { model: searchModel } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }

            });
        }
        //Index Page Related
        context.Initialize = function () {
            ajaxRequest('/Exam/RollNoGeneration/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.RollNoGenerationVM = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel.RollNoGenerationVM, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.RollNoGenerationVM.SearchViewModel);
                    }
                    context.ListSearchValidation();
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.SearchRecords = function () {
            if ($('#listRegistrationForm').valid()) {

                var searchModel = ko.toJS(context.ViewModel.RollNoGenerationVM.SearchViewModel);
                delete searchModel.__ko_mapping__;

                ajaxRequest('/Exam/RollNoGeneration/Search', 'POST', { data: { model: searchModel } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.RollNoGenerationVM.Records);
                        if (!ko.dataFor($('#recordContent')[0])) {
                            //context.ViewModel.RollNoGenerationVM.Records = ko.mapping.fromJS(response.Data);

                            ko.applyBindings(context.ViewModel.RollNoGenerationVM, $('#recordContent')[0]);
                        } else {
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



        //Index Page Related
        context.InitializeSetup = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.RollNoGenerationSetupVM = ko.mapping.fromJS(model, context.SetupMapping);

                ko.applyBindings(context.ViewModel.RollNoGenerationSetupVM, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, {}, context.ViewModel.RollNoGenerationSetupVM);
            }
        };

        context.SetupMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchClick = function () {
                    context.GenerateRollnoSetup();
                }

                vm.SaveSetupClick = function () {
                    context.SaveSetup();
                }

                vm.GenerateRollNoBySetup = function () {
                    context.GenerateRollNoBySetup();
                }
                return vm;
            }
        }

        context.GenerateRollnoSetup = function () {
            if ($('#listRegistrationForm').valid()) {

                var searchModel = ko.mapping.toJS(context.ViewModel.RollNoGenerationSetupVM);

                ajaxRequest('/Exam/RollNoGeneration/GenerateSetup', 'POST', { data: { model: searchModel } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.RollNoGenerationSetupVM.Records);
                        if (!ko.dataFor($('#recordContent')[0])) {
                            //context.ViewModel.RollNoGenerationVM.Records = ko.mapping.fromJS(response.Data);

                            ko.applyBindings(context.ViewModel.RollNoGenerationSetupVM, $('#recordContent')[0]);
                        } else {
                        }
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        }

        context.SaveSetup = function () {
            if ($('#listRegistrationForm').valid()) {

                var searchModel = ko.mapping.toJS(context.ViewModel.RollNoGenerationSetupVM);

                ajaxRequest('/Exam/RollNoGeneration/SaveSetup', 'POST', { data: { model: searchModel } }, function (response) {
                    if (response.IsSuccess) {
                        showMessage(context.Title, response.Message, 'success');
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            }
        }


        context.GenerateRollNoBySetup = function () {

            var searchModel = ko.mapping.toJS(context.ViewModel.RollNoGenerationSetupVM);

            ajaxRequest('/Exam/RollNoGeneration/GenerateFromSetup', 'POST', { data: { model: searchModel } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });

        }

    })(emis.rollNoGeneration);
});
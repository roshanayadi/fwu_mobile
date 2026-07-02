$(function () {
    emis.CreateNamespace('globalSettings');

    (function (context) {

        context.Title = 'Global Settings';
        context.ViewModel = {
            CollegeExceptionVM: {

            }
        };
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SaveClick = function () {
                    context.Save();
                }

                return vm;
            }
        };
        context.Save = function () {
            if (!$('#globalSettingsForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel);
            delete model.SaveClick;
            delete model.__ko_mapping__;

            ajaxRequest('/Admin/GlobalSettings/Create/', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, 'Global Settings saved successfully.', 'success', function () {
                        });
                    }
                });
        }

        context.Initialize = function () {
            ajaxRequest('/Admin/GlobalSettings/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        //college exception
        context.CollegeExceptionMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentCollegeException = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

                vm.AddNewClick = function () {
                    ko.mapping.fromJS(ko.toJS(vm.AddNewModel), {}, vm.CurrentCollegeException);
                    context.ApplyCollegeExceptionValidation();
                    $('#collegeExceptionAddModal').modal('show');
                }

                vm.EditClick = function (item) {
                    ko.mapping.fromJS(ko.toJS(item), {}, vm.CurrentCollegeException);
                    context.ApplyCollegeExceptionValidation();
                    $('#collegeExceptionAddModal').modal('show');
                }

                vm.SaveClick = function () {
                    context.SaveCollegeException();
                }

                vm.SearchClick = function () {
                    context.SearchCollegeException();
                }
                return vm;
            }
        }

        context.ApplyCollegeExceptionValidation = function () {
            $('#collegeExceptionAddForm').validate({
                rules: {
                    CollegeId: { required: true },
                    ExceptionItem: { required: true },
                    StartDate: { required: true },
                    EndDate: { required: true },
                }
            });
        }

        context.SaveCollegeException = function () {
            if (!$('#collegeExceptionAddForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CollegeExceptionVM.CurrentCollegeException);
            delete model.__ko_mapping__;
            delete model.Colleges;
            delete model.ExceptionItems;
            ajaxRequest('/Admin/GlobalSettings/SaveCollegeException', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    context.InitializeCollegeException();
                    showMessage(context.Title, response.Message, 'success', function() {
                        $('#collegeExceptionAddModal').modal('hide');

                    });
                } else {
                    showMessage(context.Title, response.Message, 'error', function () {
                    });
                }
            });
        }

        context.InitializeCollegeException = function () {
            ajaxRequest('/Admin/GlobalSettings/InitializeCollegeException', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.CollegeExceptionVM = ko.mapping.fromJS(response.Data, context.CollegeExceptionMapping);

                        ko.applyBindings(context.ViewModel.CollegeExceptionVM, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.CollegeExceptionVM);
                    }
                }
            });
        }


    })(emis.globalSettings);
});
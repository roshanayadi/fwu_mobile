$(function () {
    emis.CreateNamespace('studentRegistrationSource');

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

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            CollegeId: {
                                required: true
                            },
                            AcademicYearId: {
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

        context.Initialize = function (model) {
            context.ViewModel.SearchModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
        }

        context.Search = function () {
            if (!$('#frm').valid()) {
                return
            }
            var vm = ko.mapping.toJS(context.ViewModel).SearchModel;
            ajaxRequest('/Student/RegistrationSource/', 'POST', { data: { model: vm } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#resultContent')[0])) {
                        context.ViewModel.Records = ko.mapping.fromJS(response.Data);
                        ko.applyBindings(context.ViewModel, $('#resultContent')[0]);

                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.Records);
                    }
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.Export = function () {
            if (!$('#frm').valid()) {
                return
            }
            var vm = ko.mapping.toJS(context.ViewModel).SearchModel;
            ajaxRequest('/Student/RegistrationSource/InitializeExport', 'POST', { data: { model: vm } }, function (response) {
                if (response.IsSuccess) {
                    window.open('/Student/RegistrationSource/Export')
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        //create
        context.CreateMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);



                vm.SaveClick = function () {
                    context.Save();
                }


                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            CollegeId: {
                                required: true
                            },
                            AcademicYearId: {
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

        context.InitializeCreate = function (model) {
            context.ViewModel.CreateViewModel = ko.mapping.fromJS(model, context.CreateMapping);
            ko.applyBindings(context.ViewModel.CreateViewModel, $('#mainContent')[0]);
        }


        context.Save = function () {
            if (!$('#frm').valid()) {
                return
            }
            var vm = ko.mapping.toJS(context.ViewModel.CreateViewModel);
            ajaxRequest('/Student/RegistrationSource/Create', 'POST', { data: { model: vm } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function () {
                        window.location = '/Student/RegistrationSource/index'
                    })
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

    })(emis.studentRegistrationSource);
});
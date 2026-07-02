$(function () {
    emis.CreateNamespace('collegeProgram');

    (function (context) {

        context.Title = 'College Program';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            Code: {
                                required: function () { return !(vm.SearchModel.Code().length > 0) && !(vm.SearchModel.Name().length > 0) }
                            }
                        }
                    });
                }

                vm.Search = function () {
                    if (!$('#frm').valid()) {
                        return false;
                    }



                    ajaxRequest('/College/CollegeProgram/Index', 'POST', {
                        data: { Code: vm.SearchModel.Code, Name: vm.SearchModel.Name }
                    }, function (response) {
                        if (response.IsSuccess) {

                            if (!ko.dataFor($('#mainContent')[0])) {
                                context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                                ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                            } else {
                                ko.mapping.fromJS(response.Data, {}, context.ViewModel.Records);
                            }

                        } else {
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });

                }

                return vm;
            }
        };

        context.CreateMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SaveCollegeProgramMapping = function () {
                    context.Save();
                }

                return vm;
            }
        };

        context.Save = function () {
            var vm = ko.toJS(context.ViewModel.UpdateVM);

            delete vm.SaveCollegeProgramMapping;
            delete vm.__ko_mapping__;

            ajaxRequest('/College/CollegeProgram/Create', 'POST', { data: { model: vm } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, 'College Program information mapped successfully.', 'success', function () {
                        window.location = '/College/CollegeProgram/Index'
                    })
                }
                else {
                    showMessage(context.Title, response.Message, 'error', function () {
                    })
                }
            })

        }



        context.Initialize = function () {
            ajaxRequest('/College/CollegeProgram/Initialize', 'GET', {}, function (response) {
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

        context.InitializeCreate = function () {
            ajaxRequest('/College/CollegeProgram/InitializeCreate', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.UpdateVM = ko.mapping.fromJS(response.Data, context.CreateMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel.UpdateVM);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


    })(emis.collegeProgram);
});
$(function () {
    emis.CreateNamespace('menu');

    (function (context) {

        context.Title = 'Menu';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentMenuVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

                vm.AddNewClick = function () {
                    context.AddNew();
                }

                vm.SaveClick = function () {
                    context.Save();
                }

                vm.EditClick = function(item) {
                    context.Edit(item);
                }

                return vm;
            }
        };

        context.Edit = function (item) {
            ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentMenuVM);
            context.ApplyValidation();
            $('#menuModal').modal('show');
        }

        context.AddNew = function () {

            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentMenuVM);
            context.ApplyValidation();
            $('#menuModal').modal('show');
        }

        context.Save = function () {
            if (!$('#menuForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentMenuVM);

            ajaxRequest('/Menu/Create/', 'POST', { data: { model: model } }, function(response) {
                if (response.IsSuccess) {

                    context.Initialize();
                    showMessage(context.Title, 'Menu saved successfully.', 'success', function() {
                        $('#menuModal').modal('hide');
                    });
                }
            });
        }

        context.ApplyValidation = function () {
            $('#menuForm').validate({
                rules: {
                    MenuName: {
                        required: true
                    }
                },
                messages: {
                    MenuName: {
                        required: 'Menu name is required.'
                    }
                }
            });
        }

        context.Initialize = function () {
            ajaxRequest('/Menu/Initialize', 'GET', {}, function (response) {
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


    })(emis.menu);
});
$(function () {
    emis.CreateNamespace('role');

    (function (context) {

        context.Title = 'Role';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentRoleVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

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
            ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentRoleVM);
            context.ApplyValidation();
            $('#roleModal').modal('show');
        }

        context.AddNew = function () {

            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentRoleVM);
            context.ApplyValidation();
            $('#roleModal').modal('show');
        }

        context.Save = function () {
            if (!$('#roleForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentRoleVM);

            ajaxRequest('/Role/Create/', 'POST', { data: { model: model } }, function(response) {
                if (response.IsSuccess) {

                    context.Initialize();
                    showMessage(context.Title, 'Role saved successfully.', 'success', function() {
                        $('#roleModal').modal('hide');
                    });
                }
            });
        }

        context.ApplyValidation = function () {
            $('#roleForm').validate({
                rules: {
                    RoleName: {
                        required: true
                    }
                },
                messages: {
                    RoleName: {
                        required: 'Role name is required.'
                    }
                }
            });
        }

        context.Initialize = function () {
            ajaxRequest('/Role/Initialize', 'GET', {}, function (response) {
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


    })(emis.role);
});
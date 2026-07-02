$(function () {
    emis.CreateNamespace('entity');

    (function (context) {

        context.Title = 'Entity';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentEntityVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

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
            ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentEntityVM);
            context.ApplyValidation();
            $('#entityModal').modal('show');
        }

        context.AddNew = function () {

            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentEntityVM);
            context.ApplyValidation();
            $('#entityModal').modal('show');
        }

        context.Save = function () {
            if (!$('#entityForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentEntityVM);

            ajaxRequest('/Entity/Create/', 'POST', { data: { model: model } }, function(response) {
                if (response.IsSuccess) {

                    context.Initialize();
                    showMessage(context.Title, 'Entity saved successfully.', 'success', function() {
                        $('#entityModal').modal('hide');
                    });
                }
            });
        }

        context.ApplyValidation = function () {
            $('#entityForm').validate({
                rules: {
                    EntityName: {
                        required: true
                    }
                },
                messages: {
                    EntityName: {
                        required: 'Entity name is required.'
                    }
                }
            });
        }

        context.Initialize = function () {
            ajaxRequest('/Entity/Initialize', 'GET', {}, function (response) {
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


    })(emis.entity);
});
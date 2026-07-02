
$(function () {
    emis.CreateNamespace('userProgramMap');

    (function (context) {
        context.Title = 'User Program Map';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.UserId.subscribe(function (newValue) {
                    if (newValue) {
                        ajaxRequest('/Admin/UserProgram/GetMappedProgram', 'POST', { data: { userId: newValue } }, function (response) {
                            var model = { Records: [] };
                            if (response.IsSuccess) {
                                model.Records = response.Data;
                            }
                            ko.mapping.fromJS(model, context.ViewModel.UserProgramModel);
                        })
                    } else {
                        vm.Records([]);
                    }
                })

                vm.IsSelectAll = ko.observable(false);

                vm.IsSelectAll.subscribe(function (newValue) {
                    ko.utils.arrayForEach(vm.Records(), function (item) {
                        item.IsActive(newValue);
                    });
                });

                vm.save = function () {
                    context.Save();
                }

                return vm;
            }
        };

        context.Initialize = function (model) {
            context.ViewModel.UserProgramModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel.UserProgramModel, $('#mainContent')[0]);
        }

        context.Save = function () {
            var model = ko.mapping.toJS(context.ViewModel.UserProgramModel);
            delete model.Users;

            ajaxRequest('/Admin/UserProgram/Save', 'POST', { data: { userId: model.UserId, model: model.Records.filter(x => x.IsActive) } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function () {
                    })
                } else {
                    showMessage(context.Title, response.Message, 'error', function () {

                    })

                }
            });

        }

    })(emis.userProgramMap);
});
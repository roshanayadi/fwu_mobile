$(function () {
    emis.CreateNamespace('companyInfo');

    (function (context) {

        context.Title = 'Company Information';
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
            if (!$('#globalresource-configuration').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel);
            delete model.SaveClick;
            delete model.__ko_mapping__;

            $.ajax({
                url: '/Admin/GlobalResource/Create/',
                method: "POST",
                data: new FormData($('#globalresource-configuration')[0]),
                contentType: false,
                processData: false,
                success: function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, 'Resource saved successfully.', 'success', function () {
                        });
                    }
                }
            });

        }

        context.Initialize = function () {
            ajaxRequest('/Admin/GlobalResource/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    console.log(response.Data);
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
    })(emis.companyInfo);
});
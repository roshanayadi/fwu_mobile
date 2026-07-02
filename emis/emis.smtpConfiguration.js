$(function () {
    emis.CreateNamespace('smtpConfiguration');

    (function (context) {

        context.Title = 'SMTP Configuration';
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
            if (!$('#smtp-configuration').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel);
            delete model.SaveClick;
            delete model.__ko_mapping__;

            ajaxRequest('/Admin/SmtpConfiguration/Create/', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, 'SMTP Configuration saved successfully.', 'success', function () {
                        });
                    }
                });
        }

        context.Initialize = function () {
            ajaxRequest('/Admin/SmtpConfiguration/Initialize', 'GET', {}, function (response) {
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
    })(emis.smtpConfiguration);
});
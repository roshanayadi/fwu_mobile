$(function () {
    emis.CreateNamespace('studentRegistrationImport');

    (function (context) {

        context.Title = 'Student Registration Import';
        context.CreateFormId = '#frm';
        context.ViewModel = {};

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.ConsiderDOBBSOnly = ko.observable(true);

                vm.SaveClick = function () {
                    context.Save();
                };

                vm.RenderComplete = function () {
                    context.ApplyValidation();
                };

                return vm;
            }
        };

        context.Initialize = function (model) {
            context.ViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
        };

        context.ApplyValidation = function () {
            $('#frm').validate({
                rules: {
                    ProgramId: {
                        required: true
                    }
                }
            });
        }

        context.Save = function () {
            if (!$('#frm').valid()) {
                return false;
            }
            var viewModel = ko.mapping.toJS(context.ViewModel);
            delete viewModel.Programs;

            ajaxRequest('/Student/Registration/SaveImport', 'POST', {
                data: { model: viewModel.Records, programId: viewModel.ProgramId }
            }, function (response) {
                console.log(response);
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                }
                else {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.Records);
                }
            });
        };


    })(emis.studentRegistrationImport);
});
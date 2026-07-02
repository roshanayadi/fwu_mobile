$(function () {
    emis.CreateNamespace('bankVoucherReport');

    (function (context) {

        context.Title = 'Bank Vocuher Report';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);


                vm.Search = function () {
                    context.Search()
                }

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            ExamScheduleParentId: { required: true }
                        },
                        messages: {
                            ExamScheduleParentId: { required: 'Exam Schedule must be selected' }
                        }
                    })
                }


                return vm;
            }
        };

        context.Search = function () {
            if (!$('#frm').valid()) {
                return false;
            }
            var vm = ko.mapping.toJS(context.ViewModel)
            delete vm.Colleges;

            ajaxRequest('/Report/BankVoucher/Index', 'POST', {
                data: { model: vm }
            }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#resultContent')[0])) {
                        context.ViewModel.Records = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#resultContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.ViewModel.Records);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }



        context.Initialize = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel = ko.mapping.fromJS(model, context.Mapping);

                ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, context.Mapping, context.ViewModel);
            }
        }

    })(emis.bankVoucherReport);
});
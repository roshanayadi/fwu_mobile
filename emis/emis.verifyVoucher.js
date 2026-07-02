
$(function () {
    emis.CreateNamespace('verifyVoucher');

    (function (context) {

        context.Title = 'Verify Voucher';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.PaymentRequestId = ko.observable(0);
                vm.VoucherNo = ko.observable("");
                vm.PaymentType = ko.observable("");
                vm.ForwardedTimeStamp = ko.observable("");
                vm.StudentName = ko.observable("");
                vm.CollegeName = ko.observable("");
                vm.RollNo = ko.observable("");
                vm.ParentExamScheduleName = ko.observable("");
                vm.ExamScheduleName = ko.observable("");
                vm.SearchVoucher = function () {
                    if (!$('#validation-form').valid()) {
                        return false;
                    }
                    var model = ko.mapping.toJS(context.ViewModel)
                    if (model.VoucherNo) {
                        ajaxRequest('/Admin/BankVoucher/GetPaymentDetail', 'GET', { data: { VoucherNo: model.VoucherNo } }, function (response) {
                            if (response.IsSuccess) {
                                ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                            } else {
                                showMessage(context.Title, response.Message, 'error');
                                ko.mapping.fromJS({}, {}, context.ViewModel);
                            }
                        })
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                        ko.mapping.fromJS({}, {}, context.ViewModel);
                    }
                }

                vm.AcceptVoucher = function () {
                    if (!confirm("Are you sure to approve this voucher?")) {
                        return;
                    }
                    else {
                        context.AcceptVoucher();
                    }
                }

                return vm;
            }
        };

        context.ApplyValidation = function () {
            $('#validation-form').validate({
                rules: {
                    VoucherNo: {
                        required: true
                    }
                },
                messages: {
                    VoucherNo: {
                        required: 'Voucher no is required.'
                    }
                }
            });
        }

        context.AcceptVoucher = function () {
            var model = ko.mapping.toJS(context.ViewModel)
            if (!$('#validation-form').valid()) {
                return false;
            }
            if (model.PaymentRequestId && model.PaymentRequestId > 0) {
                ajaxRequest('/Admin/BankVoucher/AcceptVoucher', 'POST', { data: { PaymentRequestId: model.PaymentRequestId } }, function (response) {
                    if (response.IsSuccess) {
                        showMessage(context.Title, response.Message, 'success');
                        context.ViewModel.IsVerified(true);
                    }
                    else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                })
            }
        }

        context.Initialize = function (model) {
            context.ViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
            context.ApplyValidation();
        }

    })(emis.verifyVoucher);
});
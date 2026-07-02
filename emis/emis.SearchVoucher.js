$(function () {
    emis.CreateNamespace('searchVoucher');

    (function (context) {
        context.Title = 'Search Payment Voucher'
        context.success = ko.observable(false)
        context.ViewModel = {
            SearchVoucher: function () {
                context.SearchVoucher();
            },
            RenderComplete: function () {
                context.ApplyValidation();
            }
        }

        context.Initialize = function (model) {
            ko.mapping.fromJS(model, {}, context.ViewModel);
            ko.applyBindings(context.ViewModel, $('#maincontent')[0])
        }

        context.SearchVoucher = function () {
            if (!$('#searchForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel);
            delete model.ExamSchedules;
            delete model.SearchVoucher;
            delete model.RenderComplete;
            delete model.__ko_mapping__;
            console.log(model);
            ajaxRequest('/Registration/Payment/SearchVoucher', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    swal("Voucher No : "+response.Data.Voucher);
                }
                else {
                    showMessage(context.Title, response.Message, 'error');

                }
            });
        }

        context.ApplyValidation = function () {
            $('#searchForm').validate({
                rules: {
                    RegistrationNo: {
                        required: true
                    },
                    BirthDateBS: {
                        required:true
                    },
                    ExamScheduleId: {
                        required: true
                    }
                }
            });
        }

    })(emis.searchVoucher);
})
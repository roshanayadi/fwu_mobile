$(function () {
    emis.CreateNamespace('payment');

    (function (context) {

        context.Title = 'Payment';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchByRegistrationNo = function () {
                    vm.IsRegistrationNoVerified(false);
                    var regNo = vm.RegistrationNo();
                    if (regNo.length > 0) {
                        ajaxRequest('/Registration/Default/GetStudentRegNo', 'POST', { data: { registrationNo: regNo } }, function (response) {
                            if (response.IsSuccess) {
                                ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                                vm.IsRegistrationNoVerified(true);
                            }
                        });
                    } else {
                        //do something
                    }

                }
                vm.IsRegistrationNoVerified = ko.observable(false || vm.ExamRegistrationId() > 0);

                return vm;
            }
        };

        context.Initialize = function (model) {
            context.ViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel, $("#searchByRegNo")[0]);
        };

    })(emis.payment);
});
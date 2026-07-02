$(function () {
    emis.CreateNamespace('subjectRegistration');

    (function (context) {

        context.Title = 'Student Subject Registration';
        context.CreateFormId = '#frm';

        context.ViewModel = {};

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                var sum = 0;
                $(vm.CompulsorySubjects()).each(function (index, item) {
                    sum += item.TheoryFullMark();
                });
                vm.TotalCompulsoryMarks = ko.observable(sum);

                vm.Save = function () {
                    context.Save();
                };

                return vm;
            }
        };

        context.Initialize = function (id) {
            ajaxRequest('/Student/Registration/InitializeSubjectRegistration', 'GET', { data: { id: id } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.SubjectRegistration = ko.mapping.fromJS(response.Data, context.Mapping);
                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                        ko.applyBindings(context.ViewModel.SubjectRegistration, $('#savedSubjectContent')[0]);
                    }
                    else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.SubjectRegistration);
                    }
                }
            });
        };

        context.Save = function () {
            var vm = ko.mapping.toJS(context.ViewModel.SubjectRegistration);

            ajaxRequest('/Student/Registration/SubjectRegistration', 'POST', { data: { model: vm } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                }
                else {
                    showMessage(context.Title, response.Message, 'error');

                }
            });
        };

    })(emis.subjectRegistration);
});
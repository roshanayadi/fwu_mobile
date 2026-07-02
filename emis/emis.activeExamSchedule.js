$(function () {
    emis.CreateNamespace('activeExamSchedule');

    (function (context) {

        context.Title = 'Active Exam Schedule';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.CurrentActiveExamScheduleVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

                vm.AddNewClick = function () {
                    context.AddNew();
                }

                vm.SaveClick = function () {
                    context.Save();
                }

                vm.EditClick = function (item) {
                    context.Edit(item);
                }

                return vm;
            }
        };
       
        context.Edit = function (item) {
            ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentActiveExamScheduleVM);
            context.ApplyValidation();
            $('#activeExamScheduleModel').modal('show');
        }

        context.AddNew = function () {

            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentActiveExamScheduleVM);
            context.ApplyValidation();
            $('#activeExamScheduleModel').modal('show');
        }

        context.Save = function () {
            if (!$('#activeExamScheduleForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentActiveExamScheduleVM);

            ajaxRequest('/Admin/ActiveExamSchedules/Save/', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, 'Academic Year saved successfully.', 'success', function () {
                            $('#activeExamScheduleModel').modal('hide');
                        });
                    }
                    else {
                        showMessage(context.Title, 'Something went wrong!.', 'error');
                    }

                });
        }

        context.ApplyValidation = function () {
            $('#activeExamScheduleForm').validate({
                rules: {
                    ExamScheduleId: {
                        required: true
                    }
                },
                messages: {
                    ExamScheduleId: {
                        required: 'Exam schedule is required.'
                    }
                }
            });
        }

        context.Initialize = function () {
            ajaxRequest('/Admin/ActiveExamSchedules/Initialize', 'GET', {}, function (response) {
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


    })(emis.activeExamSchedule);
});


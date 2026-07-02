$(function () {
    emis.CreateNamespace('academicYear');

    (function (context) {

        context.Title = 'Academic Year';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentAcademicYearVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

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
            ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentAcademicYearVM);
            context.ApplyValidation();
            $('#academicYearModal').modal('show');
        }

        context.AddNew = function () {

            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentAcademicYearVM);
            context.ApplyValidation();
            $('#academicYearModal').modal('show');
        }

        context.Save = function () {
            if (!$('#academicYearForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentAcademicYearVM);

            ajaxRequest('/AcademicYear/Create/', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, 'Academic Year saved successfully.', 'success', function () {
                            $('#academicYearModal').modal('hide');
                        });
                    }
                });
        }

        context.ApplyValidation = function () {
            $('#academicYearForm').validate({
                rules: {
                    AcademicYearName: {
                        required: true
                    },
                    AcademicYearCode: {
                        required: true
                    }
                },
                messages: {
                    AcademicYearName: {
                        required: 'Academi Year name is required.'
                    },
                    AcademicYearCode: {
                        required: 'Academic Year Code is required.'
                    }
                }
            });
        }

        context.Initialize = function () {
            ajaxRequest('/AcademicYear/Initialize', 'GET', {}, function (response) {
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


    })(emis.academicYear);
});
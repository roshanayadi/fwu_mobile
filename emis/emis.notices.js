$(function () {
    emis.CreateNamespace('notices');

    (function (context) {

        context.Title = 'Notices';
        context.ViewModel = {};

        context.CreateMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SaveClick = function () {
                    context.Save();
                }

                return vm;
            }
        };
        //context.Edit = function (item) {
        //    ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentAcademicYearVM);
        //    context.ApplyValidation();
        //    $('#academicYearModal').modal('show');
        //}

        //context.AddNew = function () {

        //    ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentAcademicYearVM);
        //    context.ApplyValidation();
        //    $('#academicYearModal').modal('show');
        //}

        context.Save = function () {
            if (!$('#noticeForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.AddNewModel);

            ajaxRequest('/Admin/Notice/Create/', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                },
                function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, response.Message, 'success', function () {
                        });
                    } else {
                        showMessage(context.Title, response.Message, 'error', function () {
                        });
                    }
                });
        }

        //context.ApplyValidation = function () {
        //    $('#academicYearForm').validate({
        //        rules: {
        //            AcademicYearName: {
        //                required: true
        //            },
        //            AcademicYearCode: {
        //                required: true
        //            }
        //        },
        //        messages: {
        //            AcademicYearName: {
        //                required: 'Academi Year name is required.'
        //            },
        //            AcademicYearCode: {
        //                required: 'Academic Year Code is required.'
        //            }
        //        }
        //    });
        //}

        context.Initialize = function () {
            ajaxRequest('/Admin/Notice/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.InitializeCreate = function () {
            var noticeId = $('#NoticeId').val();
            ajaxRequest('/Admin/Notice/InitializeCreate', 'GET', { data: { id: noticeId } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.CreateMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

    })(emis.notices);
});
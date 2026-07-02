$(function () {
    emis.CreateNamespace('teacherDetail');

    (function (context) {

        context.Title = 'Teacher';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentTeacherVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

                vm.AddNewClick = function () {
                    context.AddNew();
                }

                vm.SaveClick = function () {
                    context.Save();
                }

                vm.EditClick = function(item) {
                    ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentTeacherVM);
                    context.ApplyValidation();
                    $('#teacherAddModal').modal('show');
                }
                return vm;
            }
        };

        context.ApplyValidation = function () {
            $('#teacherDetilForm').validate({
                rules: {
                    TeacherFirstName: {
                        required: true
                    },
                    TeacherLastName: {
                        required: true
                    }
                },
                messages: {
                    TeacherFirstName: {
                        required: 'First Name is required'
                    },
                    TeacherLastName: {
                        required: 'Last Name is required'
                    }
                }
            });
        }

        context.AddNew = function () {
            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentTeacherVM);
            context.ApplyValidation();
            $('#teacherAddModal').modal('show');
        }

        context.Save = function () {
            if (!$('#teacherDetilForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentTeacherVM);
            ajaxRequest('/Teacher/TeacherDetail/Create', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement : '[data-button-type=ladda]'
                }, function(response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function() {
                        context.Initialize();
                        $('#teacherAddModal').modal('hide');
                    });
                } else {
                    showMessage(context.Title, response.Message, 'error', function () {
                    });
                }
            });
        }

        context.Initialize = function () {
            ajaxRequest('/Teacher/TeacherDetail/Initialize', 'GET', {}, function (response) {
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

        context.Initialize = function () {
            ajaxRequest('/Teacher/TeacherDetail/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                        setTimeout(function () {
                            //$('.dataTables-teacher').DataTable({
                            //    dom: '<"html5buttons"B>lTfgitp',
                            //    buttons: [
                            //        { extend: 'copy' },
                            //        { extend: 'csv' },
                            //        { extend: 'excel', title: 'TeacherFile' },
                            //        { extend: 'pdf', title: 'TeacherFile' },

                            //        {
                            //            extend: 'print',
                            //            customize: function (win) {
                            //                $(win.document.body).addClass('white-bg');
                            //                $(win.document.body).css('font-size', '10px');

                            //                $(win.document.body).find('table')
                            //                        .addClass('compact')
                            //                        .css('font-size', 'inherit');
                            //            }
                            //        }
                            //    ]

                            //});
                        }, 1000);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

    })(emis.teacherDetail);
});
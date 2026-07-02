$(function () {
    emis.CreateNamespace('programDetail');

    (function (context) {

        context.Title = 'Program';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentProgramVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

                vm.AddNewClick = function () {
                    context.AddNew();
                }

                vm.SaveClick = function () {
                    context.Save();
                }

                vm.EditClick = function(item) {
                    ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentProgramVM);
                    context.ApplyValidation();
                    $('#programAddModal').modal('show');
                }

                return vm;
            }
        };

        context.ApplyValidation = function () {
            $('#programDetailForm').validate({
                rules: {
                    ProgramFirstName: {
                        required: true
                    },
                    ProgramLastName: {
                        required: true
                    }
                },
                messages: {
                    ProgramName: {
                        required: 'Program Name is required'
                    },
                    ProgramCode: {
                        required: 'Program Code is required'
                    }
                }
            });
        }

        context.AddNew = function () {
            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentProgramVM);
            context.ApplyValidation();
            $('#programAddModal').modal('show');
        }

        context.Save = function () {
            if (!$('#programDetailForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentProgramVM);
            ajaxRequest('/Exam/Program/Create', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function(response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function() {
                        context.Initialize();
                        $('#programAddModal').modal('hide');
                    });
                } else {
                    showMessage(context.Title, response.Message, 'error', function () {
                    });
                }
            });
        }

        context.Initialize = function () {
            ajaxRequest('/Exam/Program/Initialize', 'GET', {}, function (response) {
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
            ajaxRequest('/Exam/Program/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);//collegeDetailModal
                        setTimeout(function () {
                            //$('.dataTables-program').DataTable({
                            //    dom: '<"html5buttons"B>lTfgitp',
                            //    buttons: [
                            //        { extend: 'copy' },
                            //        { extend: 'csv' },
                            //        { extend: 'excel', title: 'ProgramFile' },
                            //        { extend: 'pdf', title: 'ProgramFile' },

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

    })(emis.programDetail);
});
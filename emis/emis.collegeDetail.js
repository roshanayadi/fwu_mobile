$(function () {
    emis.CreateNamespace('collegeDetail');

    (function (context) {

        context.Title = 'College';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentCollegeVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

                vm.AddNewClick = function () {
                    context.AddNew();
                }

                vm.SearchClick = function () {
                    context.Initialize();
                }

                vm.NextPageClick = function () {
                    vm.PageIndex(vm.PageIndex() + 1);
                    context.Initialize();
                }

                vm.PreviousPageClick = function () {
                    var a = vm.PageIndex() - 1;
                    a = a < 1 ? 1 : a;
                    vm.PageIndex(a);
                    context.Initialize();
                }

                vm.SaveClick = function () {
                    context.Save();
                }

                vm.EditClick = function (item) {
                    ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentCollegeVM);
                    context.ApplyValidation();
                    $('#collegeAddModal').modal('show');
                }

                return vm;
            }
        };

        context.ApplyValidation = function () {
            $('#collegeDetailForm').validate({
                rules: {
                    CollegeName: {
                        required: true
                    },
                    CollegeCode: {
                        required: true
                    }
                },
                messages: {
                    CollegeName: {
                        required: 'School/College Name is required'
                    },
                    CollegeCode: {
                        required: 'School/College Code is required'
                    }
                }
            });
        }

        context.AddNew = function () {
            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentCollegeVM);
            context.ApplyValidation();
            $('#collegeAddModal').modal('show');
        }

        context.Save = function () {
            if (!$('#collegeDetailForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentCollegeVM);
            ajaxRequest('/College/CollegeDetail/Create', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        showMessage(context.Title, response.Message, 'success', function () {
                            context.Initialize();
                            $('#collegeAddModal').modal('hide');
                        });
                    } else {
                        showMessage(context.Title, response.Message, 'error', function () {
                        });
                    }
                });
        }

        context.Initialize = function () {
            var pageindex = 1;
            if (context.ViewModel.PageIndex) {
                pageindex = context.ViewModel.PageIndex();
            }
            var searchModel = ko.toJS(context.ViewModel.SearchModel);
            ajaxRequest('/College/CollegeDetail/Initialize', 'GET', {
                data: { pageIndex: pageindex, code: searchModel != null ? searchModel.Code : "", name: searchModel != null ? searchModel .Name : "" }
            }, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        //context.Initialize = function () {
        //    ajaxRequest('/College/CollegeDetail/Initialize', 'GET', {}, function (response) {
        //        if (response.IsSuccess) {

        //            if (!ko.dataFor($('#mainContent')[0])) {
        //                context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

        //                ko.applyBindings(context.ViewModel, $('#mainContent')[0]);//collegeDetailModal
        //                setTimeout(function () {
        //                    //$('.dataTables-college').DataTable({
        //                    //    dom: '<"html5buttons"B>lTfgitp',
        //                    //    buttons: [
        //                    //        { extend: 'copy' },
        //                    //        { extend: 'csv' },
        //                    //        { extend: 'excel', title: 'CollegeFile' },
        //                    //        { extend: 'pdf', title: 'CollegeFile' },

        //                    //        {
        //                    //            extend: 'print',
        //                    //            customize: function (win) {
        //                    //                $(win.document.body).addClass('white-bg');
        //                    //                $(win.document.body).css('font-size', '10px');

        //                    //                $(win.document.body).find('table')
        //                    //                        .addClass('compact')
        //                    //                        .css('font-size', 'inherit');
        //                    //            }
        //                    //        }
        //                    //    ]

        //                    //});
        //                }, 1000);
        //            } else {
        //                ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
        //            }

        //        } else {
        //            showMessage(context.Title, response.Message, 'error');
        //        }
        //    });
        //}

    })(emis.collegeDetail);
});
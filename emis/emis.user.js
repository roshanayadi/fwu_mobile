
$(function () {
    emis.CreateNamespace('user');

    (function (context) {

        context.Title = 'User';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentPage = ko.observable(1);
                vm.PageSize = ko.observable(100);

                vm.CurrentUserVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

                vm.Search = function () {
                    context.Search();
                }

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

        context.Search = function () {
            var searchModel = {
                UserName: context.ViewModel.UserName(),
                Page: context.ViewModel.CurrentPage(),
                pageSize: context.ViewModel.PageSize(),
            };
            ajaxRequest('/Admin/User/Index', 'POST', { data: searchModel }, function (response) {
                var data = [];
                if (response.IsSuccess) {
                    data = response.Data;
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
                ko.mapping.fromJS(data, {}, context.ViewModel.Records);
            });
        }

        context.Edit = function (item) {
            //ajax initialize
            var id = item.UserID();
            ajaxRequest('/Admin/User/Edit', 'GET', { data: { id: id } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.CurrentUserVM);
                    context.ApplyValidation();
                    $('#userModal').modal('show');
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            });
            //ko.mapping.fromJS(ko.toJS(item), {}, context.ViewModel.CurrentUserVM);
            //context.ApplyValidation();
            //$('#userModal').modal('show');
        }

        context.AddNew = function () {
            var a = ko.toJS(context.ViewModel.AddNewModel);
            context.ViewModel.CurrentUserVM.RoleID(null);
            context.ViewModel.CurrentUserVM.CollegeID(null);
            ko.mapping.fromJS(a, {}, context.ViewModel.CurrentUserVM);
            context.ApplyValidation();
            $('#userModal').modal('show');
        }

        context.Save = function () {
            if (!$('#userForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentUserVM);

            ajaxRequest('/Admin/User/Create/', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {

                        context.Initialize();
                        showMessage(context.Title, 'User saved successfully.', 'success', function () {
                            $('#userModal').modal('hide');
                        });
                    }
                    else {
                        showMessage(context.Title, response.Message, 'error', function () {
                        });
                    }
                });
        }

        context.ApplyValidation = function () {
            $('#userForm').validate({
                rules: {
                    UserName: {
                        required: true
                    },
                    CollegeID: {
                        required: true
                    },
                    Password: {
                        required: true
                    },
                    FullName: {
                        required: true
                    }
                },
                messages: {
                    UserName: {
                        required: 'User name is required.'
                    },
                    CollegeID: {
                        required: 'College Must be selected.'
                    },
                    Password: {
                        required: 'Password is required.'
                    },
                    FullName: {
                        required: 'FullName is required.'
                    }
                }
            });
        }

        context.Initialize = function () {
            //$('#userModal').on
            $('#userModal').on('hide.bs.modal	', function () {
                //$('#userForm')[0].reset();
                ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentUserVM);
            })

            ajaxRequest('/User/Initialize', 'GET', {}, function (response) {
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

        //
        context.ResetPasswordMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.UserType = ko.observable("");
                vm.DOBBS = ko.observable("");
                vm.College = ko.observable("");
                vm.Name = ko.observable("");
                vm.SearchUser = function () {
                    var model = ko.mapping.toJS(context.ViewModel.ResetPasswordViewModel)
                    if (model.UserName) {
                        ajaxRequest('/Changepassword/GetUserDetail', 'GET', { data: { username: model.UserName } }, function (response) {
                            if (response.IsSuccess) {
                                vm.UserId(response.Data.UserId);
                                vm.UserType(response.Data.UserType);
                                vm.DOBBS(response.Data.DOBBS);
                                vm.College(response.Data.College);
                                vm.Name(response.Data.Name);
                            } else {
                                showMessage(context.Title, response.Message, 'error');
                                vm.UserId('');
                                vm.UserType('');
                                vm.DOBBS('');
                                vm.College('');
                                vm.Name('');

                            }
                        })
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                        vm.Password('');
                        vm.UserId('');
                        vm.UserType('');
                        vm.DOBBS('');
                        vm.College('');
                    }
                }

                vm.ResetPassword = function () {
                    context.ResetPassword();
                }

                return vm;
            }
        };

        context.ResetPassword = function () {
            var model = ko.mapping.toJS(context.ViewModel.ResetPasswordViewModel)
            var userId = model.UserId;
            var password = model.Password;
            if (!$("#resetpassword-form").valid()) {
                return false;
            }
            if (userId && userId > 0) {
                ajaxRequest('/ChangePassword/ResetPassword', 'POST', { data: { UserId: userId, password: password, confirmPassword: model.ConfirmPassword } }, function (response) {
                    if (response.IsSuccess) {
                        showMessage(context.Title, response.Message, 'success');
                    }
                    else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                })
            }
        }

        context.InitializeResetPassword = function (model) {
            context.ViewModel.ResetPasswordViewModel = ko.mapping.fromJS(model, context.ResetPasswordMapping);
            ko.applyBindings(context.ViewModel.ResetPasswordViewModel, $('#mainContent')[0]);
        }

    })(emis.user);
});
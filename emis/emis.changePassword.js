$(function () {
    emis.CreateNamespace('changePassword');

    (function (context) {
        context.Title = 'Change Password'
        context.ViewModel = {
            Save: function () {
                context.Save();
            },
            RenderComplete: function () {
                context.ApplyValidation();
            }
        }

        context.Initialize = function () {
            ajaxRequest('/ChangePassword/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#changePassword')[0])) {
                        var vm = ko.mapping.fromJS(response.Data);

                        context.ViewModel.ChangePasswordVM = vm;
                        ko.applyBindings(context.ViewModel, $('#changePassword')[0])
                       
                    }
                    else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ChangePasswordVM);
                    }
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            });
        }

        context.Save = function () {
            if (!$('#changePasswordForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.ChangePasswordVM);
            console.log(model);
            ajaxRequest('/ChangePassword/Index', 'POST', { data: { model: model } }, function (response) {

                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                    setTimeout(() => {
                        window.location.href = "/home";
                    }, 2000);
                }
                else {
                    showMessage(context.Title, response.Message, 'error');

                }
            });
        }

        context.ApplyValidation = function () {
            $('#changePasswordForm').validate({
                rules:{
                    CurrentPassword: {
                        required: true
                    },
                    NewPassword: {
                        required: true
                    },
                    ConfirmNewPassword: {
                        equalTo: '#NewPassword'
                    }
                },
                messages: {
                    CurrentPassword: {
                        required: 'Current password is required'
                    },
                    NewPassword: {
                        required: 'New Password is required.'
                    },
                    ConfirmNewPassword: {
                        equalTo: 'Confirm Password must be same as new password.'
                    }
                }
            });
        }

    })(emis.changePassword);
})